# FCM Token Update Implementation for Laundry Owners

## Overview

This document explains how FCM (Firebase Cloud Messaging) token updates work for laundry owners in the laundry app. The implementation ensures that laundry owners receive proper notifications for new orders, order status updates, and other important events.

## Key Features

### 1. Role-Specific FCM Token Updates

The app now handles FCM token updates differently for laundry owners vs customers:

- **Laundry Owners**: Receive notifications for new orders, order status changes, and customer inquiries
- **Customers**: Receive notifications for order status updates, service notifications, and promotional messages

### 2. Automatic Token Updates

FCM tokens are automatically updated in the following scenarios:

- **After Login**: Both existing and new users get their FCM tokens updated
- **After Registration**: New users get their FCM tokens registered
- **Token Refresh**: When FCM tokens are refreshed by Firebase

### 3. Role-Specific Topic Subscriptions

Laundry owners are automatically subscribed to relevant FCM topics:

- `laundry_owners` - General notifications for laundry owners
- `new_orders` - Notifications when new orders are placed
- `order_updates` - Notifications for order status changes

## Implementation Details

### Login Screen Enhancements

The login screen (`lib/login_screen.dart`) has been enhanced with:

1. **Role-Specific Logging**: Different log messages for laundry owners vs customers
2. **Comprehensive Token Updates**: Uses `FCMService().comprehensiveTokenUpdate()` method
3. **Topic Subscriptions**: Automatically subscribes to role-specific topics after successful token update
4. **Error Handling**: Detailed error logging and retry mechanisms

```dart
// Example from login_screen.dart
Future<void> _updateFCMTokenAfterLogin(String userId) async {
  // Role-specific logging
  if (_selectedRole.toUpperCase() == 'LAUNDRY') {
    print('🏪 Laundry Owner Login - FCM Token Update');
    print('Laundry owners need FCM tokens for:');
    print('- New order notifications');
    print('- Order status updates');
    print('- Customer inquiries');
  }
  
  // Use comprehensive FCM service method
  final result = await FCMService().comprehensiveTokenUpdate(userId);
  
  if (result['success']) {
    // Subscribe to role-specific topics
    await _subscribeToRoleTopics();
  }
}
```

### FCM Service Enhancements

The FCM service (`lib/fcm_service.dart`) includes:

1. **Role-Specific Topic Management**:
   ```dart
   Future<void> subscribeToRoleTopics(String role) async {
     if (role.toUpperCase() == 'LAUNDRY') {
       await subscribeToTopic('laundry_owners');
       await subscribeToTopic('new_orders');
       await subscribeToTopic('order_updates');
     }
   }
   ```

2. **Comprehensive Token Update Method**: Handles token refresh, API calls, and error recovery
3. **Debug Methods**: Detailed logging for troubleshooting FCM issues

### Logout Cleanup

The profile screen (`lib/profile_screen.dart`) now properly cleans up FCM subscriptions on logout:

```dart
Future<void> _logout() async {
  // Unsubscribe from role-specific FCM topics
  final userRole = prefs.getString('user_role');
  if (userRole != null) {
    await FCMService().unsubscribeFromRoleTopics(userRole);
  }
  
  // Clear FCM token
  await FCMService().clearFCMToken();
  
  // Perform logout API call
  await ApiService.logout();
}
```

## Testing

### Notification Test Screen

The notification test screen (`lib/notification_test_screen.dart`) includes specific tests for laundry owners:

1. **Test Laundry Owner FCM Update**: Tests the complete FCM token update process for laundry owners
2. **Test Customer FCM Update**: Tests the complete FCM token update process for customers
3. **Role-Specific Topic Subscriptions**: Verifies that laundry owners are subscribed to the correct topics

### Debug Information

The implementation includes comprehensive logging:

- Token status and validity
- API call results
- Topic subscription status
- Error details and retry attempts

## Backend Integration

The FCM token update uses the following API endpoints:

- **PUT** `/notification/user/{userId}/fcm-token` - Updates FCM token for existing users
- **POST** `/notification/user/{userId}/fcm-token` - Registers FCM token for new users

The token is sent in JSON format:
```json
{
  "fcmToken": "user_fcm_token_here"
}
```

## Troubleshooting

### Common Issues

1. **Token Not Updating**: Check if the user is properly logged in and has a valid user ID
2. **Topic Subscription Failures**: Verify that the FCM service is properly initialized
3. **API Call Failures**: Check network connectivity and API endpoint availability

### Debug Steps

1. Use the notification test screen to run role-specific tests
2. Check the console logs for detailed error information
3. Verify that the user role is correctly stored in SharedPreferences
4. Test the API endpoints directly to ensure they're working

### Log Messages to Look For

**Successful Laundry Owner Login:**
```
🏪 Laundry Owner Login - FCM Token Update
✅ FCM token updated successfully after login
🏪 Laundry owner FCM token registered successfully
Ready to receive new order notifications
✅ Laundry owner subscribed to topics: laundry_owners, new_orders, order_updates
```

