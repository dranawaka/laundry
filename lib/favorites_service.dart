import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class FavoritesService {
  static const String _favoritesKey = 'user_favorites';
  static List<Map<String, dynamic>> _favorites = [];
  
  // Get all favorites
  static List<Map<String, dynamic>> get favorites => List.unmodifiable(_favorites);
  
  // Initialize favorites from storage
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey);
      
      if (favoritesJson != null) {
        final List<dynamic> favoritesList = jsonDecode(favoritesJson);
        _favorites = favoritesList.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      print('Error initializing favorites: $e');
      _favorites = [];
    }
  }
  
  // Add laundry to favorites
  static Future<bool> addToFavorites(Map<String, dynamic> laundry) async {
    try {
      // Check if already in favorites
      if (_favorites.any((fav) => fav['id'] == laundry['id'])) {
        return false; // Already in favorites
      }
      
      // Add to favorites
      _favorites.add(laundry);
      
      // Save to storage
      await _saveToStorage();
      
      // Sync with backend if user is logged in
      await _syncWithBackend(laundry['id'], true);
      
      return true;
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }
  
  // Remove laundry from favorites
  static Future<bool> removeFromFavorites(int laundryId) async {
    try {
      final initialLength = _favorites.length;
      _favorites.removeWhere((fav) => fav['id'] == laundryId);
      
      if (_favorites.length < initialLength) {
        // Save to storage
        await _saveToStorage();
        
        // Sync with backend if user is logged in
        await _syncWithBackend(laundryId, false);
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }
  
  // Check if laundry is in favorites
  static bool isFavorite(int laundryId) {
    return _favorites.any((fav) => fav['id'] == laundryId);
  }
  
  // Get favorite by ID
  static Map<String, dynamic>? getFavorite(int laundryId) {
    try {
      return _favorites.firstWhere((fav) => fav['id'] == laundryId);
    } catch (e) {
      return null;
    }
  }
  
  // Clear all favorites
  static Future<void> clearFavorites() async {
    try {
      _favorites.clear();
      await _saveToStorage();
    } catch (e) {
      print('Error clearing favorites: $e');
    }
  }
  
  // Save favorites to storage
  static Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = jsonEncode(_favorites);
      await prefs.setString(_favoritesKey, favoritesJson);
    } catch (e) {
      print('Error saving favorites to storage: $e');
    }
  }
  
  // Sync favorites with backend
  static Future<void> _syncWithBackend(int laundryId, bool isAdding) async {
    try {
      final userData = await ApiService.getCurrentUser();
      final userId = userData['id'];
      final isLoggedIn = await ApiService.isLoggedIn();
      
      if (isLoggedIn && userId != null) {
        // TODO: Implement backend API call to sync favorites
        // This would typically be:
        // if (isAdding) {
        //   await ApiService.addToFavorites(userId, laundryId);
        // } else {
        //   await ApiService.removeFromFavorites(userId, laundryId);
        // }
        print('Would sync favorite with backend: laundryId=$laundryId, isAdding=$isAdding');
      }
    } catch (e) {
      print('Error syncing favorites with backend: $e');
    }
  }
  
  // Load favorites from backend (for logged-in users)
  static Future<void> loadFavoritesFromBackend() async {
    try {
      final isLoggedIn = await ApiService.isLoggedIn();
      if (!isLoggedIn) return;
      
      // TODO: Implement backend API call to load user favorites
      // This would typically be:
      // final userData = await ApiService.getCurrentUser();
      // final userId = userData['id'];
      // final result = await ApiService.getUserFavorites(userId);
      // if (result['success']) {
      //   _favorites = List<Map<String, dynamic>>.from(result['data']);
      //   await _saveToStorage();
      // }
      print('Would load favorites from backend');
    } catch (e) {
      print('Error loading favorites from backend: $e');
    }
  }
  
  // Get favorites count
  static int get favoritesCount => _favorites.length;
  
  // Check if favorites list is empty
  static bool get isEmpty => _favorites.isEmpty;
  
  // Check if favorites list is not empty
  static bool get isNotEmpty => _favorites.isNotEmpty;
} 