import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class UserPreferences {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUsername = 'username';

  // Save login status
  static Future<bool> setLoggedIn(bool isLoggedIn) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_keyIsLoggedIn, isLoggedIn);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Save username
  static Future<bool> setUsername(String username) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(_keyUsername, username);
  }

  // Get username
  static Future<String> getUsername() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername) ?? '';
  }

  // Clear all data
  static Future<bool> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }
}