# FCM Token Integration with User Registration

This document outlines the complete integration of Firebase Cloud Messaging (FCM) tokens with user registration and authentication in your laundry app.

## Overview

The app now automatically captures and manages FCM tokens during user registration and login, enabling push notifications for order updates, promotions, and other important events.

## Flutter Implementation

### 1. Registration Flow

When a user registers, the app automatically:
- Captures the FCM token from the device
- Sends it along with user registration data
- Backend stores the token and subscribes user to relevant topics

```dart
// Registration request now includes FCM token
final result = await ApiService.register(
  username: _usernameController.text.trim(),
  email: _signupEmailController.text.trim(),
  password: _signupPasswordController.text,
  phone: _phoneController.text.trim(),
  role: _selectedRole,
  fcmToken: FCMService().fcmToken, // FCM token included
);
```

### 2. Login Flow

When a user logs in, the app:
- Updates the FCM token for existing users
- Ensures the token is current and valid
- Re-subscribes to relevant topics

```dart
// Update FCM token after successful login
await _updateFCMToken(result['data']['id']);
```

### 3. API Service Updates

The `ApiService.register()` method now accepts an optional `fcmToken` parameter:

```dart
static Future<Map<String, dynamic>> register({
  required String username,
  required String email,
  required String password,
  required String phone,
  required String role,
  String? fcmToken, // New parameter
}) async {
  // ... existing code ...
  
  // Add FCM token if available
  if (fcmToken != null && fcmToken.isNotEmpty) {
    requestBody['fcmToken'] = fcmToken;
  }
  
  // ... rest of the method ...
}
```

## Backend Implementation

### 1. Database Schema

Add FCM token column to your users table:

```sql
-- Add FCM token column to users table
ALTER TABLE users ADD COLUMN fcm_token VARCHAR(500);

-- Create index for FCM token lookups
CREATE INDEX idx_users_fcm_token ON users(fcm_token);
```

### 2. User Entity

Update your User entity to include FCM token:

```java
@Entity
@Table(name = "users")
public class User {
    // ... existing fields ...
    
    @Column(name = "fcm_token")
    private String fcmToken;
    
    // Getters and setters
    public String getFcmToken() {
        return fcmToken;
    }
    
    public void setFcmToken(String fcmToken) {
        this.fcmToken = fcmToken;
    }
}
```

### 3. Registration DTO

Update your registration request DTO:

```java
public class UserRegistrationRequest {
    private String name;
    private String email;
    private String phone;
    private String password;
    private UserRole role;
    private String fcmToken; // New field
    
    // Getters and setters
    public String getFcmToken() {
        return fcmToken;
    }
    
    public void setFcmToken(String fcmToken) {
        this.fcmToken = fcmToken;
    }
}
```

### 4. User Service

Implement FCM token management in your user service:

```java
@Service
public class UserService {
    
    public User registerUser(UserRegistrationRequest request) {
        // ... validation ...
        
        User user = new User();
        user.setName(request.getName());
        user.setEmail(request.getEmail());
        user.setPhone(request.getPhone());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setRole(request.getRole());
        user.setFcmToken(request.getFcmToken()); // Save FCM token
        
        User savedUser = userRepository.save(user);
        
        // Subscribe user to appropriate topics
        subscribeUserToTopics(savedUser);
        
        return savedUser;
    }
    
    public void updateFCMToken(Long userId, String fcmToken) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new RuntimeException("User not found"));
        
        user.setFcmToken(fcmToken);
        userRepository.save(user);
        
        // Re-subscribe to topics with new token
        subscribeUserToTopics(user);
    }
    
    private void subscribeUserToTopics(User user) {
        if (user.getFcmToken() == null) return;
        
        try {
            // Subscribe to role-based topics
            String roleTopic = getUserTopic(user.getRole());
            firebaseMessaging.subscribeToTopic(
                List.of(user.getFcmToken()), 
                roleTopic
            );
            
            // Subscribe to general order updates
            firebaseMessaging.subscribeToTopic(
                List.of(user.getFcmToken()), 
                "order_updates"
            );
        } catch (Exception e) {
            System.err.println("Error subscribing user to topics: " + e.getMessage());
        }
    }
}
```

### 5. API Endpoints

#### Registration Endpoint

