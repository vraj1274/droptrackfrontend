# DropVerify Frontend

A React-based web application for the DropVerify platform.

## Features

- User authentication with AWS Cognito
- Role-based access control (Client, Dropper, SuperAdmin)
- Job management and tracking
- Interactive maps with Google Maps API
- Payment processing with Stripe
- Responsive design with Tailwind CSS

## Tech Stack

- React 19.1.1
- TypeScript
- Vite
- Tailwind CSS
- React Router
- AWS Cognito
- Stripe

## Environment Variables

Copy `env.example` to `.env.local` (or `.env`) and adjust the values for your stack:

| Variable | Purpose | Example |
| --- | --- | --- |
| `VITE_API_BASE_URL` | Base URL for the FastAPI backend (`/api/v1` is appended automatically) | `http://localhost:8000` |
| `VITE_BACKEND_URL` / `VITE_API_URL` | Optional aliases that are still supported | `http://localhost:8000` |
| `VITE_COGNITO_USER_POOL_ID` | AWS Cognito user pool for auth | `us-east-1_abc123` |
| `VITE_COGNITO_CLIENT_ID` | Cognito app client id | `1h57kf5cpq17m0eml12EXAMPLE` |
| `VITE_COGNITO_DOMAIN` | Cognito hosted UI / OAuth domain (without protocol) | `example-domain.auth.us-east-1.amazoncognito.com` |
| `VITE_COGNITO_REDIRECT_URI` | Redirect URI registered in Cognito for login callback | `http://localhost:5173/auth/callback` |
| `VITE_COGNITO_LOGOUT_URI` | Post-logout redirect URI registered in Cognito | `http://localhost:5173/` |
| `VITE_GOOGLE_MAPS_API_KEY` | Google Maps (Maps + Places) key | `AIza...` |
| `VITE_STRIPE_PUBLISHABLE_KEY` | Stripe publishable key used on the client | `pk_test_...` |

> Tip: keep the backend `CORS_ORIGINS` list in sync with the frontend origin(s), e.g. include `http://localhost:5173`.

## Connecting to the FastAPI Backend

1. **Backend setup**
   ```bash
   cd ../DropVerify_backend-krishaa
   python -m venv .venv && .\.venv\Scripts\activate  # PowerShell
   pip install -r requirements.txt
   # create .env (see backend README for variable list) and make sure
   # CORS_ORIGINS includes http://localhost:5173 while developing
   py run.py  # Starts FastAPI on http://localhost:8000 by default
   ```
2. **Frontend setup (new terminal)**
   ```bash
   cd ../DropVerify_webfront
   cp env.example .env.local
   npm install
   npm run dev  # Serves on http://localhost:5173
   ```
3. Visit `http://localhost:5173`, sign in via Cognito, and the UI will call the backend at `http://localhost:8000/api/v1/*`.

If you change ports, update both `VITE_API_BASE_URL` (frontend) and `CORS_ORIGINS` (backend) accordingly.

## Installation

```bash
npm install
```

## Development

```bash
npm run dev
```

## Build

```bash
npm run build
```

## Production

```bash
npm run preview
```
