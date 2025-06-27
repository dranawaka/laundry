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
      print('Attempting login to: $url'); // Debug log
      
      // Prepare request body for Spring Boot backend
      final requestBody = {
        'email': email,
        'password': password,
        'role': role.toUpperCase(), // Ensure role is uppercase
      };
      
      print('Login request body: ${jsonEncode(requestBody)}'); // Debug log
      
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(requestBody),
      ).timeout(Duration(milliseconds: Config.connectionTimeout));

      print('Login response status: ${response.statusCode}'); // Debug log
      print('Login response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle Spring Boot response format
        String message = 'Login successful';
        if (data is Map<String, dynamic>) {
          message = data['message'] ?? data['msg'] ?? message;
        }
        
        // Save user data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', data['id']?.toString() ?? '');
        await prefs.setString('user_name', data['name'] ?? '');
        await prefs.setString('user_email', data['email'] ?? '');
        await prefs.setString('user_phone', data['phone'] ?? '');
        await prefs.setString('user_role', data['role'] ?? '');
        await prefs.setBool('is_logged_in', true);
        
        return {
          'success': true,
          'message': message,
          'data': data,
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
    return {
      'id': prefs.getString('user_id'),
      'name': prefs.getString('user_name'),
      'email': prefs.getString('user_email'),
      'phone': prefs.getString('user_phone'),
      'role': prefs.getString('user_role'),
    };
  }

  // Test connection to backend
  static Future<bool> testConnection() async {
    try {
      final url = Config.getApiBaseUrl();
      print('Testing connection to: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 5));
      
      print('Connection test response: ${response.statusCode}');
      return response.statusCode < 500; // Any response means server is reachable
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
} 