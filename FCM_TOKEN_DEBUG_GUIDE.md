# FCM Token Update Debugging Guide

This guide helps you debug and fix FCM token update issues for existing users in your laundry app.

## Problem Description

FCM token updates for existing users are not happening properly, which means users may not receive push notifications after logging in.

## Debugging Steps

### 1. Check Console Logs

Look for these log patterns in your Flutter console:

#### Successful Token Update:
```
=== FCM TOKEN UPDATE AFTER LOGIN ===
User ID: 123
User Role: CUSTOMER
🔍 === COMPREHENSIVE FCM TOKEN UPDATE ===
User ID: 123
Login Status: {isLoggedIn: true, userId: 123, hasToken: true, readyForFCMUpdate: true}
FCM Token Status: {hasToken: true, tokenLength: 152, isValid: true}
🔄 Testing API connectivity...
🔄 Attempting token update...
✅ Token update successful
✅ FCM token updated successfully after login
```

#### Failed Token Update:
```
=== FCM TOKEN UPDATE AFTER LOGIN ===
User ID: 123
User Role: CUSTOMER
🔍 === COMPREHENSIVE FCM TOKEN UPDATE ===
User ID: 123
Login Status: {isLoggedIn: false, userId: null, hasToken: false, readyForFCMUpdate: false}
❌ Failed to update FCM token after login
Error: User not properly logged in
Step: login_check
```

### 2. Use the Notification Test Screen

Navigate to the notification test screen and use the "Test FCM Token Update" button to get detailed debugging information.

### 3. Common Issues and Solutions

#### Issue 1: User Not Properly Logged In
**Symptoms:**
- `Login Status: {isLoggedIn: false, userId: null, hasToken: false, readyForFCMUpdate: false}`

**Solutions:**
1. Check if the login process is properly saving user data to SharedPreferences
2. Verify that `user_id`, `token`, and `is_logged_in` are being set correctly
3. Check the login API response structure

#### Issue 2: FCM Token Not Available
**Symptoms:**
- `FCM Token Status: {hasToken: false, tokenLength: 0, isValid: false}`

**Solutions:**
1. Check Firebase configuration
2. Verify internet connectivity
3. Check if Firebase Messaging is properly initialized
4. Try forcing a token refresh

#### Issue 3: API Connectivity Issues
**Symptoms:**
- `API Test: {success: false, message: 'API connectivity failed'}`

**Solutions:**
1. Check network connectivity
2. Verify API base URL configuration
3. Check if the authentication token is valid
4. Verify the backend endpoint is working

#### Issue 4: Backend API Errors
**Symptoms:**
- `Update Result: {success: false, message: 'Failed to update FCM token', statusCode: 400}`

**Solutions:**
1. Check the backend API endpoint `/notification/user/{userId}/fcm-token`
2. Verify the request format and headers
3. Check backend logs for errors
4. Verify user authentication on the backend

### 4. Testing Commands

#### Check FCM Token Status:
```dart
final status = FCMService().getTokenStatus();
print('Token Status: $status');
```

#### Check User Login Status:
```dart
final loginStatus = await FCMService().checkUserLoginStatus();
print('Login Status: $loginStatus');
```

#### Force Token Refresh:
```dart
final newToken = await FCMService().forceRefreshToken();
print('New Token: $newToken');
```

#### Test Comprehensive Update:
```dart
final result = await FCMService().comprehensiveTokenUpdate('userId');
print('Result: $result');
```

### 5. Backend Verification

#### Check Backend Endpoint:
```bash
curl -X PUT \
  http://your-api-url/notification/user/123/fcm-token \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer your-token' \
  -d '{
    "fcmToken": "your-fcm-token"
  }'
```

#### Expected Response:
```json
{
  "success": true,
  "message": "FCM token updated successfully"
}
```

### 6. Debugging Checklist

- [ ] User is properly logged in (`is_logged_in: true`)
- [ ] User ID is available (`user_id` is not null)
- [ ] Authentication token is valid (`token` is not null)
- [ ] FCM token is available (`_fcmToken` is not null)
- [ ] Firebase is properly initialized
- [ ] Network connectivity is working
- [ ] Backend API is accessible
- [ ] Backend endpoint is working correctly
- [ ] Authentication is valid on backend

### 7. Common Fixes

#### Fix 1: Ensure Proper Login Data Storage
```dart
// In login success handler
final prefs = await SharedPreferences.getInstance();
await prefs.setBool('is_logged_in', true);
await prefs.setString('user_id', result['data']['id']);
await prefs.setString('token', result['data']['token']);
```

#### Fix 2: Force FCM Token Refresh
```dart
// Force refresh FCM token
final newToken = await FCMService().forceRefreshToken();
if (newToken != null) {
  // Try update again
  final result = await FCMService().comprehensiveTokenUpdate(userId);
}
```

#### Fix 3: Check API Headers
```dart
// Ensure proper headers are set
static Map<String, String> get _headers {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  return {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
```

### 8. Monitoring and Logging

#### Add to your main.dart:
```dart
// Monitor FCM token updates
FirebaseMessaging.onTokenRefresh.listen((newToken) {
  print('FCM Token refreshed: $newToken');
  // Automatically update with backend
  FCMService()._registerTokenWithBackend();
});
```

#### Add to your login screen:
```dart
// After successful login
print('=== LOGIN SUCCESS DEBUG ===');
final prefs = await SharedPreferences.getInstance();
print('is_logged_in: ${prefs.getBool('is_logged_in')}');
print('user_id: ${prefs.getString('user_id')}');
print('token: ${prefs.getString('token')?.substring(0, 20)}...');
print('=== END LOGIN DEBUG ===');
```

### 9. Testing Scenarios

1. **Fresh Login**: New user logs in for the first time
2. **Returning User**: Existing user logs in again
3. **Token Refresh**: FCM token is refreshed during session
4. **Network Issues**: Token update fails due to network problems
5. **Invalid Token**: Authentication token is invalid
6. **Backend Down**: Backend API is not accessible

### 10. Success Indicators

When FCM token updates are working correctly, you should see:

1. ✅ Successful login with proper data storage
2. ✅ FCM token obtained and valid
3. ✅ API connectivity test passes
4. ✅ Token update API call succeeds
5. ✅ Push notifications are received
6. ✅ No errors in console logs

### 11. Next Steps

If you're still experiencing issues:

1. Check the detailed logs from the comprehensive token update method
2. Use the notification test screen to run diagnostics
3. Verify backend API endpoints and authentication
4. Test with a fresh user account
5. Check Firebase console for any configuration issues

## Conclusion

The enhanced FCM token update system provides comprehensive debugging and multiple fallback mechanisms. Use the debugging tools and logs to identify the specific issue and apply the appropriate fix. 