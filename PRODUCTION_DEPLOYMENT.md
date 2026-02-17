# Production Deployment Guide

This guide covers deploying the DropTrack PWA to production.

## Pre-Deployment Checklist

### 1. Environment Variables

Ensure all required environment variables are set in your production environment:

**Required:**
- `VITE_COGNITO_USER_POOL_ID` - AWS Cognito User Pool ID
- `VITE_COGNITO_CLIENT_ID` - AWS Cognito Client ID
- `VITE_API_BASE_URL` - Backend API URL (must use HTTPS in production)
- `VITE_GOOGLE_MAPS_API_KEY` - Google Maps API Key

**Optional but Recommended:**
- `VITE_STRIPE_PUBLISHABLE_KEY` - Stripe publishable key (required for payments)
- `VITE_COGNITO_REGION` - AWS region (auto-detected from User Pool ID)
- `VITE_COGNITO_REDIRECT_URI` - OAuth redirect URI (must use HTTPS in production)
- `VITE_COGNITO_LOGOUT_URI` - Post-logout redirect URI

### 2. Build the Application

#### Using PowerShell (Windows):
```powershell
.\build-production.ps1
```

#### Using Bash (Linux/Mac):
```bash
npm run build:prod
# or
./build.sh
```

#### Manual Build:
```bash
npm install
npm run type-check
npm run lint
npm run build
```

### 3. Verify Build Output

After building, verify the `dist/` directory contains:
- `index.html` - Main HTML file
- `manifest.json` - PWA manifest
- `sw.js` - Service worker
- All bundled JavaScript and CSS files
- Static assets (images, icons, etc.)

## Deployment Options

### AWS S3 + CloudFront (Recommended)

#### Step 1: Upload to S3

```bash
aws s3 sync dist/ s3://your-bucket-name --delete
```

#### Step 2: Configure S3 Bucket

1. Enable static website hosting:
   - Index document: `index.html`
   - Error document: `index.html` (for SPA routing)

2. Set bucket policy for public read access (or use CloudFront)

#### Step 3: Configure CloudFront

1. **Origin Settings:**
   - Origin: Your S3 bucket
   - Origin path: Leave empty (or `/` if using website endpoint)

2. **Error Pages (Critical for SPA):**
   - 403 → `/index.html` with HTTP 200 response
   - 404 → `/index.html` with HTTP 200 response

3. **SSL Certificate:**
   - Use AWS Certificate Manager (ACM) certificate
   - Must be in `us-east-1` region for CloudFront

4. **Security Headers:**
   - Configure Response Headers Policy:
     - `Content-Security-Policy`
     - `Strict-Transport-Security` (HSTS)
     - `X-Content-Type-Options: nosniff`
     - `X-Frame-Options: DENY`
     - `X-XSS-Protection: 1; mode=block`

5. **Caching:**
   - Cache static assets (JS, CSS, images) for 1 year
   - Don't cache `index.html` (or cache for 5 minutes)
   - Don't cache `manifest.json` and `sw.js`

### Other Hosting Platforms

#### Netlify
- Deploy `dist/` folder
- Configure redirects: `/* /index.html 200`
- Set environment variables in Netlify dashboard

#### Vercel
- Deploy `dist/` folder
- Configure `vercel.json`:
  ```json
  {
    "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
  }
  ```

#### GitHub Pages
- Deploy `dist/` folder to `gh-pages` branch
- Configure 404.html to redirect to index.html

## Post-Deployment Verification

### 1. Test SPA Routing

- Navigate to production URL
- Go to `/signin` or `/signup`
- Refresh the page (F5)
- Verify no 404 errors

### 2. Test PWA Functionality

- Open browser DevTools → Application tab
- Check Service Worker is registered
- Check Manifest is loaded
- Test "Add to Home Screen" (mobile)

### 3. Test Authentication

- Sign up a new user
- Verify user appears in AWS Cognito Console
- Test sign in
- Test sign out

### 4. Test API Connectivity

- Open browser DevTools → Network tab
- Verify all API requests use HTTPS
- Check for CORS errors
- Verify API responses are successful

### 5. Security Checks

- Verify HTTPS is enforced
- Check security headers are present
- Verify no mixed-content warnings
- Test CSP (Content Security Policy)

## Troubleshooting

### Issue: 404 on Page Refresh

**Solution:**
- Configure error pages: 403/404 → `/index.html` (200)
- Verify SPA routing is configured on your hosting platform

### Issue: Service Worker Not Registering

**Solution:**
- Verify `sw.js` is accessible at `/sw.js`
- Check browser console for errors
- Ensure HTTPS is enabled (required for service workers)
- Verify service worker registration code is only running in production

### Issue: Environment Variables Not Working

**Solution:**
- Verify variables are set in your hosting platform
- Check variable names start with `VITE_`
- Rebuild after changing environment variables
- Clear browser cache

### Issue: API Calls Failing

**Solution:**
- Verify `VITE_API_BASE_URL` uses HTTPS in production
- Check CORS configuration on backend
- Verify API endpoint is accessible
- Check browser console for specific errors

### Issue: Cognito Authentication Failing

**Solution:**
- Verify Cognito User Pool ID and Client ID are correct
- Check redirect URIs are registered in Cognito
- Verify redirect URIs use HTTPS in production
- Check Cognito User Pool region matches configuration

## Monitoring

### Recommended Monitoring

1. **Error Tracking:**
   - Set up error tracking (e.g., Sentry, LogRocket)
   - Monitor JavaScript errors
   - Track API errors

2. **Performance:**
   - Monitor Core Web Vitals
   - Track page load times
   - Monitor API response times

3. **Analytics:**
   - Track user signups
   - Monitor authentication success rate
   - Track PWA installs

## Maintenance

### Regular Tasks

1. **Update Dependencies:**
   ```bash
   npm update
   npm audit fix
   ```

2. **Rebuild and Redeploy:**
   - After dependency updates
   - After code changes
   - After environment variable changes

3. **Monitor Logs:**
   - Check CloudWatch logs (if using AWS)
   - Review error tracking dashboards
   - Monitor user feedback

## Support

For issues or questions:
1. Check browser console for errors
2. Review this deployment guide
3. Check production validation checklist
4. Contact the development team





















