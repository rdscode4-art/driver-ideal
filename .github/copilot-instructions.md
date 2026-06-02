# RiDeal Driver App - Copilot Instructions

## Architecture Overview

This is a Flutter driver app for the RiDeal ride-sharing platform using **GetX** for state management and routing. The app follows a feature-first structure with clear separation of concerns.

### Core Structure
```
lib/
├── controllers/          # GetX controllers (business logic)
├── presentation/         # UI screens and widgets
├── services/            # API services and external integrations
├── core/               # Core utilities (storage, constants)
├── data/               # Data models and repositories
├── domain/             # Business entities and use cases
└── routes/             # App navigation and routing
```

## Key Patterns & Conventions

### State Management with GetX
- **Controllers**: Use `Get.put()` for dependency injection in screens
- **Reactive Variables**: Use `.obs` for reactive state (e.g., `var isLoading = false.obs`)
- **Navigation**: Use `Get.toNamed(Routes.SCREEN_NAME)` for navigation
- **Snackbars**: Use `Get.snackbar()` for user feedback messages

### API Integration
- **Base URL**: `https://ride.bhoomi.cloud`
- **Authentication**: Bearer token stored via `StorageHelper.getAuthToken()`
- **API Service Pattern**: Centralized in `rides_api_service.dart` and `driver_api_service.dart`
- **Response Format**: Always return `Map<String, dynamic>` with `success` boolean flag

### Critical API Endpoints
```dart
// Accept ride (POST)
POST /rides/rides/accept
Body: {"rideId": "string"}

// Get available rides (GET)
GET /rides/rides/available

// Update driver status (PATCH)
PATCH /driver/status
Body: {"status": "online|offline"}
```

## Essential Development Workflows

### Adding New Features
1. Create controller in `controllers/` with GetX pattern
2. Add API methods to appropriate service class
3. Create UI in `presentation/` using Obx() for reactive updates
4. Add routes to `app_pages.dart` and `app_routes.dart`

### Ride Management Flow
1. **Available Rides**: `RidesController` manages ride list and acceptance
2. **Accept Ride**: Calls API, updates UI, shows loading dialog
3. **Driver Status**: `HomeController` manages online/offline state
4. **Real-time Updates**: Manual refresh patterns (no WebSocket yet)

### Error Handling Pattern
```dart
try {
  final response = await apiService.method();
  if (response['success'] == true) {
    // Handle success
  } else {
    Get.snackbar('Error', response['message']);
  }
} catch (e) {
  Get.snackbar('Error', 'Network error: $e');
}
```

## UI/UX Conventions

### Color Scheme
- **Primary**: Blue[700] (`Colors.blue[700]`)
- **Success**: Green shades for earnings and positive states
- **Warning**: Orange for notifications and pending states
- **Cards**: Rounded corners (12-15px), subtle elevation (2-4)

### Common Widgets
- **Status Cards**: Driver online/offline with toggle switches
- **Ride Cards**: Pickup/dropoff with icons, fare prominently displayed
- **Loading States**: `CircularProgressIndicator` with descriptive text
- **Empty States**: Icon + message + retry button pattern

## Testing & Debugging

### Build Commands
```bash
flutter pub get                 # Install dependencies
flutter run                     # Run debug mode
flutter build apk --release     # Build release APK
flutter clean                   # Clean build cache
```

### Common Debug Points
- **Authentication**: Check `StorageHelper.getAuthToken()` for token issues
- **API Errors**: Enable logging in API services for response debugging
- **State Issues**: Use `print()` statements in controllers for state tracking
- **Navigation**: Verify route names in `app_routes.dart`

## Data Models

### Ride Entity
```dart
class Ride {
  final String id;              // MongoDB ObjectId
  final String pickupLocation;  // Human-readable address
  final String dropoffLocation; // Human-readable address
  final String rideType;        // "sedan", "bike", "ev", "suv"
  final double estimatedFare;   // Fare amount
  final String status;          // "pending", "accepted", "completed"
  // ... other fields
}
```

### Driver States
- **Online**: Receiving ride requests, can accept rides
- **Offline**: Not receiving requests, hidden from riders
- **In Trip**: Currently on an active ride (future state)

## External Dependencies

### Key Packages
- `get: ^4.6.6` - State management and routing
- `geolocator: ^11.0.0` - Location services
- `shared_preferences: ^2.5.3` - Local storage
- `https: ^1.1.0` - API calls
- `image_picker: ^1.1.2` - Document/photo uploads

### Platform Integration
- **Android**: Minimum SDK 21, location permissions required
- **iOS**: Location usage description in Info.plist
- **Permissions**: Location (always), camera, storage for driver verification

## Quick Start Checklist

1. **Setup**: Run `flutter pub get` to install dependencies
2. **Authentication**: Ensure valid bearer token in storage
3. **Driver Status**: Toggle online in HomeScreen to start receiving rides
4. **Accept Rides**: Use AvailableRidesScreen or quick-accept from HomeScreen
5. **Testing**: Use API endpoints with your auth token for debugging

## Common Issues & Solutions

- **Empty Ride List**: Check driver status (must be online) and API connectivity
- **Accept Ride Fails**: Verify ride still available (not already accepted)
- **Token Expired**: Implement refresh token logic or re-authenticate
- **Location Issues**: Check permissions and GPS enablement on device
