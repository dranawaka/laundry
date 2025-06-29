# FCM Token Registration Implementation

## Overview

This document describes the implementation of FCM (Firebase Cloud Messaging) token registration in the laundry app.

## Endpoint Specification

The FCM token registration endpoint follows this specification:

- **Method**: PUT
- **URL**: `/notification/user/{userId}/fcm-token`
- **Request Body**:
```json
{
  "fcmToken": "firebase-fcm-token-here"
}
```

## Implementation Details

### 1. API Service (`lib/api_service.dart`)

The `ApiService` class provides the following methods for FCM token management:

#### `registerFCMToken(String fcmToken, String userId)`
- Registers a new FCM token for a user
- Uses PUT method to `/notification/user/{userId}/fcm-token`
- Returns success/error response

#### `updateFCMToken(String fcmToken, String userId)`
- Updates an existing FCM token for a user
- Uses the same endpoint as registration (PUT method)
- Returns success/error response

### 2. FCM Service (`lib/fcm_service.dart`)

The `FCMService` class handles:

#### Automatic Token Registration
- Automatically registers tokens with the backend when:
  - A new token is obtained during app initialization
  - A token is refreshed by Firebase
- Only registers if the user is logged in

#### Manual Token Registration
- `registerTokenWithBackend(String userId)` method for manual registration
- Can be called from other parts of the app when needed

### 3. Integration Points

#### Login Screen (`lib/login_screen.dart`)
- Registers FCM token after successful login
- Updates FCM token for existing users

#### Notification Test Screen (`lib/notification_test_screen.dart`)
- Provides UI for testing FCM token registration
- Allows manual registration and token refresh

## Usage Examples

### Automatic Registration
FCM tokens are automatically registered when:
1. User logs in successfully
2. App starts and user is already logged in
3. Firebase refreshes the FCM token

### Manual Registration
```dart
// Register FCM token manually
final result = await FCMService().registerTokenWithBackend(userId);
if (result['success']) {
  print('FCM token registered successfully');
} else {
  print('Failed to register: ${result['message']}');
}
```

### Direct API Call
```dart
// Direct API call
final result = await ApiService.registerFCMToken(fcmToken, userId);
if (result['success']) {
  print('FCM token registered successfully');
} else {
  print('Failed to register: ${result['message']}');
}
```

## Error Handling

The implementation includes comprehensive error handling:

1. **Network Errors**: Connection failures, timeouts
2. **API Errors**: Server errors, validation errors
3. **Token Errors**: Missing or invalid FCM tokens
4. **User Errors**: User not logged in

## Testing

Use the Notification Test Screen to:
1. View current FCM token
2. Refresh FCM token
3. Register token with backend
4. Test topic subscription/unsubscription

## Backend Requirements

The backend should implement the endpoint:
- `PUT /notification/user/{userId}/fcm-token`
- Accept JSON body with `fcmToken` field
- Return appropriate success/error responses

## Security Considerations

1. FCM tokens are stored locally in SharedPreferences
2. Tokens are only sent to the backend when user is authenticated
3. HTTPS is used for all API communications
4. User ID validation is performed before token registration 