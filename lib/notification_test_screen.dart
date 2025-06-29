import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fcm_service.dart';
import 'api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'shared_preferences.dart';
import 'config.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({Key? key}) : super(key: key);

  @override
  _NotificationTestScreenState createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  String? _fcmToken;
  String? _userId;
  String _testResult = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
    _loadUserId();
  }

  Future<void> _loadFCMToken() async {
    final token = await FCMService().getStoredFCMToken();
    setState(() {
      _fcmToken = token;
    });
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
    });
  }

  Future<void> _refreshFCMToken() async {
    setState(() => _isLoading = true);
    try {
      await FCMService().initialize();
      await _loadFCMToken();
      Fluttertoast.showToast(
        msg: "FCM token refreshed successfully",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error refreshing FCM token: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registerTokenWithBackend() async {
    if (_fcmToken == null || _userId == null) {
      Fluttertoast.showToast(
        msg: "FCM token or user ID not available",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await FCMService().registerTokenWithBackend(_userId!);
      if (result['success']) {
        Fluttertoast.showToast(
          msg: "FCM token registered with backend successfully",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Failed to register FCM token: ${result['message']}",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error registering FCM token: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _subscribeToTopic() async {
    setState(() => _isLoading = true);
    try {
      await FCMService().subscribeToTopic('test_topic');
      Fluttertoast.showToast(
        msg: "Subscribed to test_topic successfully",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error subscribing to topic: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unsubscribeFromTopic() async {
    setState(() => _isLoading = true);
    try {
      await FCMService().unsubscribeFromTopic('test_topic');
      Fluttertoast.showToast(
        msg: "Unsubscribed from test_topic successfully",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error unsubscribing from topic: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testFCMTokenUpdate() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing FCM token update...\n';
    });

    try {
      // Get current user ID
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId == null) {
        setState(() {
          _testResult += '❌ No user ID found. Please login first.\n';
          _isLoading = false;
        });
        return;
      }

      _testResult += 'User ID: $userId\n';
      
      // Test FCM token status
      final tokenStatus = FCMService().getTokenStatus();
      _testResult += 'Token Status: $tokenStatus\n';
      
      // Test enhanced FCM token update
      _testResult += 'Testing enhanced FCM token update...\n';
      final result = await FCMService().updateTokenForUserEnhanced(userId);
      _testResult += 'Enhanced Update Result: $result\n';
      
      // Test API directly
      _testResult += 'Testing API directly...\n';
      final apiResult = await ApiService.updateFCMToken(_fcmToken!, userId);
      _testResult += 'Direct API Result: $apiResult\n';
      
      setState(() {
        _testResult += '✅ Test completed!\n';
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _testResult += '❌ Test error: $e\n';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Sending test notification...\n';
    });

    try {
      // Get current user ID
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId == null) {
        setState(() {
          _testResult += '❌ No user ID found. Please login first.\n';
          _isLoading = false;
        });
        return;
      }

      // Send test notification to the current user
      final response = await http.post(
        Uri.parse('${Config.getApiBaseUrl()}/notification/test'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${prefs.getString('token')}',
        },
        body: jsonEncode({
          'userId': userId,
          'title': 'Test Notification',
          'body': 'This is a test notification from the app!',
          'type': 'test',
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _testResult += '✅ Test notification sent successfully!\n';
          _isLoading = false;
        });
      } else {
        setState(() {
          _testResult += '❌ Failed to send test notification: ${response.statusCode}\n';
          _testResult += 'Response: ${response.body}\n';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _testResult += '❌ Error sending test notification: $e\n';
        _isLoading = false;
      });
    }
  }

  // Test FCM token update for laundry owners
  Future<void> _testLaundryOwnerFCMUpdate() async {
    setState(() {
      _isLoading = true;
      _testResult += '🏪 === LAUNDRY OWNER FCM TOKEN UPDATE TEST ===\n';
    });

    try {
      // Get current user info
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');
      final currentUserRole = prefs.getString('user_role');
      
      _testResult += 'Current User ID: $currentUserId\n';
      _testResult += 'Current User Role: $currentUserRole\n';
      
      if (currentUserId == null) {
        _testResult += '❌ No user ID found - user not logged in\n';
        setState(() => _isLoading = false);
        return;
      }
      
      // Test comprehensive token update
      _testResult += '🔄 Testing comprehensive FCM token update...\n';
      final result = await FCMService().comprehensiveTokenUpdate(currentUserId);
      
      if (result['success']) {
        _testResult += '✅ FCM token update successful!\n';
        _testResult += 'Response: ${result['message']}\n';
        _testResult += 'Step: ${result['step']}\n';
        
        // Subscribe to laundry owner topics
        _testResult += '🎯 Subscribing to laundry owner topics...\n';
        await FCMService().subscribeToRoleTopics('LAUNDRY');
        _testResult += '✅ Laundry owner topics subscribed\n';
        
        // Get token status
        final tokenStatus = FCMService().getTokenStatus();
        _testResult += 'Token Status: $tokenStatus\n';
        
      } else {
        _testResult += '❌ FCM token update failed\n';
        _testResult += 'Error: ${result['message']}\n';
        _testResult += 'Step: ${result['step']}\n';
        
        // Log detailed debug information
        if (result['loginStatus'] != null) {
          _testResult += 'Login Status: ${result['loginStatus']}\n';
        }
        if (result['tokenStatus'] != null) {
          _testResult += 'Token Status: ${result['tokenStatus']}\n';
        }
        if (result['apiTest'] != null) {
          _testResult += 'API Test: ${result['apiTest']}\n';
        }
        if (result['updateResult'] != null) {
          _testResult += 'Update Result: ${result['updateResult']}\n';
        }
        if (result['regResult'] != null) {
          _testResult += 'Registration Result: ${result['regResult']}\n';
        }
      }
      
      _testResult += '=== END LAUNDRY OWNER FCM TEST ===\n\n';
      
    } catch (e) {
      _testResult += '❌ Error in laundry owner FCM test: $e\n';
      _testResult += '=== END LAUNDRY OWNER FCM TEST ===\n\n';
    }
    
    setState(() => _isLoading = false);
  }

  // Test FCM token update for customers
  Future<void> _testCustomerFCMUpdate() async {
    setState(() {
      _isLoading = true;
      _testResult += '👤 === CUSTOMER FCM TOKEN UPDATE TEST ===\n';
    });

    try {
      // Get current user info
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');
      final currentUserRole = prefs.getString('user_role');
      
      _testResult += 'Current User ID: $currentUserId\n';
      _testResult += 'Current User Role: $currentUserRole\n';
      
      if (currentUserId == null) {
        _testResult += '❌ No user ID found - user not logged in\n';
        setState(() => _isLoading = false);
        return;
      }
      
      // Test comprehensive token update
      _testResult += '🔄 Testing comprehensive FCM token update...\n';
      final result = await FCMService().comprehensiveTokenUpdate(currentUserId);
      
      if (result['success']) {
        _testResult += '✅ FCM token update successful!\n';
        _testResult += 'Response: ${result['message']}\n';
        _testResult += 'Step: ${result['step']}\n';
        
        // Subscribe to customer topics
        _testResult += '🎯 Subscribing to customer topics...\n';
        await FCMService().subscribeToRoleTopics('CUSTOMER');
        _testResult += '✅ Customer topics subscribed\n';
        
        // Get token status
        final tokenStatus = FCMService().getTokenStatus();
        _testResult += 'Token Status: $tokenStatus\n';
        
      } else {
        _testResult += '❌ FCM token update failed\n';
        _testResult += 'Error: ${result['message']}\n';
        _testResult += 'Step: ${result['step']}\n';
        
        // Log detailed debug information
        if (result['loginStatus'] != null) {
          _testResult += 'Login Status: ${result['loginStatus']}\n';
        }
        if (result['tokenStatus'] != null) {
          _testResult += 'Token Status: ${result['tokenStatus']}\n';
        }
        if (result['apiTest'] != null) {
          _testResult += 'API Test: ${result['apiTest']}\n';
        }
        if (result['updateResult'] != null) {
          _testResult += 'Update Result: ${result['updateResult']}\n';
        }
        if (result['regResult'] != null) {
          _testResult += 'Registration Result: ${result['regResult']}\n';
        }
      }
      
      _testResult += '=== END CUSTOMER FCM TEST ===\n\n';
      
    } catch (e) {
      _testResult += '❌ Error in customer FCM test: $e\n';
      _testResult += '=== END CUSTOMER FCM TEST ===\n\n';
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Test'),
        backgroundColor: const Color(0xFF424242),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FCM Token',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _fcmToken ?? 'No FCM token available',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _refreshFCMToken,
                            child: const Text('Refresh Token'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _registerTokenWithBackend,
                            child: const Text('Register with Backend'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Topic Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _subscribeToTopic,
                            child: const Text('Subscribe to Test Topic'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _unsubscribeFromTopic,
                            child: const Text('Unsubscribe'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('User ID: ${_userId ?? 'Not available'}'),
                    const SizedBox(height: 8),
                    const Text(
                      'Note: This screen is for testing FCM functionality. In a production app, you would typically not expose FCM tokens to users.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testFCMTokenUpdate,
              child: Text('Test FCM Token Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF424242),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendTestNotification,
              child: Text('Send Test Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF424242),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testLaundryOwnerFCMUpdate,
              child: Text('Test Laundry Owner FCM Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF424242),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testCustomerFCMUpdate,
              child: Text('Test Customer FCM Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF424242),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Results:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _testResult.isEmpty ? 'No test results yet' : _testResult,
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 