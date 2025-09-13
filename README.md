# SamaNet Project

A comprehensive messaging application consisting of:

## Components

### Backend API (`SamaNetMessaegingAppApi/`)
- .NET Core Web API
- RESTful endpoints for users, messages, and file handling
- SQLite database
- Real-time messaging with SignalR

### Mobile App (`sama_net_messaging_app_mobile/`)
- Flutter cross-platform mobile application
- BLoC state management pattern
- Real-time messaging interface
- File sharing capabilities

## Getting Started

### Prerequisites
- .NET 6.0 or later
- Flutter SDK
- Android Studio / Xcode for mobile development

### Running the API
```bash
cd SamaNetMessaegingAppApi
dotnet run
```

### Running the Mobile App
```bash
cd sama_net_messaging_app_mobile
flutter pub get
flutter run
```

## Development

The API runs on `https://localhost:7073` by default.
The mobile app is configured to connect to this endpoint.

## Project Structure

- `SamaNetMessaegingAppApi/` - Backend .NET API
- `sama_net_messaging_app_mobile/` - Flutter mobile application