```http
POST /auth/register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "1234567890",
  "password": "password123",
  "role": "CUSTOMER",
  "fcmToken": "your-fcm-token-here"
}
```

#### FCM Token Management Endpoints

```http
# Register/Update FCM token
POST /users/fcm-token
PUT /users/fcm-token/{userId}
DELETE /users/fcm-token/{userId}

# Request body for POST/PUT
{
  "userId": 123,
  "fcmToken": "your-fcm-token-here"
}
```

## Topic Management

### Automatic Topic Subscription

Users are automatically subscribed to topics based on their role:

- **Customers**: `customers`, `order_updates`, `promotions`
- **Laundry Owners**: `laundry_owners`, `order_updates`, `new_orders`

### Manual Topic Management

Users can also subscribe/unsubscribe to specific topics:

```dart
// Subscribe to specific topic
await FCMService().subscribeToTopic('promotions');

// Unsubscribe from topic
await FCMService().unsubscribeFromTopic('promotions');
```

## Notification Types

### 1. Order Updates

```json
{
  "notification": {
    "title": "Order Update",
    "body": "Your order #123 has been completed!"
  },
  "data": {
    "type": "order_update",
    "orderId": "123",
    "status": "completed"
  }
}
```

### 2. New Orders (for laundry owners)

```json
{
  "notification": {
    "title": "New Order Received",
    "body": "New order #456 from John Doe"
  },
  "data": {
    "type": "new_order",
    "orderId": "456",
    "customerName": "John Doe"
  }
}
```

### 3. Promotions

```json
{
  "notification": {
    "title": "Special Offer!",
    "body": "Get 20% off on your next order"
  },
  "data": {
    "type": "promotion",
    "promotionId": "promo123"
  }
}
```

## Testing

### 1. Flutter App Testing

1. Navigate to **Profile → Notification Settings**
2. View your FCM token
3. Test topic subscription
4. Register token with backend

### 2. Backend Testing

Test the registration endpoint with FCM token:

```bash
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "phone": "1234567890",
    "password": "password123",
    "role": "CUSTOMER",
    "fcmToken": "test-fcm-token-123"
  }'
```

### 3. Notification Testing

Send test notifications using Firebase Console or your backend:

```java
// Send test notification
Map<String, Object> payload = NotificationHelper.getTestNotificationPayload(fcmToken);
firebaseMessaging.send(payload);
```

## Error Handling

### Flutter Side

- FCM token generation failures are logged but don't block registration
- Network errors during token registration are handled gracefully
- Token refresh is automatic

### Backend Side

- Invalid FCM tokens are logged but don't block user registration
- Topic subscription failures are logged but don't affect user creation
- Token updates are idempotent

## Security Considerations

1. **Token Validation**: Validate FCM tokens on the backend before storing
2. **Token Expiration**: Handle expired tokens gracefully
3. **User Consent**: Ensure users have granted notification permissions
4. **Data Privacy**: Don't log sensitive FCM token data

## Best Practices

1. **Token Refresh**: Always handle token refresh events
2. **Error Logging**: Log FCM-related errors for debugging
3. **Graceful Degradation**: App should work without FCM tokens
4. **Testing**: Test notifications on both foreground and background states
5. **User Experience**: Provide clear feedback about notification permissions

## Troubleshooting

### Common Issues

1. **FCM Token Not Generated**
   - Check Firebase configuration
   - Verify Google Services files are in place
   - Check device internet connectivity

2. **Notifications Not Received**
   - Verify user has granted notification permissions
   - Check if user is subscribed to correct topics
   - Verify FCM token is valid and not expired

3. **Backend Registration Fails**
   - Check FCM token format
   - Verify Firebase Admin SDK configuration
   - Check database schema for FCM token column

### Debug Commands

```bash
# Check FCM token in Flutter logs
flutter logs | grep FCM

# Test Firebase connection
flutter run --verbose

# Check backend logs for FCM errors
tail -f application.log | grep FCM
```

## Next Steps

1. **Implement Backend**: Add FCM token support to your Spring Boot backend
2. **Test Integration**: Test the complete flow from registration to notification
3. **Add Analytics**: Track notification engagement and delivery rates
4. **User Preferences**: Add notification preferences in the app
5. **Advanced Features**: Implement rich notifications, action buttons, and deep linking 