# Firebase Cloud Messaging (FCM) Setup Guide

This guide will help you set up Firebase Cloud Messaging for your Flutter laundry app.

## Prerequisites

1. A Google account
2. Flutter project with the dependencies already added to `pubspec.yaml`

## Step 1: Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter a project name (e.g., "Laundry App")
4. Choose whether to enable Google Analytics (optional)
5. Click "Create project"

## Step 2: Add Android App to Firebase

1. In your Firebase project console, click the Android icon (</>) to add an Android app
2. Enter your Android package name: `com.example.laundry`
3. Enter app nickname (optional): "Laundry App"
4. Click "Register app"
5. Download the `google-services.json` file
6. Place the downloaded `google-services.json` file in the `android/app/` directory of your Flutter project

## Step 3: Add iOS App to Firebase (if needed)

1. In your Firebase project console, click the iOS icon to add an iOS app
2. Enter your iOS bundle ID: `com.example.laundry`
3. Enter app nickname (optional): "Laundry App"
4. Click "Register app"
5. Download the `GoogleService-Info.plist` file
6. Place the downloaded `GoogleService-Info.plist` file in the `ios/Runner/` directory of your Flutter project

## Step 4: Update Configuration Files

### Replace Placeholder Values

The configuration files in this project contain placeholder values. You need to replace them with your actual Firebase project values:

#### For Android (`android/app/google-services.json`):
- Replace `YOUR_PROJECT_NUMBER` with your actual project number
- Replace `your-laundry-app-id` with your actual project ID
- Replace `YOUR_APP_ID` with your actual app ID
- Replace `YOUR_CLIENT_ID` with your actual client ID
- Replace `YOUR_API_KEY` with your actual API key

#### For iOS (`ios/Runner/GoogleService-Info.plist`):
- Replace `YOUR_API_KEY` with your actual API key
- Replace `YOUR_PROJECT_NUMBER` with your actual project number
- Replace `your-laundry-app-id` with your actual project ID
- Replace `YOUR_APP_ID` with your actual app ID

## Step 5: Install Dependencies

Run the following command to install the Firebase dependencies:

```bash
flutter pub get
```

## Step 6: Test FCM Integration

1. Run your app on a device or emulator
2. Check the console logs for FCM token generation
3. The app should request notification permissions on first launch

## Step 7: Backend Integration

Your Spring Boot backend needs to be configured to send FCM notifications. Here are the key endpoints that should be implemented:

### FCM Token Management Endpoints:

1. **Register FCM Token**
   ```
   POST /users/fcm-token
   Body: {
     "userId": "string",
     "fcmToken": "string"
   }
   ```

2. **Update FCM Token**
   ```
   PUT /users/fcm-token/{userId}
   Body: {
     "fcmToken": "string"
   }
   ```

3. **Delete FCM Token**
   ```
   DELETE /users/fcm-token/{userId}
   ```

### Sending Notifications:

Your backend can send notifications using the Firebase Admin SDK. Here's an example structure:

```java
// Example notification payload
{
  "notification": {
    "title": "Order Update",
    "body": "Your order #123 has been completed!"
  },
  "data": {
    "type": "order_update",
    "orderId": "123",
    "status": "completed"
  },
  "token": "user_fcm_token_here"
}
```

## Step 8: Notification Types

The app is configured to handle different types of notifications:

1. **Order Updates** (`type: "order_update"`)
   - Navigate to orders screen
   - Show order status changes

2. **New Orders** (`type: "new_order"`)
   - Navigate to specific order
   - For laundry owners

3. **Promotions** (`type: "promotion"`)
   - Show promotional content
   - Special offers and discounts

## Troubleshooting

### Common Issues:

1. **FCM Token not generated**
   - Check if Firebase is properly initialized
   - Verify `google-services.json` is in the correct location
   - Check console logs for initialization errors

2. **Notifications not showing**
   - Verify notification permissions are granted
   - Check if the app is in foreground/background
   - Verify notification channel is created (Android)

3. **Build errors**
   - Ensure all dependencies are installed
   - Check if `google-services.json` is valid
   - Verify package name matches Firebase configuration

### Debug Commands:

```bash
# Check if dependencies are properly installed
flutter doctor

# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check for FCM logs
flutter logs
```

## Security Notes

1. Never commit real Firebase configuration files to public repositories
2. Use environment variables for sensitive configuration
3. Implement proper authentication before sending notifications
4. Validate FCM tokens on the backend

## Additional Features

The FCM service includes these additional features:

- **Topic Subscription**: Subscribe to specific topics (e.g., "promotions", "order_updates")
- **Token Management**: Automatic token refresh and storage
- **Background Message Handling**: Process messages when app is closed
- **Local Notifications**: Show notifications even when app is in foreground
- **Deep Linking**: Navigate to specific screens when notification is tapped

## Support

If you encounter issues:

1. Check the Firebase Console for any configuration errors
2. Review the console logs for detailed error messages
3. Verify all configuration files are properly placed
4. Ensure your device/emulator has internet connectivity 