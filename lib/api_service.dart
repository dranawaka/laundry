import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class ApiService {
  // Headers for API requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Login API call
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final url = Config.getApiUrl(Config.loginEndpoint);
      final requestBody = {
        'email': email,
        'password': password,
        'role': role.toUpperCase(),
      };
      print('ApiService.login called');
      print('URL: ' + url);
      print('Request body: ' + requestBody.toString());
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(requestBody),
      ).timeout(Duration(milliseconds: Config.connectionTimeout));
      print('Response status: \\${response.statusCode}');
      print('Response body: \\${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle Spring Boot response format
        String message = 'Login successful';
        if (data is Map<String, dynamic>) {
          message = data['message'] ?? data['msg'] ?? message;
        }
        
        // Save user data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', data['id'] != null ? data['id'].toString() : '');
        await prefs.setString('user_name', data['name'] ?? '');
        await prefs.setString('user_email', data['email'] ?? '');
        await prefs.setString('user_phone', data['phone'] ?? '');
        await prefs.setString('user_role', data['role'] ?? '');
        await prefs.setBool('is_logged_in', true);
        print('Saved user role: \'${data['role']}\''); // Debug print
        
        return {
          'success': true,
          'message': message,
          'data': {
            ...data,
            'id': data['id'] != null ? data['id'].toString() : '', // Always String in returned data
          },
        };
      } else {
        // Handle Spring Boot error responses
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Login failed';
        
        if (errorData is Map<String, dynamic>) {
          // Handle different error response formats
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          } else if (errorData['msg'] != null) {
            errorMessage = errorData['msg'];
          } else if (errorData['detail'] != null) {
            errorMessage = errorData['detail'];
          }
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } on SocketException catch (e) {
      print('=== CONNECTION ERROR ===');
      print('SocketException: ${e.message}');
      print('OS Error: ${e.osError}');
      print('Address: ${e.address}');
      print('Port: ${e.port}');
      print('=== END CONNECTION ERROR ===');
      
      return {
        'success': false,
        'message': 'Connection failed: Unable to reach the server at ${Config.getApiBaseUrl()}. Please check:\n\n1. Is your Spring Boot backend running?\n2. Is it running on port 8080?\n3. If using emulator, try http://10.0.2.2:8080\n4. If using physical device, use your computer\'s IP address',
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'message': 'Request timeout: The server took too long to respond. Please try again.',
        };
    } on FormatException catch (e) {
      return {
        'success': false,
        'message': 'Invalid response format from server: ${e.message}',
      };
    } catch (e) {
      print('=== UNEXPECTED ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: ${e.toString()}');
      print('=== END UNEXPECTED ERROR ===');
      
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Register API call
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String phone,
    required String role,
    String? fcmToken,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
  }) async {
    try {
      final url = Config.getApiUrl(Config.registerEndpoint);
      print('=== REGISTRATION DEBUG INFO ===');
      print('Attempting registration to: $url');
      print('Base URL: ${Config.getApiBaseUrl()}');
      print('Endpoint: $Config.registerEndpoint');
      
      // Prepare request body for Spring Boot backend - matching your exact format
      final requestBody = {
        'name': username, // Using 'name' as expected by your backend
        'email': email,
        'phone': phone,
        'password': password,
        'role': role.toUpperCase(), // Ensure role is uppercase as expected
      };
      
      // Add address fields if provided
      if (address != null && address.isNotEmpty) {
        requestBody['address'] = address;
      }
      if (city != null && city.isNotEmpty) {
        requestBody['city'] = city;
      }
      if (state != null && state.isNotEmpty) {
        requestBody['state'] = state;
      }
      if (zipCode != null && zipCode.isNotEmpty) {
        requestBody['zipCode'] = zipCode;
      }
      if (country != null && country.isNotEmpty) {
        requestBody['country'] = country;
      }
      
      // Add FCM token if available
      if (fcmToken != null && fcmToken.isNotEmpty) {
        requestBody['fcmToken'] = fcmToken;
        print('Including FCM token in registration');
      }
      
      print('Registration request body: ${jsonEncode(requestBody)}');
      print('Headers: $_headers');
      
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(requestBody),
      ).timeout(Duration(milliseconds: Config.connectionTimeout));

      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');
      print('=== END REGISTRATION DEBUG ===');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle Spring Boot response format
        String message = 'Registration successful';
        if (data is Map<String, dynamic>) {
          message = data['message'] ?? data['msg'] ?? message;
          
          // Save user data to SharedPreferences after successful registration
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', data['id']?.toString() ?? '');
          await prefs.setString('user_name', data['name'] ?? '');
          await prefs.setString('user_email', data['email'] ?? '');
          await prefs.setString('user_phone', data['phone'] ?? '');
          await prefs.setString('user_role', data['role'] ?? '');
          await prefs.setBool('is_logged_in', true);
        }
        
        return {
          'success': true,
          'message': message,
          'data': data,
        };
      } else {
        // Handle Spring Boot error responses
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Registration failed';
        
        if (errorData is Map<String, dynamic>) {
          // Handle different error response formats
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          } else if (errorData['msg'] != null) {
            errorMessage = errorData['msg'];
          } else if (errorData['detail'] != null) {
            errorMessage = errorData['detail'];
          }
          
          // Handle validation errors
          if (errorData['errors'] != null && errorData['errors'] is List) {
            final errors = errorData['errors'] as List;
            if (errors.isNotEmpty) {
              errorMessage = errors.first.toString();
            }
          }
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } on SocketException catch (e) {
      return {
        'success': false,
        'message': 'Connection failed: Unable to reach the server. Please check if the backend is running and the URL is correct.',
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'message': 'Request timeout: The server took too long to respond. Please try again.',
        };
    } on FormatException catch (e) {
      return {
        'success': false,
        'message': 'Invalid response format from server: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Logout API call
  static Future<Map<String, dynamic>> logout() async {
    try {
      // Since your API doesn't use token-based authentication,
      // we'll just clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      return {
        'success': true,
        'message': 'Logout successful',
      };
    } catch (e) {
      // Clear local storage even if there's an error
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      return {
        'success': true,
        'message': 'Logout successful',
      };
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  // Get current user info
  static Future<Map<String, String?>> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = {
      'id': prefs.getString('user_id'), // Always return as String
      'name': prefs.getString('user_name'),
      'email': prefs.getString('user_email'),
      'phone': prefs.getString('user_phone'),
      'role': prefs.getString('user_role'),
    };
    print('🔵 getCurrentUser data: $userData');
    return userData;
  }

  // Test connection to backend
  static Future<bool> testConnection() async {
    try {
      final url = Config.getApiBaseUrl();
      print('🔵 Testing connection to: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 5));
      
      print('🔵 Connection test response: ${response.statusCode}');
      print('🔵 Connection test body: ${response.body}');
      
      final isConnected = response.statusCode < 500; // Any response means server is reachable
      print(isConnected ? '✅ Connection successful' : '❌ Connection failed');
      return isConnected;
    } catch (e) {
      print('❌ Connection test exception: $e');
      return false;
    }
  }

  // Place new order
  static Future<Map<String, dynamic>> placeOrder({
    required int customerId,
    required int laundryId,
    required DateTime pickupDate,
    required DateTime deliveryDate,
    required String pickupAddress,
    required String deliveryAddress,
    String? specialInstructions,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final url = '${Config.getApiBaseUrl()}/orders/place';
      print('Placing order to: $url');
      
      final requestBody = {
        'customerId': customerId,
        'laundryId': laundryId,
        'pickupDate': pickupDate.toIso8601String(),
        'deliveryDate': deliveryDate.toIso8601String(),
        'pickupAddress': pickupAddress,
        'deliveryAddress': deliveryAddress,
        'specialInstructions': specialInstructions,
        'items': items,
      };
      
      print('Order request body: $requestBody');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          ..._headers,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 30));
      
      print('Order placement response: ${response.statusCode}');
      print('Order placement response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
          'message': 'Order placed successfully',
        };
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['error'] ?? errorData['message'] ?? 'Failed to place order',
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Failed to place order: ${response.body}',
          };
        }
      }
    } catch (e) {
      print('Error placing order: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get customer orders
  static Future<Map<String, dynamic>> getCustomerOrders(int customerId) async {
    try {
      final url = '${Config.getApiBaseUrl()}/orders/customer/$customerId';
      print('Getting customer orders from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      
      print('Get customer orders response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch orders',
        };
      }
    } catch (e) {
      print('Error getting customer orders: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get order by ID
  static Future<Map<String, dynamic>> getOrderById(int orderId) async {
    try {
      final url = '${Config.getApiBaseUrl()}/orders/$orderId';
      print('Getting order from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      
      print('Get order response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch order',
        };
      }
    } catch (e) {
      print('Error getting order: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get laundry orders (for laundry owners)
  static Future<Map<String, dynamic>> getLaundryOrders(int laundryId) async {
    try {
      final url = '${Config.getApiBaseUrl()}/orders/laundry/$laundryId';
      print('Getting laundry orders from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      
      print('Get laundry orders response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch orders',
        };
      }
    } catch (e) {
      print('Error getting laundry orders: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get nearby laundry services
  static Future<Map<String, dynamic>> getNearbyServices({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      final url = Uri.parse(Config.getApiUrl(Config.nearbyServicesEndpoint)).replace(
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'radiusKm': radiusKm.toString(),
        },
      );
      
      print('=== NEARBY SERVICES DEBUG INFO ===');
      print('Fetching nearby services from: $url');
      
      final response = await http.get(
        url,
        headers: _headers,
      ).timeout(Duration(milliseconds: Config.connectionTimeout));

      print('Nearby services response status: ${response.statusCode}');
      print('Nearby services response body: ${response.body}');
      print('=== END NEARBY SERVICES DEBUG ===');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Nearby services fetched successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Failed to fetch nearby services';
        
        if (errorData is Map<String, dynamic>) {
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } on SocketException catch (e) {
      print('=== CONNECTION ERROR ===');
      print('SocketException: ${e.message}');
      print('=== END CONNECTION ERROR ===');
      
      return {
        'success': false,
        'message': 'Connection failed: Unable to reach the server.',
      };
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'message': 'Request timeout: The server took too long to respond.',
      };
    } on FormatException catch (e) {
      return {
        'success': false,
        'message': 'Invalid response format from server: ${e.message}',
      };
    } catch (e) {
      print('=== UNEXPECTED ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: ${e.toString()}');
      print('=== END UNEXPECTED ERROR ===');
      
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Laundry Service Management APIs
  static Future<List<dynamic>> getServicesByLaundry(int laundryId) async {
    try {
      final url = Config.getApiUrl('/laundry-services/laundry/$laundryId');
      print('=== GET SERVICES BY LAUNDRY DEBUG ===');
      print('Fetching services for laundry ID: $laundryId');
      print('URL: $url');
      
      final response = await http.get(
        Uri.parse(url), 
        headers: _headers,
      ).timeout(Duration(milliseconds: Config.connectionTimeout));
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed data: $data');
        print('Data type: ${data.runtimeType}');
        
        if (data is List) {
          print('Services found: ${data.length}');
          print('=== END GET SERVICES BY LAUNDRY DEBUG ===');
          return data;
        } else {
          print('Unexpected data format. Expected List, got ${data.runtimeType}');
          print('=== END GET SERVICES BY LAUNDRY DEBUG ===');
          return [];
        }
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
        print('=== END GET SERVICES BY LAUNDRY DEBUG ===');
        throw Exception('Failed to load services: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('=== CONNECTION ERROR ===');
      print('SocketException: ${e.message}');
      print('=== END CONNECTION ERROR ===');
      throw Exception('Connection failed: Unable to reach the server.');
    } on TimeoutException catch (e) {
      print('=== TIMEOUT ERROR ===');
      print('TimeoutException: ${e.message}');
      print('=== END TIMEOUT ERROR ===');
      throw Exception('Request timeout: The server took too long to respond.');
    } on FormatException catch (e) {
      print('=== FORMAT ERROR ===');
      print('FormatException: ${e.message}');
      print('=== END FORMAT ERROR ===');
      throw Exception('Invalid response format from server: ${e.message}');
    } catch (e) {
      print('=== UNEXPECTED ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: ${e.toString()}');
      print('=== END UNEXPECTED ERROR ===');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> createLaundryService(int laundryId, Map<String, dynamic> data) async {
    final url = Config.getApiUrl('/laundry-services/$laundryId');
    final response = await http.post(Uri.parse(url), headers: _headers, body: jsonEncode(data));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateLaundryService(int serviceId, int laundryId, Map<String, dynamic> data) async {
    final url = Config.getApiUrl('/laundry-services/$serviceId/laundry/$laundryId');
    final response = await http.put(Uri.parse(url), headers: _headers, body: jsonEncode(data));
    return jsonDecode(response.body);
  }

  static Future<void> deleteLaundryService(int serviceId, int laundryId) async {
    final url = Config.getApiUrl('/laundry-services/$serviceId/laundry/$laundryId');
    final response = await http.delete(Uri.parse(url), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete service');
    }
  }

  static Future<Map<String, dynamic>> toggleServiceAvailability(int serviceId, int laundryId) async {
    final url = Config.getApiUrl('/laundry-services/$serviceId/laundry/$laundryId/toggle-availability');
    final response = await http.put(Uri.parse(url), headers: _headers);
    return jsonDecode(response.body);
  }

  // Update laundry status (active/inactive)
  static Future<Map<String, dynamic>> updateLaundryStatus(int laundryId, bool isActive) async {
    try {
      final url = '${Config.getApiBaseUrl()}/laundry/services/$laundryId/active?active=$isActive';
      print('Updating laundry status at: $url');
      
      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      
      print('Update laundry status response: ${response.statusCode}');
      print('Update laundry status response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true, 
          'message': data['message'] ?? 'Laundry status updated successfully'
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false, 
          'message': data['error'] ?? data['message'] ?? 'Failed to update laundry status'
        };
      }
    } catch (e) {
      print('Error updating laundry status: $e');
      return {
        'success': false, 
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  // Get laundry status
  static Future<Map<String, dynamic>> getLaundryStatus(int laundryId) async {
    try {
      final url = '${Config.getApiBaseUrl()}/laundry/services/active';
      print('Getting laundry status from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      
      print('Get laundry status response: ${response.statusCode}');
      print('Get laundry status response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch laundry status',
        };
      }
    } catch (e) {
      print('Error getting laundry status: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get all active laundries (fallback when location is not available)
  static Future<Map<String, dynamic>> getAllLaundries() async {
    try {
      final url = '${Config.getApiBaseUrl()}/laundry/services/active';
      print('Getting all active laundries from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      
      print('Get all laundries response: ${response.statusCode}');
      print('Get all laundries response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'All laundries fetched successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Failed to fetch laundries';
        
        if (errorData is Map<String, dynamic>) {
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('Error getting all laundries: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    try {
      final url = '${Config.getApiBaseUrl()}/orders/$orderId/update-status';
      print('Updating order status at: $url');
      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({'status': status}),
      ).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message'] ?? 'Order status updated'};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['error'] ?? data['message'] ?? 'Failed to update status'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    try {
      final url = '${Config.getApiBaseUrl()}/orders/$orderId/cancel';
      print('Cancelling order at: $url');
      final response = await http.delete(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message'] ?? 'Order canceled successfully'};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['error'] ?? data['message'] ?? 'Failed to cancel order'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // FCM Token Management
  static Future<Map<String, dynamic>> registerFCMToken(String fcmToken, String userId) async {
    try {
      final url = '${Config.getApiBaseUrl()}/notification/user/$userId/fcm-token';
      print('Registering FCM token at: $url');
      
      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({
          'fcmToken': fcmToken,
        }),
      ).timeout(Duration(seconds: 10));
      
      print('FCM token registration response: ${response.statusCode}');
      print('FCM token registration response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'FCM token registered successfully',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Failed to register FCM token',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('Error registering FCM token: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateFCMToken(String fcmToken, String userId) async {
    try {
      final url = '${Config.getApiBaseUrl()}/notification/user/$userId/fcm-token';
      print('Updating FCM token at: $url');
      
      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({
          'fcmToken': fcmToken,
        }),
      ).timeout(Duration(seconds: 10));
      
      print('FCM token update response: ${response.statusCode}');
      print('FCM token update response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'FCM token updated successfully',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Failed to update FCM token',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('Error updating FCM token: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> deleteFCMToken(String userId) async {
    try {
      final url = '${Config.getApiBaseUrl()}/users/fcm-token/$userId';
      print('Deleting FCM token at: $url');
      
      final response = await http.delete(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'FCM token deleted successfully',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Failed to delete FCM token',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Submit a rating and review for a laundry (updated to match new endpoint)
  static Future<Map<String, dynamic>> submitLaundryReview({
    required int laundryId,
    required int customerId,
    required double rating,
    required String reviewText,
  }) async {
    final url = Config.getApiUrl('/laundries/$laundryId/rate?customerId=$customerId');
    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode({
        'rating': rating,
        'reviewText': reviewText,
      }),
    );
    return jsonDecode(response.body);
  }

  // Fetch reviews for a laundry
  static Future<List<dynamic>> getLaundryReviews(int laundryId) async {
    final url = Config.getApiUrl('/laundries/$laundryId/reviews');
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  // Check if a customer has already reviewed a laundry
  static Future<bool> hasReviewedLaundry(int laundryId, int customerId) async {
    final url = Config.getApiUrl('/laundries/$laundryId/customer/$customerId/has-reviewed');
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['hasReviewed'] == true;
    }
    return false;
  }

  // ==================== ANALYTICS ENDPOINTS ====================

  // Get analytics summary for a laundry owner
  static Future<Map<String, dynamic>> getAnalyticsSummary(int laundryId) async {
    try {
      final url = '${Config.getApiBaseUrl()}/analytics/summary/$laundryId';
      print('Getting analytics summary from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      
      print('Analytics summary response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch analytics summary',
        };
      }
    } catch (e) {
      print('Error getting analytics summary: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get revenue analytics for a laundry owner
  static Future<Map<String, dynamic>> getRevenueAnalytics(int laundryId) async {
    try {
      final url = '${Config.getApiBaseUrl()}/analytics/revenue/$laundryId';
      print('Getting revenue analytics from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      
      print('Revenue analytics response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch revenue analytics',
        };
      }
    } catch (e) {
      print('Error getting revenue analytics: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get order analytics for a laundry owner
  static Future<Map<String, dynamic>> getOrderAnalytics(int laundryId) async {
    try {
      final url = '${Config.getApiBaseUrl()}/analytics/orders/$laundryId';
      print('Getting order analytics from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      
      print('Order analytics response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch order analytics',
        };
      }
    } catch (e) {
      print('Error getting order analytics: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get service analytics for a laundry owner
  static Future<Map<String, dynamic>> getServiceAnalytics(int laundryId) async {
    try {
      final url = '${Config.getApiBaseUrl()}/analytics/services/$laundryId';
      print('Getting service analytics from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      
      print('Service analytics response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch service analytics',
        };
      }
    } catch (e) {
      print('Error getting service analytics: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get customer analytics for a laundry owner
  static Future<Map<String, dynamic>> getCustomerAnalytics(int laundryId) async {
    try {
      final url = '${Config.getApiBaseUrl()}/analytics/customers/$laundryId';
      print('Getting customer analytics from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      
      print('Customer analytics response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch customer analytics',
        };
      }
    } catch (e) {
      print('Error getting customer analytics: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // ==================== CHAT/MESSAGING ENDPOINTS ====================

  // Get all conversations for a user
  static Future<Map<String, dynamic>> getConversations(int userId) async {
    try {
      final url = '${Config.getApiBaseUrl()}/chat/users/$userId/conversations';
      print('Getting conversations from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      
      print('Conversations response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch conversations',
        };
      }
    } catch (e) {
      print('Error getting conversations: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get messages for a specific conversation
  static Future<Map<String, dynamic>> getMessages(int conversationId, {int page = 0, int limit = 50}) async {
    try {
      // Ensure 0-based page numbering for backend
      final backendPage = page;
      final url = '${Config.getApiBaseUrl()}/chat/conversations/$conversationId/messages?page=$backendPage&limit=$limit';
      print('🔵 Getting messages from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      
      print('🔵 Messages response: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Messages retrieved successfully');
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        print('❌ Error response: $errorData');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch messages',
        };
      }
    } catch (e) {
      print('❌ Exception in getMessages: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Send a new message
  static Future<Map<String, dynamic>> sendMessage({
    required int conversationId,
    required int senderId,
    required String message,
    String messageType = 'text',
  }) async {
    try {
      final url = '${Config.getApiBaseUrl()}/chat/conversations/$conversationId/messages';
      print('🔵 Sending message to: $url');
      
      final requestBody = {
        'senderId': senderId,
        'message': message,
        'messageType': messageType,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      print('🔵 Request body: $requestBody');
      print('🔵 Request headers: $_headers');
      
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 10));
      
      print('🔵 Send message response: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Message sent successfully');
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        print('❌ Error response: $errorData');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to send message',
        };
      }
    } catch (e) {
      print('❌ Exception in sendMessage: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Create or get conversation between customer and laundry
  static Future<Map<String, dynamic>> createOrGetConversation({
    required int customerId,
    required int laundryId,
  }) async {
    try {
      final url = '${Config.getApiBaseUrl()}/chat/conversations';
      print('🔵 Creating/getting conversation at: $url');
      
      final requestBody = {
        'customerId': customerId,
        'laundryId': laundryId,
      };
      
      print('🔵 Request body: $requestBody');
      print('🔵 Request headers: $_headers');
      
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 10));
      
      print('🔵 Create conversation response: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Conversation created/retrieved successfully');
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        print('❌ Error response: $errorData');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create conversation',
        };
      }
    } catch (e) {
      print('❌ Exception in createOrGetConversation: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Mark messages as read
  static Future<Map<String, dynamic>> markMessagesAsRead(int conversationId, int userId) async {
    try {
      final url = '${Config.getApiBaseUrl()}/chat/conversations/$conversationId/read';
      print('Marking messages as read at: $url');
      
      final requestBody = {
        'userId': userId,
        'readAt': DateTime.now().toIso8601String(),
      };
      
      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 10));
      
      print('Mark as read response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to mark messages as read',
        };
      }
    } catch (e) {
      print('Error marking messages as read: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get unread message count for a user
  static Future<Map<String, dynamic>> getUnreadMessageCount(int userId) async {
    try {
      final url = '${Config.getApiBaseUrl()}/chat/users/$userId/unread-count';
      print('Getting unread count from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 10));
      
      print('Unread count response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch unread count',
        };
      }
    } catch (e) {
      print('Error getting unread count: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Fetch full user profile (with address details) from backend
  static Future<Map<String, dynamic>?> getUserProfileFromBackend(String userId) async {
    try {
      final url = Uri.parse('${Config.getApiBaseUrl()}/auth/user/$userId');
      print('Fetching user profile from backend: $url');
      final response = await http.get(url, headers: _headers).timeout(Duration(seconds: 10));
      print('User profile response status: ${response.statusCode}');
      print('User profile response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // If the backend wraps the user in a 'data' field, unwrap it
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          return data['data'] as Map<String, dynamic>;
        }
        return data as Map<String, dynamic>;
      } else {
        print('Failed to fetch user profile: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching user profile from backend: $e');
      return null;
    }
  }
} 