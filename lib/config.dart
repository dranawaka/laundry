class Config {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ld-app-production.up.railway.app', // Updated to production backend
  );

  // Alternative URLs for different environments
  static const String localhostUrl = 'http://localhost:8080';
  static const String androidEmulatorUrl = 'http://10.0.2.2:8080';
  static const String iosSimulatorUrl = 'http://127.0.0.1:8080';
  static const String physicalDeviceUrl = 'http://192.168.1.100:8080'; // Update with your machine's IP

  // Environment-specific configurations
  static const bool isDevelopment = bool.fromEnvironment(
    'IS_DEVELOPMENT',
    defaultValue: true,
  );

  static const bool isProduction = bool.fromEnvironment(
    'IS_PRODUCTION',
    defaultValue: false,
  );

  // API Endpoints - Spring Boot backend
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register'; // Matches your endpoint
  static const String logoutEndpoint = '/auth/logout';
  static const String userProfileEndpoint = '/api/user/profile';
  static const String updateProfileEndpoint = '/api/user/update';
  static const String changePasswordEndpoint = '/api/user/change-password';
  
  // Spring Boot specific endpoints (if using different naming conventions)
  static const String springLoginEndpoint = '/api/auth/signin';
  static const String springRegisterEndpoint = '/api/auth/signup';
  static const String springUserEndpoint = '/api/users/me';
  
  // Timeout configurations
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Get the full URL for an endpoint
  static String getApiUrl(String endpoint) {
    return '$apiBaseUrl$endpoint';
  }

  // Get appropriate API URL based on platform
  static String getApiBaseUrl() {
    // If API_BASE_URL is provided via environment, use it
    if (const String.fromEnvironment('API_BASE_URL') != '') {
      return const String.fromEnvironment('API_BASE_URL');
    }
    
    // Otherwise use the default (Android emulator)
    return apiBaseUrl;
  }

  // Print configuration for debugging
  static void printConfig() {
    print('API Base URL: $apiBaseUrl');
    print('Is Development: $isDevelopment');
    print('Is Production: $isProduction');
    print('Full Login URL: ${getApiUrl(loginEndpoint)}');
  }
} 