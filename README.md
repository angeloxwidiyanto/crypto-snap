# Crypto-Snap

Crypto-Snap is a modern cryptocurrency tracking application with a Go backend and Flutter frontend. The application provides real-time cryptocurrency price data, charts, and market statistics.

## Features

- Real-time cryptocurrency price data from CoinGecko
- Interactive price charts with multiple timeframe options (1h, 1d, 7d, 30d, 90d, 1y)
- Detailed market statistics for each coin (market cap, volume, supply, etc.)
- Modern, responsive UI built with Flutter
- Cached API responses for improved performance

## Backend (Go)

The backend is built in Go and provides several API endpoints:

- `/api/coins` - List of available cryptocurrencies
- `/api/prices/:symbol` - Price data for a specific cryptocurrency
- `/api/prices/:symbol/:timeframe` - Price data for a specific timeframe
- `/api/stats/:symbol` - Detailed market statistics
- `/api/chart/:symbol` - PNG chart image

### Running the Backend

1. Navigate to the backend directory:
```bash
cd backend
```

2. Run the Go server:
```bash
go run main.go fetch.go
```

The backend server will start on `http://localhost:8080`.

### Testing Backend Endpoints

You can use the included test script to verify all endpoints are working correctly:

```bash
chmod +x test_endpoints.sh
./test_endpoints.sh
```

## Frontend (Flutter)

The frontend is built with Flutter and consumes the backend API endpoints.

### Requirements

- Flutter SDK (latest stable version)
- Dart SDK
- An IDE with Flutter support (VS Code, Android Studio, etc.)

### Running the Frontend

1. Navigate to the frontend directory:
```bash
cd frontend
```

2. Get Flutter dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run -d chrome
```
Or use your preferred device/emulator instead of chrome.

## Architecture

- **Backend**: Go server with custom in-memory caching and CORS support
- **Frontend**: Flutter app using Provider for state management
- **API**: RESTful API endpoints with JSON responses
- **Data Source**: CoinGecko public API

## Future Improvements

- User authentication and personalized portfolios
- Real-time price updates using WebSockets
- Search functionality for coins
- Detailed coin view with additional statistics
- Price alerts and notifications

## License

MIT License - See LICENSE file for details.
