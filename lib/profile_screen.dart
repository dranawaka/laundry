import 'package:flutter/material.dart';
import 'api_service.dart';
import 'notification_test_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fcm_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 3;
  String userName = '';
  String userEmail = '';
  String? userPhone;
  String? userRole;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? '';
      userEmail = prefs.getString('user_email') ?? '';
      userPhone = prefs.getString('user_phone');
      userRole = prefs.getString('user_role');
      isLoading = false;
    });
    print('Loaded userName: '
        '[32m$userName[0m, userEmail: [32m$userEmail[0m, userPhone: $userPhone, userRole: $userRole, isLoading: $isLoading');
  }

  Future<void> _logout() async {
    try {
      print('🚪 === LOGOUT PROCESS STARTED ===');
      
      // Get current user role for FCM cleanup
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('user_role');
      print('Current user role: $userRole');
      
      // Unsubscribe from role-specific FCM topics
      if (userRole != null) {
        print('🎯 Unsubscribing from FCM topics for role: $userRole');
        await FCMService().unsubscribeFromRoleTopics(userRole);
      }
      
      // Clear FCM token
      print('🧹 Clearing FCM token...');
      await FCMService().clearFCMToken();
      
      // Perform logout API call
      print('🔐 Calling logout API...');
      await ApiService.logout();
      
      print('✅ Logout completed successfully');
      print('=== LOGOUT PROCESS ENDED ===');
      
      // Navigate to login screen
      Navigator.of(context).pushReplacementNamed('/login');
      
    } catch (e) {
      print('❌ Error during logout: $e');
      // Still navigate to login even if cleanup fails
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building ProfileScreen, isLoading: $isLoading, userName: $userName, userEmail: $userEmail');
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      const Text(
                        'Profile',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),
                      // Avatar and user info
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, size: 40, color: Colors.grey),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName.isNotEmpty ? userName : 'User',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userEmail.isNotEmpty ? userEmail : '-',
                                style: const TextStyle(color: Colors.grey, fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Menu tiles
                      _buildMenuTile(Icons.person_outline, 'My profile', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MyProfileScreen()),
                        );
                      }),
                      _buildMenuTile(Icons.favorite_border, 'Favourites', () {}),
                      _buildMenuTile(Icons.privacy_tip_outlined, 'Privacy policy', () {}),
                      _buildMenuTile(Icons.info_outline, 'About us', () {}),
                      _buildMenuTile(Icons.settings_outlined, 'Settings', () {}),
                      _buildMenuTile(Icons.logout, 'Sign out', () {
                        _logout();
                      }, isDestructive: true),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: isDestructive ? Colors.red : Colors.black, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isDestructive ? Colors.red : Colors.black,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({Key? key}) : super(key: key);

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  String userName = '';
  String userEmail = '';
  String userPhone = '';
  String userAddress = '';
  String userCity = '';
  String userState = '';
  String userZip = '';
  String userCountry = '';
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Get userId from SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final userIdString = prefs.getString('user_id');
      if (userIdString == null) throw Exception('No userId in SharedPreferences');
      // Fetch full profile from backend
      final userData = await ApiService.getUserProfileFromBackend(userIdString);
      if (userData != null) {
        setState(() {
          userName = userData['name'] ?? '';
          userEmail = userData['email'] ?? '';
          userPhone = userData['phone'] ?? '';
          userAddress = userData['address'] ?? '';
          userCity = userData['city'] ?? '';
          userState = userData['state'] ?? '';
          userZip = userData['zipCode'] ?? '';
          userCountry = userData['country'] ?? '';
          userId = int.tryParse(userData['id']?.toString() ?? '');
        });
        print('Loaded user data from backend - Name: $userName, Email: $userEmail, Phone: $userPhone, Address: $userAddress, City: $userCity, State: $userState, Zip: $userZip, Country: $userCountry, UserId: $userId');
        return;
      }
    } catch (e) {
      print('Error loading user data from backend: $e');
    }
    // Fallback to SharedPreferences if backend fails
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? '';
      userEmail = prefs.getString('user_email') ?? '';
      userPhone = prefs.getString('user_phone') ?? '';
      userAddress = prefs.getString('user_address') ?? '';
      userCity = prefs.getString('user_city') ?? '';
      userState = prefs.getString('user_state') ?? '';
      userZip = prefs.getString('user_zip') ?? '';
      userCountry = prefs.getString('user_country') ?? '';
      final userIdString = prefs.getString('user_id');
      userId = int.tryParse(userIdString ?? '');
    });
    print('Loaded user data from SharedPreferences (backend failed)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, size: 60, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.edit),
                label: Text('Edit Profile'),
                onPressed: () async {
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User ID not found. Please log in again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(
                        initialProfile: {
                          "name": userName,
                          "email": userEmail,
                          "phone": userPhone,
                          "address": userAddress,
                          "city": userCity,
                          "state": userState,
                          "zipCode": userZip,
                          "country": userCountry,
                        },
                        userId: userId!,
                      ),
                    ),
                  );
                  if (updated == true) {
                    await _loadUserData();
                  }
                },
              ),
              const SizedBox(height: 32),
              _infoTile('Name', userName.isNotEmpty ? userName : '-'),
              const SizedBox(height: 16),
              _infoTile('Email address', userEmail.isNotEmpty ? userEmail : '-'),
              const SizedBox(height: 16),
              _infoTile('Phone number', userPhone.isNotEmpty ? userPhone : '-'),
              const SizedBox(height: 16),
              _infoTile('Address', userAddress.isNotEmpty ? userAddress : '-'),
              const SizedBox(height: 16),
              _infoTile('City', userCity.isNotEmpty ? userCity : '-'),
              const SizedBox(height: 16),
              _infoTile('State', userState.isNotEmpty ? userState : '-'),
              const SizedBox(height: 16),
              _infoTile('Zip Code', userZip.isNotEmpty ? userZip : '-'),
              const SizedBox(height: 16),
              _infoTile('Country', userCountry.isNotEmpty ? userCountry : '-'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
