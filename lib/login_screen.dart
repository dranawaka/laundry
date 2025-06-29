import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'api_service.dart';
import 'config.dart';
import 'fcm_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _currentTabIndex = 0; // Index for tracking Login or Register tabs
  final PageController _pageController = PageController();

  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>(); // Key for login form validation
  final GlobalKey<FormState> _signupFormKey = GlobalKey<FormState>(); // Key for signup form validation

  // Controllers for login form fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Controllers for signup form fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false; // Visibility for password in login
  bool _isSignupPasswordVisible = false; // Visibility for signup password
  bool _isConfirmPasswordVisible = false; // Visibility for confirm password
  bool _isLoading = false;

  // Add role selection
  String _selectedRole = 'CUSTOMER';
  final List<String> _roles = ['CUSTOMER', 'LAUNDRY']; // Backend values
  final Map<String, String> _roleLabels = {
    'CUSTOMER': 'Customer',
    'LAUNDRY': 'Laundry Owner',
  };

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_loginFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final result = await ApiService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
        );

        setState(() => _isLoading = false);

        if (result['success']) {
          // Update FCM token for existing user after successful login
          await _updateFCMTokenAfterLogin(result['data']['id']);
          
          Fluttertoast.showToast(
            msg: "Login successful as $_selectedRole!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: const Color(0xFF424242), // Dark gray
            textColor: Colors.white,
          );
          
          // Navigate to home screen
          Navigator.pushReplacementNamed(context, '/home');
          
          // For customers, redirect to favorites screen after a short delay
          if (_selectedRole.toUpperCase() == 'CUSTOMER') {
            Future.delayed(Duration(milliseconds: 500), () {
              // This will be handled by the main screen which shows favorites first for customers
            });
          }
        } else {
          Fluttertoast.showToast(
            msg: result['message'],
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: "An error occurred: ${e.toString()}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  // Register FCM token with backend
  Future<void> _registerFCMToken(String userId) async {
    try {
      final result = await FCMService().registerTokenWithBackend(userId);
      if (result['success']) {
        print('FCM token registered successfully');
      } else {
        print('Failed to register FCM token: ${result['message']}');
      }
    } catch (e) {
      print('Error registering FCM token: $e');
    }
  }

  // Update FCM token for existing user after login
  Future<void> _updateFCMTokenAfterLogin(String userId) async {
    try {
      print('=== FCM TOKEN UPDATE AFTER LOGIN ===');
      print('User ID: $userId');
      print('User Role: $_selectedRole');
      
      // Role-specific logging
      if (_selectedRole.toUpperCase() == 'LAUNDRY') {
        print('🏪 Laundry Owner Login - FCM Token Update');
        print('Laundry owners need FCM tokens for:');
        print('- New order notifications');
        print('- Order status updates');
        print('- Customer inquiries');
      } else if (_selectedRole.toUpperCase() == 'CUSTOMER') {
        print('👤 Customer Login - FCM Token Update');
        print('Customers need FCM tokens for:');
        print('- Order status updates');
        print('- Service notifications');
        print('- Promotional messages');
      }
      
      // Use the comprehensive FCM service method
      final result = await FCMService().comprehensiveTokenUpdate(userId);
      
      if (result['success']) {
        print('✅ FCM token updated successfully after login');
        print('Response: ${result['message']}');
        print('Step: ${result['step']}');
        
        // Role-specific success messages
        if (_selectedRole.toUpperCase() == 'LAUNDRY') {
          print('🏪 Laundry owner FCM token registered successfully');
          print('Ready to receive new order notifications');
        } else if (_selectedRole.toUpperCase() == 'CUSTOMER') {
          print('👤 Customer FCM token registered successfully');
          print('Ready to receive order updates and notifications');
        }
        
        // Log token status for debugging
        final tokenStatus = FCMService().getTokenStatus();
        print('Token Status: $tokenStatus');
        
        // Subscribe to role-specific topics
        await _subscribeToRoleTopics();
        
      } else {
        print('❌ Failed to update FCM token after login');
        print('Error: ${result['message']}');
        print('Step: ${result['step']}');
        
        // Role-specific error handling
        if (_selectedRole.toUpperCase() == 'LAUNDRY') {
          print('🏪 Laundry owner FCM token update failed');
          print('This may affect new order notifications');
        } else if (_selectedRole.toUpperCase() == 'CUSTOMER') {
          print('👤 Customer FCM token update failed');
          print('This may affect order status notifications');
        }
        
        // Log detailed debug information
        if (result['loginStatus'] != null) {
          print('Login Status: ${result['loginStatus']}');
        }
        if (result['tokenStatus'] != null) {
          print('Token Status: ${result['tokenStatus']}');
        }
        if (result['apiTest'] != null) {
          print('API Test: ${result['apiTest']}');
        }
        if (result['updateResult'] != null) {
          print('Update Result: ${result['updateResult']}');
        }
        if (result['regResult'] != null) {
          print('Registration Result: ${result['regResult']}');
        }
        
        // Try alternative method - force refresh token
        print('Trying alternative method - force refresh token...');
        final refreshResult = await FCMService().forceRefreshToken();
        if (refreshResult != null) {
          print('✅ Token refreshed successfully, retrying update...');
          final retryResult = await FCMService().comprehensiveTokenUpdate(userId);
          if (retryResult['success']) {
            print('✅ FCM token update successful after retry');
            // Subscribe to role-specific topics after successful retry
            await _subscribeToRoleTopics();
          } else {
            print('❌ FCM token update still failed after retry: ${retryResult['message']}');
          }
        } else {
          print('❌ Failed to refresh FCM token');
        }
      }
      
      print('=== END FCM TOKEN UPDATE ===');
      
    } catch (e) {
      print('❌ Error updating FCM token after login: $e');
      print('Error type: ${e.runtimeType}');
      
      // Don't show error to user as this is not critical for login
      // Just log it for debugging purposes
    }
  }

  // Subscribe to role-specific FCM topics
  Future<void> _subscribeToRoleTopics() async {
    try {
      print('🎯 Using FCM service to subscribe to role-specific topics...');
      await FCMService().subscribeToRoleTopics(_selectedRole);
    } catch (e) {
      print('⚠️ Error subscribing to role topics: $e');
      // Don't fail the login process for topic subscription errors
    }
  }

  // Update FCM token for new user after registration
  Future<void> _updateFCMTokenAfterRegistration(String userId) async {
    try {
      print('=== FCM TOKEN UPDATE AFTER REGISTRATION ===');
      print('User ID: $userId');
      print('User Role: $_selectedRole');
      
      // Role-specific logging
      if (_selectedRole.toUpperCase() == 'LAUNDRY') {
        print('🏪 Laundry Owner Registration - FCM Token Update');
        print('Setting up FCM for new laundry owner account');
      } else if (_selectedRole.toUpperCase() == 'CUSTOMER') {
        print('👤 Customer Registration - FCM Token Update');
        print('Setting up FCM for new customer account');
      }
      
      // Use the comprehensive FCM service method
      final result = await FCMService().comprehensiveTokenUpdate(userId);
      
      if (result['success']) {
        print('✅ FCM token updated successfully after registration');
        print('Response: ${result['message']}');
        print('Step: ${result['step']}');
        
        // Role-specific success messages
        if (_selectedRole.toUpperCase() == 'LAUNDRY') {
          print('🏪 New laundry owner FCM token registered successfully');
          print('Ready to receive new order notifications');
        } else if (_selectedRole.toUpperCase() == 'CUSTOMER') {
          print('👤 New customer FCM token registered successfully');
          print('Ready to receive order updates and notifications');
        }
        
        // Log token status for debugging
        final tokenStatus = FCMService().getTokenStatus();
        print('Token Status: $tokenStatus');
        
        // Subscribe to role-specific topics
        await _subscribeToRoleTopics();
        
      } else {
        print('❌ Failed to update FCM token after registration');
        print('Error: ${result['message']}');
        print('Step: ${result['step']}');
        
        // Role-specific error handling
        if (_selectedRole.toUpperCase() == 'LAUNDRY') {
          print('🏪 New laundry owner FCM token update failed');
          print('This may affect new order notifications');
        } else if (_selectedRole.toUpperCase() == 'CUSTOMER') {
          print('👤 New customer FCM token update failed');
          print('This may affect order status notifications');
        }
        
        // Log detailed debug information
        if (result['loginStatus'] != null) {
          print('Login Status: ${result['loginStatus']}');
        }
        if (result['tokenStatus'] != null) {
          print('Token Status: ${result['tokenStatus']}');
        }
        if (result['apiTest'] != null) {
          print('API Test: ${result['apiTest']}');
        }
        if (result['updateResult'] != null) {
          print('Update Result: ${result['updateResult']}');
        }
        if (result['regResult'] != null) {
          print('Registration Result: ${result['regResult']}');
        }
        
        // Try alternative method - force refresh token
        print('Trying alternative method - force refresh token...');
        final refreshResult = await FCMService().forceRefreshToken();
        if (refreshResult != null) {
          print('✅ Token refreshed successfully, retrying update...');
          final retryResult = await FCMService().comprehensiveTokenUpdate(userId);
          if (retryResult['success']) {
            print('✅ FCM token update successful after retry');
            // Subscribe to role-specific topics after successful retry
            await _subscribeToRoleTopics();
          } else {
            print('❌ FCM token update still failed after retry: ${retryResult['message']}');
          }
        } else {
          print('❌ Failed to refresh FCM token');
        }
      }
      
      print('=== END FCM TOKEN UPDATE ===');
      
    } catch (e) {
      print('❌ Error updating FCM token after registration: $e');
      print('Error type: ${e.runtimeType}');
      
      // Don't show error to user as this is not critical for registration
      // Just log it for debugging purposes
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set the system UI overlay style (status bar color and icon brightness)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // PageView for illustrations
              Expanded(
                flex: 3,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentTabIndex = index;
                    });
                  },
                  children: [
                    _buildIllustration(0),
                    _buildIllustration(1),
                  ],
                ),
              ),

              // "Looking for Laundry Services?" text displayed on the login tab
              if (_currentTabIndex == 0)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    "Looking for Laundry Services?",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444444),
                    ),
                  ),
                ),

              // Login/Register form
              Expanded(
                flex: _currentTabIndex == 0 ? 7 : 9, // Adjust space based on active tab
                child: Card(
                  elevation: 1,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tab buttons for switching between Login and Sign Up
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTabButton('Login', _currentTabIndex == 0, () {
                                  setState(() {
                                    _currentTabIndex = 0;
                                    _pageController.animateToPage(
                                      0,
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  });
                                }),
                              ),
                              Expanded(
                                child: _buildTabButton('Sign up', _currentTabIndex == 1, () {
                                  setState(() {
                                    _currentTabIndex = 1;
                                    _pageController.animateToPage(
                                      1,
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  });
                                }),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Role selector
                        ToggleButtons(
                          isSelected: _roles.map((role) => _selectedRole == role).toList(),
                          onPressed: (index) {
                            setState(() {
                              _selectedRole = _roles[index];
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          selectedColor: Colors.white,
                          fillColor: Color(0xFF424242),
                          color: Color(0xFF424242),
                          children: _roles.map((role) => Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Text(_roleLabels[role] ?? role, style: TextStyle(fontWeight: FontWeight.w600)),
                          )).toList(),
                        ),

                        // Form to display based on the active tab
                        Expanded(
                          child: _currentTabIndex == 0
                              ? _buildLoginForm()
                              : _buildSignupForm(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 1,
              offset: Offset(0, 1),
            ),
          ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isActive ? const Color(0xFF444444) : Colors.grey[600],
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  // Method for form fields with validation
  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isConfirmPassword = false,
    IconData? prefixIcon,
  }) {
    bool isVisible = isPassword ?
    (isConfirmPassword ? _isConfirmPasswordVisible :
    (_currentTabIndex == 0 ? _isPasswordVisible : _isSignupPasswordVisible)) : false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF424242), size: 20) : null,
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              isVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[400],
              size: 20,
            ),
            onPressed: () {
              setState(() {
                if (isConfirmPassword) {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                } else if (_currentTabIndex == 0) {
                  _isPasswordVisible = !_isPasswordVisible;
                } else {
                  _isSignupPasswordVisible = !_isSignupPasswordVisible;
                }
              });
            },
          )
              : null,
        ),
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormField(
            label: 'Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),

          _buildFormField(
            label: 'Password',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: Icons.lock_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Fluttertoast.showToast(
                  msg: "Password reset link will be sent to your email",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: const Color(0xFF424242), // Dark gray
                  textColor: Colors.white,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF424242), // Dark gray
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size.zero,
              ),
              child: Text(
                'Forgotten your password?',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF424242), // Dark gray
                ),
              ),
            ),
          ),

          const Spacer(),

          // Login button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE0E0E0),
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text(
                'Login',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormField(
              label: 'Username',
              controller: _usernameController,
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a username';
                }
                if (value.length < 3) {
                  return 'Username must be at least 3 characters';
                }
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                  return 'Username can only contain letters, numbers, and underscores';
                }
                return null;
              },
            ),

            _buildFormField(
              label: 'Phone Number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                // Basic phone validation - adjust regex based on your requirements
                if (!RegExp(r'^\+?[\d\s\-\(\)]{10,}$').hasMatch(value)) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),

            _buildFormField(
              label: 'Email',
              controller: _signupEmailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),

            _buildFormField(
              label: 'Password',
              controller: _signupPasswordController,
              isPassword: true,
              prefixIcon: Icons.lock_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                // Add more password validation if needed
                if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                  return 'Password must contain uppercase, lowercase, and number';
                }
                return null;
              },
            ),

            _buildFormField(
              label: 'Re-enter Password',
              controller: _confirmPasswordController,
              isPassword: true,
              isConfirmPassword: true,
              prefixIcon: Icons.lock_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _signupPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            const SizedBox(height: 1),

            // Sign up button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (_signupFormKey.currentState!.validate()) {
                    setState(() => _isLoading = true);
                    
                    try {
                      // Get FCM token for registration using enhanced method
                      final fcmToken = await FCMService().getCurrentToken(forceRefresh: true);
                      print('FCM Token for registration: ${fcmToken != null ? '${fcmToken.substring(0, 20)}...' : 'null'}');
                      
                      final result = await ApiService.register(
                        username: _usernameController.text.trim(),
                        email: _signupEmailController.text.trim(),
                        password: _signupPasswordController.text,
                        phone: _phoneController.text.trim(),
                        role: _selectedRole,
                        fcmToken: fcmToken, // Pass FCM token to registration
                      );

                      setState(() => _isLoading = false);

                      if (result['success']) {
                        // Update FCM token after successful registration
                        if (result['data'] != null && result['data']['id'] != null) {
                          await _updateFCMTokenAfterRegistration(result['data']['id']);
                        }
                        
                        Fluttertoast.showToast(
                          msg: "Registration successful! Welcome ${_usernameController.text.trim()}!",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: const Color(0xFF424242), // Dark gray
                          textColor: Colors.white,
                        );

                        // Clear form fields
                        _usernameController.clear();
                        _phoneController.clear();
                        _signupEmailController.clear();
                        _signupPasswordController.clear();
                        _confirmPasswordController.clear();

                        // Navigate directly to home screen since user is now logged in
                        Navigator.pushReplacementNamed(context, '/home');
                        
                        // For customers, ensure favorites are initialized
                        if (_selectedRole.toUpperCase() == 'CUSTOMER') {
                          Future.delayed(Duration(milliseconds: 500), () {
                            // This will be handled by the main screen which shows favorites first for customers
                          });
                        }
                      } else {
                        Fluttertoast.showToast(
                          msg: result['message'],
                          toastLength: Toast.LENGTH_LONG,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                        );
                      }
                    } catch (e) {
                      setState(() => _isLoading = false);
                      Fluttertoast.showToast(
                        msg: "An error occurred: ${e.toString()}",
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE0E0E0),
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text(
                  'Sign up',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(int index) {
    switch (index) {
      case 0:
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 30,
              left: 50,
              right: 50,
              child: Container(height: 1, color: const Color(0xFF424242)),
            ),
            Positioned(
              left: MediaQuery.of(context).size.width * 0.3,
              child: Container(
                width: 70,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFF424242), width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
                      color: const Color(0xFF424242).withOpacity(0.3),
                    ),
                    Container(
                      height: 5,
                      margin: const EdgeInsets.only(top: 5, left: 10, right: 30),
                      color: const Color(0xFF424242).withOpacity(0.3),
                    ),
                    Container(
                      height: 5,
                      margin: const EdgeInsets.only(top: 5, left: 10, right: 20),
                      color: const Color(0xFF424242).withOpacity(0.3),
                    ),
                    Container(
                      height: 5,
                      margin: const EdgeInsets.only(top: 5, left: 10, right: 15),
                      color: const Color(0xFF424242).withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: MediaQuery.of(context).size.width * 0.3,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5).withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF424242), width: 1),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF424242),
                  size: 28,
                ),
              ),
            ),
          ],
        );

      case 1:
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5).withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFF424242), width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      height: 8,
                      margin: const EdgeInsets.only(top: 8, left: 8, right: 8),
                      color: const Color(0xFF424242).withOpacity(0.3),
                    ),
                    Container(
                      height: 4,
                      margin: const EdgeInsets.only(top: 4, left: 8, right: 20),
                      color: const Color(0xFF424242).withOpacity(0.3),
                    ),
                    Container(
                      height: 4,
                      margin: const EdgeInsets.only(top: 4, left: 8, right: 15),
                      color: const Color(0xFF424242).withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 60,
                right: 100,
                child: Icon(
                  Icons.add,
                  color: const Color(0xFF424242),
                  size: 18,
                ),
              ),
              Positioned(
                bottom: 60,
                left: 105,
                child: Icon(
                  Icons.add,
                  color: const Color(0xFF424242),
                  size: 18,
                ),
              ),
            ],
          ),
        );

      default:
        return Container();
    }
  }
}