**Failed Token Update:**
```
❌ Failed to update FCM token after login
🏪 Laundry owner FCM token update failed
This may affect new order notifications
```

## Best Practices

1. **Always test FCM functionality** after login for both roles
2. **Monitor console logs** for FCM-related errors
3. **Handle token refresh** gracefully when Firebase refreshes tokens
4. **Clean up subscriptions** on logout to prevent notification leaks
5. **Use role-specific topics** to ensure notifications reach the right users

## Future Enhancements

1. **Token Validation**: Add server-side validation of FCM tokens
2. **Retry Mechanisms**: Implement exponential backoff for failed token updates
3. **Token Analytics**: Track token update success rates and failure reasons
4. **Push Notification History**: Store and display notification history in the app

## Flow Diagram

```
App Startup
    ↓
Initialize Firebase & FCM
    ↓
Check User Login Status
    ↓
[User Logged In?]
    ↓ Yes
Validate FCM Token
    ↓
[Token Valid?]
    ↓ Yes
Update Token with Backend
    ↓
[Success?]
    ↓ Yes
✅ Token Updated
    ↓ No
⚠️ Log Error (Non-blocking)

[Token Valid?]
    ↓ No
Force Refresh Token
    ↓
[Success?]
    ↓ Yes
Update Token with Backend
    ↓
[Success?]
    ↓ Yes
✅ Token Updated
    ↓ No
⚠️ Log Error (Non-blocking)
```

## Login Flow

```
User Login
    ↓
Validate Credentials
    ↓
[Login Success?]
    ↓ Yes
Update FCM Token
    ↓
[Token Update Success?]
    ↓ Yes
✅ Continue to Home
    ↓ No
⚠️ Log Error (Continue to Home)
```

## Registration Flow

```
User Registration
    ↓
Get FCM Token (Force Refresh)
    ↓
Register User with Token
    ↓
[Registration Success?]
    ↓ Yes
Update FCM Token
    ↓
[Token Update Success?]
    ↓ Yes
✅ Continue to Home
    ↓ No
⚠️ Log Error (Continue to Home)
```

## Error Handling

### 1. Non-Critical Errors
- FCM token update failures don't block user login/registration
- Errors are logged for debugging but not shown to users
- App continues to function normally

### 2. Fallback Mechanisms
- If primary token update fails, try alternative methods
- Force token refresh if current token is invalid
- Multiple retry attempts with different approaches

### 3. Logging
- Comprehensive logging for debugging
- Clear success/failure indicators
- Detailed error messages and status codes

## Debugging

### Console Logs to Look For:

#### Successful Token Update:
```
=== FCM TOKEN UPDATE AFTER LOGIN ===
User ID: 123
User Role: CUSTOMER
✅ FCM token updated successfully after login
Response: FCM token updated successfully
Token Status: {hasToken: true, tokenLength: 152, tokenPreview: fMEP0vJqS6y..., isValid: true}
=== END FCM TOKEN UPDATE ===
```

#### Failed Token Update:
```
=== FCM TOKEN UPDATE AFTER LOGIN ===
User ID: 123
User Role: CUSTOMER
❌ Failed to update FCM token after login
Error: Network error: Connection timeout
Trying alternative method - force refresh token...
✅ Token refreshed successfully, retrying update...
✅ FCM token update successful after retry
=== END FCM TOKEN UPDATE ===
```

#### App Startup Validation:
```
=== FCM TOKEN VALIDATION ON STARTUP ===
Token Status: {hasToken: true, tokenLength: 152, tokenPreview: fMEP0vJqS6y..., isValid: true}
User logged in: true
User ID: 123
✅ Valid FCM token found, updating with backend...
✅ FCM token updated successfully on startup
=== END FCM TOKEN VALIDATION ===
```

## Testing

### Test Scenarios:

1. **Fresh Login**: User logs in for the first time
2. **Returning User**: User logs in with existing session
3. **Token Refresh**: FCM token is refreshed during session
4. **Network Issues**: Token update fails due to network problems
5. **Invalid Token**: Token becomes invalid and needs refresh
6. **App Restart**: App is restarted with existing login session

### Test Commands:

```bash
# Check FCM token status
flutter logs | grep "FCM"

# Monitor token updates
flutter logs | grep "TOKEN UPDATE"

# Check for errors
flutter logs | grep "❌"
```

## Configuration

### Required Dependencies:
- `firebase_messaging`: For FCM functionality
- `shared_preferences`: For token persistence
- `http`: For API calls

### Environment Variables:
- `FCM_SERVER_KEY`: Firebase server key (configured in Firebase console)
- `API_BASE_URL`: Backend API base URL

## Security Considerations

1. **Token Storage**: FCM tokens are stored locally using SharedPreferences
2. **API Security**: Token updates use authenticated API calls
3. **Token Validation**: Tokens are validated before sending to backend
4. **Error Handling**: Sensitive information is not exposed in error messages

## Conclusion

The FCM token update implementation provides a robust, non-blocking solution for managing FCM tokens in the laundry app. It ensures that users receive push notifications reliably while maintaining a smooth user experience during login and registration flows. 