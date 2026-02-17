/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // Primary colors
        primary: {
          DEFAULT: '#2E7D32',
          light: '#4CAF50',
          dark: '#1B5E20',
        },
        // Secondary colors
        secondary: {
          DEFAULT: '#FF6D00',
          light: '#FF9E40',
          dark: '#E65100',
        },
        // Neutral colors
        neutral: {
          50: '#FAFAFA',
          100: '#F5F5F5',
          200: '#EEEEEE',
          300: '#E0E0E0',
          400: '#BDBDBD',
          500: '#9E9E9E',
          600: '#757575',
          700: '#616161',
          800: '#424242',
          900: '#212121',
        },
        // Semantic colors
        success: '#4CAF50',
        warning: '#FF9800',
        error: '#F44336',
        info: '#2196F3',
        // Surface colors
        surface: {
          DEFAULT: '#FFFFFF',
          variant: '#F5F5F5',
        },
        background: '#FAFAFA',
        // Text colors
        text: {
          primary: '#212121',
          secondary: '#757575',
          disabled: '#BDBDBD',
          'on-primary': '#FFFFFF',
          'on-secondary': '#FFFFFF',
        },
        // Border colors
        border: {
          DEFAULT: '#E0E0E0',
          light: '#EEEEEE',
          dark: '#BDBDBD',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
      },
      borderRadius: {
        button: '0.5rem',
        card: '0.75rem',
        input: '0.375rem',
      },
      animation: {
        'gradient-xy': 'gradient-xy 3s ease infinite',
      },
      keyframes: {
        'gradient-xy': {
          '0%, 100%': {
            'background-size': '200% 200%',
            'background-position': 'left center'
          },
          '50%': {
            'background-size': '200% 200%',
            'background-position': 'right center'
          },
        }
      },
    },
  },
  plugins: [],
};