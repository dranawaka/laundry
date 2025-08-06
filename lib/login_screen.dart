import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'api_service.dart';
import 'config.dart';
import 'fcm_service.dart';
import 'registration_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _selectedRole = 'CUSTOMER';
  final List<String> _roles = ['CUSTOMER', 'LAUNDRY'];

  Future<void> _updateFCMToken(String userId) async {
    try {
      print('=== FCM TOKEN UPDATE AFTER LOGIN ===');
      print('User ID: $userId');
      final fcmService = FCMService();
      await fcmService.registerTokenWithBackend(userId);
      print('✅ FCM token updated successfully after login');
    } catch (e) {
      print('❌ Failed to update FCM token after login: $e');
    }
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    print('Login button pressed');
    setState(() => _isLoading = true);
    try {
      print('Calling ApiService.login...');
      
      // Use the selected role directly since we're now using the correct API role names
      String apiRole = _selectedRole;
      
      final result = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: apiRole,
      );
      print('API call result: $result');
      setState(() => _isLoading = false);
      
      if (result['success']) {
        // Update FCM token for the logged-in user
        final userId = result['data']['id'];
        if (userId != null) {
          await _updateFCMToken(userId.toString());
        }
        
        Fluttertoast.showToast(
          msg: "Login successful!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        
        // Navigate to dashboard
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? 'Login failed',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Login error: $e');
      Fluttertoast.showToast(
        msg: "An error occurred: \n${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sign in',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Log in to start your laundry journey with us.',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            
                            // Trim whitespace
                            value = value.trim();
                            
                            // Check for basic email format
                            if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            
                            // Check for minimum length
                            if (value.length < 5) {
                              return 'Email address is too short';
                            }
                            
                            // Check for maximum length
                            if (value.length > 254) {
                              return 'Email address is too long';
                            }
                            
                            // Check for valid domain
                            final parts = value.split('@');
                            if (parts.length != 2) {
                              return 'Invalid email format';
                            }
                            
                            final domain = parts[1];
                            if (domain.length < 3 || !domain.contains('.')) {
                              return 'Invalid domain in email address';
                            }
                            
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
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
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          items: [
                            DropdownMenuItem(
                              value: 'CUSTOMER',
                              child: Text('Customer'),
                            ),
                            DropdownMenuItem(
                              value: 'LAUNDRY',
                              child: Text('Laundry Owner'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedRole = value);
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.zero,
                              minimumSize: Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Forget password?',
                              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF001A36),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Sign in'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: const [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('Or', style: TextStyle(color: Colors.black54)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/4/4a/Logo_2013_Google.png',
                        width: 24,
                        height: 24,
                      ),
                      label: const Text('Google', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F5F5),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.apple, color: Colors.black, size: 24),
                      label: const Text('Apple', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F5F5),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ", style: TextStyle(color: Colors.black)),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            color: Color(0xFF001A36),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
