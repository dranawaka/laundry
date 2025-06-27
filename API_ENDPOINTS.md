# Spring Boot API Endpoints for Laundry App

This document outlines the expected API endpoints that your Spring Boot backend should implement to work with the Flutter laundry app.

## Base URL
- Development: `http://localhost:8080/api`
- Production: `https://your-domain.com/api`

## Authentication Endpoints

### 1. Login
**POST** `/api/auth/login`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (Success - 200):**
```json
{
  "id": 1,
  "name": "Dilan Ranawaka",
  "email": "dilan@ld.com",
  "phone": "+1234567890",
  "password": "securepassword",
  "role": "CUSTOMER"
}
```

**Response (Error - 401/400):**
```json
{
  "success": false,
  "message": "Invalid credentials"
}
```

### 2. Register
**POST** `/api/auth/register`

**Request Body:**
```json
{
  "username": "john_doe",
  "email": "user@example.com",
  "password": "password123",
  "phone": "+1234567890",
  "role": "customer"
}
```

**Response (Success - 201):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "username": "john_doe",
    "role": "customer",
    "phone": "+1234567890"
  }
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "message": "Email already exists"
}
```

### 3. Logout
**POST** `/api/auth/logout`

**Headers:**
```
Authorization: Bearer <token>
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Logout successful"
}
```

### 4. Refresh Token
**POST** `/api/auth/refresh`

**Request Body:**
```json
{
  "refreshToken": "refresh_token_here"
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Token refreshed successfully",
  "token": "new_jwt_token_here",
  "refreshToken": "new_refresh_token_here"
}
```

## Spring Boot Implementation Example

Here's a basic example of how your Spring Boot controller might look:

```java
@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @Autowired
    private AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest loginRequest) {
        try {
            User user = authService.login(loginRequest);
            return ResponseEntity.ok(user);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ErrorResponse("Login failed: " + e.getMessage()));
        }
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest registerRequest) {
        try {
            User user = authService.register(registerRequest);
            return ResponseEntity.status(HttpStatus.CREATED).body(user);
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                .body(new ErrorResponse("Registration failed: " + e.getMessage()));
        }
    }
}
```

## DTO Classes

```java
public class LoginRequest {
    private String email;
    private String password;
    // getters and setters
}

public class RegisterRequest {
    private String username;
    private String email;
    private String password;
    private String phone;
    private String role;
    // getters and setters
}

public class User {
    private Long id;
    private String name;
    private String email;
    private String phone;
    private String password;
    private String role;
    // getters and setters
}

public class ErrorResponse {
    private boolean success = false;
    private String message;
    // getters and setters
}
```

## Security Configuration

Make sure to configure CORS in your Spring Boot application:

```java
@Configuration
public class CorsConfig implements WebMvcConfigurer {
    
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
            .allowedOrigins("*")
            .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
            .allowedHeaders("*")
            .allowCredentials(false);
    }
}
```

## Testing the API

You can test your API endpoints using tools like:
- Postman
- cURL
- Insomnia

Example cURL command for login:
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

## Environment Configuration

Update the `Config.dart` file in your Flutter app to match your Spring Boot server URL:

- For Android Emulator: `http://10.0.2.2:8080/api`
- For iOS Simulator: `http://localhost:8080/api`
- For Physical Device: `http://your-server-ip:8080/api` 