import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart';
import 'favorites_screen.dart';
import 'dashboard_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'laundry_services_management_screen.dart';
import 'api_service.dart';
import 'fcm_service.dart';
import 'favorites_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== APP STARTUP ===');
  
  // Initialize Firebase first
  await Firebase.initializeApp();
  print('✅ Firebase initialized');
  
  // Initialize FCM service
  await FCMService().initialize();
  print('✅ FCM service initialized');
  
  // Initialize Favorites service
  await FavoritesService.initialize();
  print('✅ Favorites service initialized');
  
  // Check and validate FCM token on startup
  await _validateAndUpdateFCMTokenOnStartup();
  
  print('=== APP STARTUP COMPLETE ===');
  
  runApp(const LaundryApp());
}

// Validate and update FCM token on app startup
Future<void> _validateAndUpdateFCMTokenOnStartup() async {
  try {
    print('=== FCM TOKEN VALIDATION ON STARTUP ===');
    
    // Get current token status
    final tokenStatus = FCMService().getTokenStatus();
    print('Token Status: $tokenStatus');
    
    // Check if user is logged in
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final userId = prefs.getString('user_id');
    
    print('User logged in: $isLoggedIn');
    print('User ID: $userId');
    
    if (isLoggedIn && userId != null) {
      // User is logged in, ensure FCM token is up to date
      if (tokenStatus['isValid']) {
        print('✅ Valid FCM token found, updating with backend...');
        final result = await FCMService().updateTokenForUser(userId);
        if (result['success']) {
          print('✅ FCM token updated successfully on startup');
        } else {
          print('⚠️ FCM token update failed on startup: ${result['message']}');
        }
      } else {
        print('⚠️ Invalid FCM token found, refreshing...');
        final newToken = await FCMService().forceRefreshToken();
        if (newToken != null) {
          print('✅ FCM token refreshed successfully');
          final result = await FCMService().updateTokenForUser(userId);
          if (result['success']) {
            print('✅ FCM token updated successfully after refresh');
          } else {
            print('⚠️ FCM token update failed after refresh: ${result['message']}');
          }
        } else {
          print('❌ Failed to refresh FCM token on startup');
        }
      }
    } else {
      print('ℹ️ User not logged in, skipping FCM token update');
    }
    
    print('=== END FCM TOKEN VALIDATION ===');
    
  } catch (e) {
    print('❌ Error during FCM token validation on startup: $e');
    // Don't throw error as this is not critical for app startup
  }
}

class LaundryApp extends StatelessWidget {
  const LaundryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'LaundryPro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: MaterialColor(
          0xFF424242, // Dark gray as the main color
          <int, Color>{
            50: Color(0xFFFAFAFA),   // Very light gray
            100: Color(0xFFF5F5F5),  // Light gray
            200: Color(0xFFEEEEEE),  // Lighter gray
            300: Color(0xFFE0E0E0),  // Medium light gray
            400: Color(0xFFBDBDBD),  // Medium gray
            500: Color(0xFF9E9E9E),  // Medium dark gray
            600: Color(0xFF757575),  // Dark gray
            700: Color(0xFF616161),  // Darker gray
            800: Color(0xFF424242),  // Main dark gray
            900: Color(0xFF212121),  // Very dark gray
          },
        ),
        scaffoldBackgroundColor: Color(0xFFF8F8F8), // Very light gray background
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121), // Very dark gray for text
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF424242), // Dark gray for body text
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Color(0xFF424242), // Dark gray
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF424242), // Dark gray
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF424242), width: 2),
          ),
        ),
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainScreen(),
      },
    );
  }
}

