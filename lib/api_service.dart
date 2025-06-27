import 'dart:convert';
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
      final response = await http.post(
        Uri.parse(Config.getApiUrl(Config.loginEndpoint)),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(Duration(milliseconds: Config.connectionTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Save user data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', data['id'].toString());
        await prefs.setString('user_name', data['name']);
        await prefs.setString('user_email', data['email']);
        await prefs.setString('user_phone', data['phone']);
        await prefs.setString('user_role', data['role']);
        await prefs.setBool('is_logged_in', true);
        
        return {
          'success': true,
          'message': 'Login successful',
          'data': data,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
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
      final response = await http.post(
        Uri.parse(Config.getApiUrl(Config.registerEndpoint)),
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'phone': phone,
          'role': role.toLowerCase(),
        }),
      ).timeout(Duration(milliseconds: Config.connectionTimeout));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Registration successful',
          'data': data,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Registration failed',
        };
      }
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
} 