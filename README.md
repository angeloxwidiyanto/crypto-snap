# Crypto Snap

A minimal example demonstrating a Flutter mobile app with a Go backend that serves cryptocurrency chart data.

## Backend (Go)

The backend exposes two endpoints:

- `/api/prices/{symbol}` – returns the last 24h prices for a given coin using the CoinGecko API
- `/api/chart/{symbol}` – returns a PNG line chart of the same data

### Running the backend

```bash
cd backend
go run .
```

The server listens on port `8080`.

## Frontend (Flutter)

The Flutter app fetches price data from the backend and displays it using `fl_chart`.
A basic configuration is included in `frontend/`.

### Running the app

Ensure you have Flutter installed, then run:

```bash
cd frontend
flutter run
```

The app will request data from `http://localhost:8080`.
