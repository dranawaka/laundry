import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  String? _fcmToken;

  // Getter for FCM token
  String? get fcmToken => _fcmToken;

  // Initialize FCM service
  Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request notification permissions
      await _requestNotificationPermissions();

      // Get FCM token
      await _getFCMToken();

      // Set up message handlers
      _setupMessageHandlers();

      print('FCM Service initialized successfully');
    } catch (e) {
      print('Error initializing FCM Service: $e');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Request notification permissions
  Future<void> _requestNotificationPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  // Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $_fcmToken');

      // Save token to shared preferences
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
        
        // Register token with backend if user is logged in
        await _registerTokenWithBackend();
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('FCM Token refreshed: $newToken');
        _saveTokenToPreferences(newToken);
        _registerTokenWithBackend(); // Register refreshed token
      });
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  // Register FCM token with backend
  Future<void> _registerTokenWithBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      
      if (isLoggedIn && userId != null && _fcmToken != null) {
        print('Registering FCM token with backend for user: $userId');
        final result = await ApiService.registerFCMToken(_fcmToken!, userId);
        if (result['success']) {
          print('FCM token registered successfully with backend');
        } else {
          print('Failed to register FCM token with backend: ${result['message']}');
        }
      } else {
        print('Skipping FCM token registration: user not logged in or token not available');
      }
    } catch (e) {
      print('Error registering FCM token with backend: $e');
    }
  }

  // Save token to shared preferences
  Future<void> _saveTokenToPreferences(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    } catch (e) {
      print('Error saving FCM token to preferences: $e');
    }
  }

  // Set up message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from notification: ${message.data}');
      _handleNotificationTap(message);
    });

    // Handle initial notification when app is launched
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App launched from notification: ${message.data}');
        _handleNotificationTap(message);
      }
    });
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'laundry_app_channel',
      'Laundry App Notifications',
      channelDescription: 'Notifications for laundry service app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: json.encode(message.data),
    );
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      _handleNotificationTap(RemoteMessage(data: data));
    }
  }

  // Handle notification tap logic
  void _handleNotificationTap(RemoteMessage message) {
    // Handle different types of notifications based on data
    final data = message.data;
    
    print('Handling notification tap for type: ${data['type']}');
    
    switch (data['type']) {
      case 'order_update':
      case 'order_status_update':
        // Navigate to orders screen for order updates
        print('Navigate to orders screen for order update');
        _navigateToOrdersScreen();
        break;
        
      case 'new_order':
        // Navigate to specific order for laundry owners
        print('Navigate to specific order: ${data['orderId']}');
        _navigateToSpecificOrder(data['orderId']);
        break;
        
      case 'order_cancelled':
        // Navigate to orders screen for cancelled orders
        print('Navigate to orders screen for cancelled order');
        _navigateToOrdersScreen();
        break;
        
      case 'promotion':
        // Show promotion details
        print('Show promotion: ${data['promotionId']}');
        _showPromotion(data['promotionId']);
        break;
        
      case 'test':
        // Handle test notifications
        print('Test notification received');
        break;
        
      default:
        // Default navigation to orders screen
        print('Default navigation to orders screen');
        _navigateToOrdersScreen();
        break;
    }
  }

  // Navigate to orders screen
  void _navigateToOrdersScreen() {
    // This would typically use a navigation service or global key
    // For now, we'll just print the action
    print('Should navigate to orders screen');
  }

  // Navigate to specific order
  void _navigateToSpecificOrder(String? orderId) {
    if (orderId != null) {
      print('Should navigate to order details screen for order: $orderId');
    } else {
      print('Order ID is null, navigating to orders screen');
      _navigateToOrdersScreen();
    }
  }

  // Show promotion details
  void _showPromotion(String? promotionId) {
    if (promotionId != null) {
      print('Should show promotion details for: $promotionId');
    } else {
      print('Promotion ID is null');
    }
  }

  // Subscribe to topics
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  // Subscribe to role-specific topics
  Future<void> subscribeToRoleTopics(String role) async {
    try {
      print('🎯 Subscribing to role-specific topics for: $role');
      
      if (role.toUpperCase() == 'LAUNDRY') {
        // Laundry owner topics
        await subscribeToTopic('laundry_owners');
        await subscribeToTopic('new_orders');
        await subscribeToTopic('order_updates');
        print('✅ Laundry owner subscribed to: laundry_owners, new_orders, order_updates');
      } else if (role.toUpperCase() == 'CUSTOMER') {
        // Customer topics
        await subscribeToTopic('customers');
        await subscribeToTopic('order_updates');
        await subscribeToTopic('promotions');
        print('✅ Customer subscribed to: customers, order_updates, promotions');
      } else {
        print('⚠️ Unknown role: $role - no topics subscribed');
      }
    } catch (e) {
      print('❌ Error subscribing to role topics: $e');
    }
  }

  // Unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }

  // Unsubscribe from role-specific topics
  Future<void> unsubscribeFromRoleTopics(String role) async {
    try {
      print('🎯 Unsubscribing from role-specific topics for: $role');
      
      if (role.toUpperCase() == 'LAUNDRY') {
        // Laundry owner topics
        await unsubscribeFromTopic('laundry_owners');
        await unsubscribeFromTopic('new_orders');
        await unsubscribeFromTopic('order_updates');
        print('✅ Laundry owner unsubscribed from: laundry_owners, new_orders, order_updates');
      } else if (role.toUpperCase() == 'CUSTOMER') {
        // Customer topics
        await unsubscribeFromTopic('customers');
        await unsubscribeFromTopic('order_updates');
        await unsubscribeFromTopic('promotions');
        print('✅ Customer unsubscribed from: customers, order_updates, promotions');
      } else {
        print('⚠️ Unknown role: $role - no topics unsubscribed');
      }
    } catch (e) {
      print('❌ Error unsubscribing from role topics: $e');
    }
  }

  // Get stored FCM token
  Future<String?> getStoredFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      print('Error getting stored FCM token: $e');
      return null;
    }
  }

  // Clear FCM token
  Future<void> clearFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      _fcmToken = null;
      print('FCM token cleared');
    } catch (e) {
      print('Error clearing FCM token: $e');
    }
  }

  // Public method to register FCM token with backend
  Future<Map<String, dynamic>> registerTokenWithBackend(String userId) async {
    try {
      if (_fcmToken != null) {
        print('Manually registering FCM token with backend for user: $userId');
        final result = await ApiService.registerFCMToken(_fcmToken!, userId);
        return result;
      } else {
        return {
          'success': false,
          'message': 'FCM token not available',
        };
      }
    } catch (e) {
      print('Error manually registering FCM token: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Force refresh FCM token
  Future<String?> forceRefreshToken() async {
    try {
      print('Force refreshing FCM token...');
      _fcmToken = await _firebaseMessaging.getToken();
      print('New FCM Token: $_fcmToken');
      
      if (_fcmToken != null) {
        await _saveTokenToPreferences(_fcmToken!);
        await _registerTokenWithBackend();
      }
      
      return _fcmToken;
    } catch (e) {
      print('Error force refreshing FCM token: $e');
      return null;
    }
  }

  // Get token status for debugging
  Map<String, dynamic> getTokenStatus() {
    return {
      'hasToken': _fcmToken != null,
      'tokenLength': _fcmToken?.length ?? 0,
      'tokenPreview': _fcmToken != null ? '${_fcmToken!.substring(0, 20)}...' : 'null',
      'isValid': isTokenValid,
    };
  }

  // Debug method to test FCM token update for existing users
  Future<Map<String, dynamic>> debugFCMTokenUpdate(String userId) async {
    try {
      print('🔍 === FCM TOKEN UPDATE DEBUG ===');
      print('User ID: $userId');
      
      // Check current token status
      final tokenStatus = getTokenStatus();
      print('Current Token Status: $tokenStatus');
      
      // Check if user is logged in
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final storedUserId = prefs.getString('user_id');
      print('User Login Status: $isLoggedIn');
      print('Stored User ID: $storedUserId');
      
      // Check if we have a valid token
      if (!tokenStatus['isValid']) {
        print('⚠️ No valid token found, attempting to get fresh token...');
        final newToken = await getCurrentToken(forceRefresh: true);
        if (newToken != null) {
          print('✅ Fresh token obtained: ${newToken.substring(0, 20)}...');
        } else {
          print('❌ Failed to get fresh token');
          return {
            'success': false,
            'message': 'Unable to obtain FCM token',
            'debug': 'Token refresh failed',
          };
        }
      }
      
      // Test the API call directly
      print('🔄 Testing API call to update FCM token...');
      final apiResult = await ApiService.updateFCMToken(_fcmToken!, userId);
      print('API Result: $apiResult');
      
      // Test alternative registration method
      print('🔄 Testing alternative registration method...');
      final regResult = await ApiService.registerFCMToken(_fcmToken!, userId);
      print('Registration Result: $regResult');
      
      // Check if token was actually updated
      print('🔄 Verifying token update...');
      final verificationResult = await _verifyTokenUpdate(userId);
      print('Verification Result: $verificationResult');
      
      print('🔍 === END FCM TOKEN UPDATE DEBUG ===');
      
      return {
        'success': apiResult['success'] || regResult['success'],
        'message': apiResult['success'] ? apiResult['message'] : regResult['message'],
        'debug': {
          'tokenStatus': tokenStatus,
          'userLoginStatus': isLoggedIn,
          'storedUserId': storedUserId,
          'apiResult': apiResult,
          'regResult': regResult,
          'verificationResult': verificationResult,
        },
      };
      
    } catch (e) {
      print('❌ Error in debug FCM token update: $e');
      return {
        'success': false,
        'message': 'Debug error: ${e.toString()}',
        'debug': {'error': e.toString()},
      };
    }
  }

  // Verify if token was actually updated on the backend
  Future<Map<String, dynamic>> _verifyTokenUpdate(String userId) async {
    try {
      // This would typically call an endpoint to verify the token
      // For now, we'll just return a mock verification
      return {
        'success': true,
        'message': 'Token verification not implemented',
        'verified': true,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Verification failed: ${e.toString()}',
        'verified': false,
      };
    }
  }

  // Enhanced update method with better error handling
  Future<Map<String, dynamic>> updateTokenForUserEnhanced(String userId) async {
    try {
      print('🚀 === ENHANCED FCM TOKEN UPDATE ===');
      print('User ID: $userId');
      
      // Step 1: Ensure we have a valid token
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        print('📱 Step 1: Getting fresh FCM token...');
        final newToken = await forceRefreshToken();
        if (newToken == null) {
          print('❌ Step 1 Failed: Unable to obtain FCM token');
          return {
            'success': false,
            'message': 'Unable to obtain FCM token',
            'step': 'token_refresh',
          };
        }
        print('✅ Step 1 Success: Token obtained');
      } else {
        print('✅ Step 1: Valid token already available');
      }
      
      // Step 2: Try update method first
      print('🔄 Step 2: Attempting token update...');
      final updateResult = await ApiService.updateFCMToken(_fcmToken!, userId);
      if (updateResult['success']) {
        print('✅ Step 2 Success: Token updated successfully');
        return updateResult;
      }
      print('⚠️ Step 2 Failed: ${updateResult['message']}');
      
      // Step 3: Try registration method as fallback
      print('🔄 Step 3: Attempting token registration as fallback...');
      final regResult = await ApiService.registerFCMToken(_fcmToken!, userId);
      if (regResult['success']) {
        print('✅ Step 3 Success: Token registered successfully');
        return regResult;
      }
      print('❌ Step 3 Failed: ${regResult['message']}');
      
      // Step 4: Try with fresh token
      print('🔄 Step 4: Attempting with fresh token...');
      final freshToken = await forceRefreshToken();
      if (freshToken != null) {
        final freshResult = await ApiService.updateFCMToken(freshToken, userId);
        if (freshResult['success']) {
          print('✅ Step 4 Success: Token updated with fresh token');
          return freshResult;
        }
        print('❌ Step 4 Failed: ${freshResult['message']}');
      }
      
      print('❌ All steps failed');
      return {
        'success': false,
        'message': 'All token update methods failed',
        'step': 'all_failed',
        'updateResult': updateResult,
        'regResult': regResult,
      };
      
    } catch (e) {
      print('❌ Error in enhanced token update: $e');
      return {
        'success': false,
        'message': 'Enhanced update error: ${e.toString()}',
        'step': 'exception',
      };
    }
  }

  // Get current FCM token (with refresh if needed)
  Future<String?> getCurrentToken({bool forceRefresh = false}) async {
    try {
      if (forceRefresh || _fcmToken == null || _fcmToken!.isEmpty) {
        print('Getting fresh FCM token...');
        _fcmToken = await _firebaseMessaging.getToken();
        if (_fcmToken != null) {
          await _saveTokenToPreferences(_fcmToken!);
        }
      }
      return _fcmToken;
    } catch (e) {
      print('Error getting current FCM token: $e');
      return null;
    }
  }

  // Check if FCM token is valid
  bool get isTokenValid => _fcmToken != null && _fcmToken!.isNotEmpty;

  // Alias for backward compatibility
  Future<Map<String, dynamic>> updateTokenForUser(String userId) async {
    return await comprehensiveTokenUpdate(userId);
  }

  // Check if user is properly logged in and ready for FCM token updates
  Future<Map<String, dynamic>> checkUserLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final userId = prefs.getString('user_id');
      final token = prefs.getString('token');
      
      return {
        'isLoggedIn': isLoggedIn,
        'userId': userId,
        'hasToken': token != null,
        'tokenPreview': token != null ? '${token.substring(0, 20)}...' : 'null',
        'readyForFCMUpdate': isLoggedIn && userId != null && token != null,
      };
    } catch (e) {
      return {
        'isLoggedIn': false,
        'userId': null,
        'hasToken': false,
        'tokenPreview': 'null',
        'readyForFCMUpdate': false,
        'error': e.toString(),
      };
    }
  }

  // Comprehensive FCM token update with full validation
  Future<Map<String, dynamic>> comprehensiveTokenUpdate(String userId) async {
    try {
      print('🔍 === COMPREHENSIVE FCM TOKEN UPDATE ===');
      print('User ID: $userId');
      
      // Step 1: Check user login status
      final loginStatus = await checkUserLoginStatus();
      print('Login Status: $loginStatus');
      
      if (!loginStatus['readyForFCMUpdate']) {
        return {
          'success': false,
          'message': 'User not properly logged in',
          'loginStatus': loginStatus,
          'step': 'login_check',
        };
      }
      
      // Step 2: Check FCM token status
      final tokenStatus = getTokenStatus();
      print('FCM Token Status: $tokenStatus');
      
      if (!tokenStatus['isValid']) {
        print('📱 Getting fresh FCM token...');
        final newToken = await forceRefreshToken();
        if (newToken == null) {
          return {
            'success': false,
            'message': 'Unable to obtain FCM token',
            'tokenStatus': tokenStatus,
            'step': 'token_refresh',
          };
        }
      }
      
      // Step 3: Test API connectivity
      print('🔄 Testing API connectivity...');
      final testResult = await _testAPIConnectivity();
      if (!testResult['success']) {
        return {
          'success': false,
          'message': 'API connectivity test failed',
          'apiTest': testResult,
          'step': 'api_test',
        };
      }
      
      // Step 4: Attempt token update
      print('🔄 Attempting token update...');
      final updateResult = await ApiService.updateFCMToken(_fcmToken!, userId);
      if (updateResult['success']) {
        print('✅ Token update successful');
        return {
          'success': true,
          'message': 'FCM token updated successfully',
          'updateResult': updateResult,
          'step': 'update_success',
        };
      }
      
      // Step 5: Try registration as fallback
      print('🔄 Trying registration as fallback...');
      final regResult = await ApiService.registerFCMToken(_fcmToken!, userId);
      if (regResult['success']) {
        print('✅ Token registration successful');
        return {
          'success': true,
          'message': 'FCM token registered successfully',
          'regResult': regResult,
          'step': 'registration_success',
        };
      }
      
      print('❌ All update methods failed');
      return {
        'success': false,
        'message': 'All FCM token update methods failed',
        'updateResult': updateResult,
        'regResult': regResult,
        'step': 'all_failed',
      };
      
    } catch (e) {
      print('❌ Error in comprehensive token update: $e');
      return {
        'success': false,
        'message': 'Comprehensive update error: ${e.toString()}',
        'step': 'exception',
      };
    }
  }

  // Test API connectivity
  Future<Map<String, dynamic>> _testAPIConnectivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }
      
      // Test a simple API call
      final response = await http.get(
        Uri.parse('${Config.getApiBaseUrl()}/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10));
      
      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': response.statusCode == 200 ? 'API connectivity OK' : 'API connectivity failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'API connectivity error: ${e.toString()}',
      };
    }
  }
} 