// Main screen with bottom navigation
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Start with home/dashboard
  late PageController _pageController;
  String? userRole;
  bool isLoading = true;
  int? laundryId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _loadUserRoleAndLaundryId();
  }

  Future<void> _loadUserRoleAndLaundryId() async {
    try {
      final userData = await ApiService.getCurrentUser();
      final idString = userData['id'];
      int? parsedLaundryId = int.tryParse(idString ?? '');
      setState(() {
        userRole = userData['role'];
        isLoading = false;
        laundryId = parsedLaundryId;
      });
      print('User role loaded: $userRole'); // Debug log
      print('Laundry ID loaded: $laundryId'); // Debug log
    } catch (e) {
      print('Error loading user role/laundryId: $e'); // Debug log
      setState(() {
        userRole = 'CUSTOMER'; // Default to customer if error
        isLoading = false;
        laundryId = null;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Get the appropriate screen based on index and user role
  Widget _getScreen(int index) {
    print('_getScreen called with index: $index, userRole: $userRole, laundryId: $laundryId'); // Debug log
    if (index == 0) {
      if (userRole?.toUpperCase() == 'LAUNDRY') {
        print('Returning LaundryServicesManagementScreen for LAUNDRY, laundryId: $laundryId'); // Debug log
        return LaundryServicesManagementScreen(laundryId: laundryId ?? 1); // Use actual laundryId
      } else {
        print('Returning FavoritesScreen for customer role: $userRole'); // Debug log
        return FavoritesScreen();
      }
    } else if (index == 1) {
      return DashboardScreen();
    } else if (index == 2) {
      return OrdersScreen();
    } else if (index == 3) {
      return ProfileScreen();
    }
    return DashboardScreen(); // Default fallback
  }

  // Get the appropriate label based on index and user role
  String _getLabel(int index) {
    if (index == 0) {
      String label = userRole?.toUpperCase() == 'LAUNDRY' ? 'Manage' : 'Favorites';
      print('_getLabel for index 0: $label (userRole: $userRole)'); // Debug log
      return label;
    } else if (index == 1) {
      return 'Home';
    } else if (index == 2) {
      return 'Orders';
    } else if (index == 3) {
      return 'Profile';
    }
    return '';
  }

  // Get the appropriate icon based on index and user role
  Icon _getIcon(int index, bool isActive) {
    if (index == 0) {
      if (userRole?.toUpperCase() == 'LAUNDRY') {
        return Icon(
          isActive ? Icons.manage_accounts : Icons.manage_accounts_outlined,
        );
      } else {
        return Icon(
          isActive ? Icons.favorite : Icons.favorite_outline,
        );
      }
    } else if (index == 1) {
      return Icon(
        isActive ? Icons.home : Icons.home_outlined,
      );
    } else if (index == 2) {
      return Icon(
        isActive ? Icons.receipt_long : Icons.receipt_long_outlined,
      );
    } else if (index == 3) {
      return Icon(
        isActive ? Icons.person : Icons.person_outline,
      );
    }
    return Icon(Icons.home_outlined);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF424242), // Dark gray
              ),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isLaundryOwner = userRole?.toUpperCase() == 'LAUNDRY';

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: isLaundryOwner
            ? [
                _getScreen(0), // Manage
                _getScreen(2), // Orders
                _getScreen(3), // Profile
              ]
            : [
                _getScreen(0), // Favorites
                _getScreen(1), // Dashboard
                _getScreen(2), // Orders
                _getScreen(3), // Profile
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF424242), // Dark gray
          unselectedItemColor: Colors.grey,
          elevation: 0,
          items: isLaundryOwner
              ? [
                  BottomNavigationBarItem(
                    icon: _getIcon(0, false),
                    activeIcon: _getIcon(0, true),
                    label: _getLabel(0),
                  ),
                  BottomNavigationBarItem(
                    icon: _getIcon(2, false),
                    activeIcon: _getIcon(2, true),
                    label: _getLabel(2),
                  ),
                  BottomNavigationBarItem(
                    icon: _getIcon(3, false),
                    activeIcon: _getIcon(3, true),
                    label: _getLabel(3),
                  ),
                ]
              : [
            BottomNavigationBarItem(
                    icon: _getIcon(0, false),
                    activeIcon: _getIcon(0, true),
                    label: _getLabel(0),
            ),
            BottomNavigationBarItem(
                    icon: _getIcon(1, false),
                    activeIcon: _getIcon(1, true),
                    label: _getLabel(1),
            ),
            BottomNavigationBarItem(
                    icon: _getIcon(2, false),
                    activeIcon: _getIcon(2, true),
                    label: _getLabel(2),
            ),
            BottomNavigationBarItem(
                    icon: _getIcon(3, false),
                    activeIcon: _getIcon(3, true),
                    label: _getLabel(3),
            ),
          ],
        ),
      ),
    );
  }
}
