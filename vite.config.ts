import react from '@vitejs/plugin-react';
import { defineConfig, loadEnv } from 'vite';

// Export as a function to access environment variables
export default defineConfig(({ mode }) => {
  // Load env file based on `mode` in the current working directory.
  // Set the third parameter to '' to load all env regardless of the `VITE_` prefix.
  const env = loadEnv(mode, process.cwd(), '')

  // Proxy API requests to production server to avoid CORS issues in development
  // To use local backend instead, set VITE_USE_LOCAL_BACKEND=true in .env
  const useLocalBackend = env.VITE_USE_LOCAL_BACKEND === 'true';
  const backendTarget = useLocalBackend
    ? 'http://127.0.0.1:8000'
    : (env.VITE_API_BASE_URL || 'http://3.104.243.143');


  console.log(`🔧 Using backend at ${backendTarget}`);

  // https://vite.dev/config/
  return {
    plugins: [react()],
    server: {
      host: '0.0.0.0',
      port: 5173,
      // Explicit HMR configuration to fix WebSocket connection issues
      hmr: {
        protocol: 'ws',
        host: 'localhost',
        port: 5173,
        clientPort: 5173,
      },
      proxy: {
        '/api': {
          target: backendTarget,
          changeOrigin: true,
          secure: useLocalBackend ? false : true,
          agent: false,
          rewrite: (path) => path,
          timeout: useLocalBackend ? 30000 : 60000,
          connectTimeout: useLocalBackend ? 10000 : 30000,
          configure: (proxy, _options) => {
            proxy.on('proxyReq', (proxyReq, req, _res) => {
              proxyReq.setHeader('Connection', 'close');
              proxyReq.setTimeout(60000);
              proxyReq.socket?.setTimeout(60000);
              const startTime = Date.now();
              (req as any).__startTime = startTime;
              (req as any).__retryCount = 0;
              console.log(`[Proxy] ${req.method} ${req.url} -> ${backendTarget}`);
            });

            proxy.on('proxyRes', (proxyRes, req, _res) => {
              const duration = Date.now() - ((req as any).__startTime || Date.now());
              console.log(`[Proxy] ${proxyRes.statusCode} ${req.url} (${duration}ms)`);
            });

            proxy.on('error', (err: any, req, res) => {
              const errorCode = err?.code || 'UNKNOWN';
              const errorMessage = err?.message || String(err);
              const url = req.url || 'unknown';
              const isTimeout = errorCode === 'ETIMEDOUT' || errorCode === 'ESOCKETTIMEDOUT';
              const isConnectionRefused = errorCode === 'ECONNREFUSED';
              const isConnectionReset = errorCode === 'ECONNRESET';
              const isNetworkError = errorCode === 'ENOTFOUND' || errorCode === 'ENETUNREACH' || errorCode === 'EHOSTUNREACH';

              if (isConnectionReset) {
                console.warn('⚠️ Connection reset by server (ECONNRESET):', {
                  url,
                  target: backendTarget,
                  message: 'Server closed the connection. This is usually transient.',
                  suggestion: 'The client will automatically retry. If this persists, check server logs.'
                });

                if (res && typeof (res as any).writeHead === 'function') {
                  const response = res as any;
                  if (!response.headersSent) {
                    response.writeHead(502, {
                      'Content-Type': 'application/json',
                      'X-Proxy-Error': 'ECONNRESET',
                      'Retry-After': '1',
                    });
                    response.end(JSON.stringify({
                      error: 'Connection Reset',
                      message: 'The server closed the connection. Please retry.',
                      code: 'ECONNRESET',
                      retryable: true,
                      target: backendTarget,
                    }));
                  }
                }
                return;
              }

              const isAggregateError = errorCode === 'AggregateError' || errorMessage.includes('AggregateError');
              if (isTimeout || isAggregateError) {
                if (!(global as any).__proxyTimeoutLogged) {
                  console.error('⚠️ Proxy connection timeout:', {
                    url,
                    target: backendTarget,
                    error: errorMessage,
                    errorCode,
                    isAggregateError,
                    suggestion: useLocalBackend
                      ? 'Check if local backend is running on port 8000. Start it with: cd DropVerify_backend && python run.py'
                      : 'Remote server is slow or unreachable. Switch to local backend by setting VITE_USE_LOCAL_BACKEND=true in .env file'
                  });
                  (global as any).__proxyTimeoutLogged = true;
                  setTimeout(() => {
                    (global as any).__proxyTimeoutLogged = false;
                  }, 60000);
                }
              } else if (isConnectionRefused) {
                console.error('❌ Proxy connection refused:', {
                  url,
                  target: backendTarget,
                  suggestion: useLocalBackend
                    ? 'Backend server may be down. Start it with: cd DropVerify_backend && python run.py'
                    : 'Backend server may be down or not accessible'
                });
              } else if (isNetworkError) {
                console.error('❌ Proxy network error:', {
                  url,
                  target: backendTarget,
                  error: errorMessage,
                  code: errorCode,
                  isAggregateError,
                  suggestion: useLocalBackend
                    ? 'Check if local backend is running on port 8000. Start it with: cd DropVerify_backend && python run.py'
                    : 'Cannot reach remote server. Check internet connection or use local backend by setting VITE_USE_LOCAL_BACKEND=true in .env file'
                });
              } else {
                console.error('❌ Proxy error:', {
                  code: errorCode,
                  message: errorMessage,
                  url,
                  target: backendTarget,
                  suggestion: useLocalBackend
                    ? 'Check if local backend is running on port 8000'
                    : 'Try using local backend by setting VITE_USE_LOCAL_BACKEND=true in .env file'
                });
              }

              if (res && typeof (res as any).writeHead === 'function') {
                const response = res as any;
                if (!response.headersSent) {
                  const isAggregateError = errorCode === 'AggregateError' || errorMessage.includes('AggregateError');
                  let userMessage = 'Backend server did not respond in time. Please try again.';

                  if (isTimeout || isAggregateError) {
                    userMessage = useLocalBackend
                      ? 'Local backend server is not responding. Please check if it\'s running on port 8000. Start it with: cd DropVerify_backend && python run.py'
                      : 'Remote backend server is slow or unreachable. Please check your network connection or switch to local backend by setting VITE_USE_LOCAL_BACKEND=true in .env file.';
                  } else if (isConnectionRefused) {
                    userMessage = useLocalBackend
                      ? 'Backend server connection refused. The server may be down. Start it with: cd DropVerify_backend && python run.py'
                      : 'Backend server connection refused. The server may be down.';
                  } else if (isNetworkError) {
                    userMessage = useLocalBackend
                      ? 'Network error. Check if local backend is running on port 8000.'
                      : 'Network error. Please check your internet connection or use local backend (VITE_USE_LOCAL_BACKEND=true).';
                  }

                  response.writeHead(504, {
                    'Content-Type': 'application/json',
                    'X-Proxy-Error': errorCode,
                  });
                  response.end(JSON.stringify({
                    error: 'Gateway Timeout',
                    message: userMessage,
                    code: errorCode,
                    target: backendTarget,
                    suggestion: useLocalBackend
                      ? 'Ensure local backend is running: npm run dev (in backend directory)'
                      : 'Try using local backend by setting VITE_USE_LOCAL_BACKEND=true in .env'
                  }));
                }
              }
            });

            (proxy as any).on('timeout', (req: any, res: any) => {
              console.warn('⚠️ Proxy request timeout:', req.url);
              if (res && typeof (res as any).writeHead === 'function') {
                const response = res as any;
                if (!response.headersSent) {
                  response.writeHead(504, {
                    'Content-Type': 'application/json',
                  });
                  response.end(JSON.stringify({
                    error: 'Gateway Timeout',
                    message: 'Request timed out. The backend server may be slow or unreachable.',
                    suggestion: useLocalBackend
                      ? 'Check if local backend is running and responding'
                      : 'Check network connection or try using local backend'
                  }));
                }
              }
            });

            (proxy as any).on('upgrade', (req: any) => {
              if (req.url && req.url.startsWith('/api')) {
                console.log('[Proxy] WebSocket upgrade for API:', req.url);
              }
            });
          },
        }
      }
    },
    define: {
      global: 'globalThis',
    },
    build: {
      rollupOptions: {
        output: {
          manualChunks: {
            vendor: ['react', 'react-dom', 'react-router-dom'],
            ui: ['clsx', 'tailwind-merge'],
          },
        },
      },
      sourcemap: process.env.NODE_ENV !== 'production',
      chunkSizeWarningLimit: 1000,
    },
    optimizeDeps: {
      include: ['react', 'react-dom', 'react-router-dom', 'buffer', 'process'],
      esbuildOptions: {
        define: {
          global: 'globalThis',
        },
      },
    },
    resolve: {
      alias: {
        buffer: 'buffer',
        process: 'process',
      },
    },
  };
})