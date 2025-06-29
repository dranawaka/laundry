// Notification Helper - Example payloads for testing FCM
// This file contains example notification payloads that can be used to test FCM functionality

class NotificationHelper {
  // Example notification payloads for different scenarios
  
  // Order Update Notification (for CUSTOMERS)
  static Map<String, dynamic> getOrderUpdatePayload({
    required String fcmToken,
    required String orderId,
    required String status,
  }) {
    return {
      "message": {
        "token": fcmToken,
        "notification": {
          "title": "Order Update",
          "body": "Your order #$orderId has been $status",
        },
        "data": {
          "type": "order_update",
          "orderId": orderId,
          "status": status,
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
        },
        "android": {
          "notification": {
            "channel_id": "laundry_app_channel",
            "priority": "high",
            "default_sound": true,
            "default_vibrate_timings": true,
          }
        },
        "apns": {
          "payload": {
            "aps": {
              "sound": "default",
              "badge": 1,
            }
          }
        }
      }
    };
  }

  // New Order Notification (for LAUNDRY OWNERS)
  static Map<String, dynamic> getNewOrderPayload({
    required String fcmToken,
    required String orderId,
    required String customerName,
  }) {
    return {
      "message": {
        "token": fcmToken,
        "notification": {
          "title": "New Order Received",
          "body": "New order #$orderId from $customerName",
        },
        "data": {
          "type": "new_order",
          "orderId": orderId,
          "customerName": customerName,
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
        },
        "android": {
          "notification": {
            "channel_id": "laundry_app_channel",
            "priority": "high",
            "default_sound": true,
            "default_vibrate_timings": true,
          }
        },
        "apns": {
          "payload": {
            "aps": {
              "sound": "default",
              "badge": 1,
            }
          }
        }
      }
    };
  }

  // Order Status Update Notification (for CUSTOMERS)
  static Map<String, dynamic> getOrderStatusUpdatePayload({
    required String fcmToken,
    required String orderId,
    required String status,
    required String laundryName,
  }) {
    return {
      "message": {
        "token": fcmToken,
        "notification": {
          "title": "Order Status Updated",
          "body": "Your order #$orderId is now $status by $laundryName",
        },
        "data": {
          "type": "order_status_update",
          "orderId": orderId,
          "status": status,
          "laundryName": laundryName,
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
        },
        "android": {
          "notification": {
            "channel_id": "laundry_app_channel",
            "priority": "high",
            "default_sound": true,
            "default_vibrate_timings": true,
          }
        },
        "apns": {
          "payload": {
            "aps": {
              "sound": "default",
              "badge": 1,
            }
          }
        }
      }
    };
  }

  // Order Cancellation Notification (for CUSTOMERS)
  static Map<String, dynamic> getOrderCancellationPayload({
    required String fcmToken,
    required String orderId,
    required String reason,
  }) {
    return {
      "message": {
        "token": fcmToken,
        "notification": {
          "title": "Order Cancelled",
          "body": "Your order #$orderId has been cancelled. Reason: $reason",
        },
        "data": {
          "type": "order_cancelled",
          "orderId": orderId,
          "reason": reason,
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
        },
        "android": {
          "notification": {
            "channel_id": "laundry_app_channel",
            "priority": "high",
            "default_sound": true,
            "default_vibrate_timings": true,
          }
        },
        "apns": {
          "payload": {
            "aps": {
              "sound": "default",
              "badge": 1,
            }
          }
        }
      }
    };
  }

  // Promotion Notification
  static Map<String, dynamic> getPromotionPayload({
    required String fcmToken,
    required String promotionId,
    required String title,
    required String description,
  }) {
    return {
      "message": {
        "token": fcmToken,
        "notification": {
          "title": title,
          "body": description,
        },
        "data": {
          "type": "promotion",
          "promotionId": promotionId,
          "title": title,
          "description": description,
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
        },
        "android": {
          "notification": {
            "channel_id": "laundry_app_channel",
            "priority": "normal",
            "default_sound": true,
            "default_vibrate_timings": false,
          }
        },
        "apns": {
          "payload": {
            "aps": {
              "sound": "default",
              "badge": 1,
            }
          }
        }
      }
    };
  }

  // Topic-based notification (for broadcasting to multiple users)
  static Map<String, dynamic> getTopicNotificationPayload({
    required String topic,
    required String title,
    required String body,
    Map<String, String>? data,
  }) {
    return {
      "message": {
        "topic": topic,
        "notification": {
          "title": title,
          "body": body,
        },
        "data": data ?? {},
        "android": {
          "notification": {
            "channel_id": "laundry_app_channel",
            "priority": "normal",
            "default_sound": true,
            "default_vibrate_timings": false,
          }
        },
        "apns": {
          "payload": {
            "aps": {
              "sound": "default",
              "badge": 1,
            }
          }
        }
      }
    };
  }

  // Test notification payload
  static Map<String, dynamic> getTestNotificationPayload({
    required String fcmToken,
  }) {
    return {
      "message": {
        "token": fcmToken,
        "notification": {
          "title": "Test Notification",
          "body": "This is a test notification from your laundry app!",
        },
        "data": {
          "type": "test",
          "timestamp": DateTime.now().toIso8601String(),
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
        },
        "android": {
          "notification": {
            "channel_id": "laundry_app_channel",
            "priority": "normal",
            "default_sound": true,
            "default_vibrate_timings": true,
          }
        },
        "apns": {
          "payload": {
            "aps": {
              "sound": "default",
              "badge": 1,
            }
          }
        }
      }
    };
  }

  // Common topics for the laundry app
  static const String TOPIC_ORDER_UPDATES = "order_updates";
  static const String TOPIC_PROMOTIONS = "promotions";
  static const String TOPIC_LAUNDRY_OWNERS = "laundry_owners";
  static const String TOPIC_CUSTOMERS = "customers";
  static const String TOPIC_TEST = "test_topic";

  // Helper method to get topic name for specific user type
  static String getUserTopic(String userRole) {
    switch (userRole.toUpperCase()) {
      case 'LAUNDRY':
        return TOPIC_LAUNDRY_OWNERS;
      case 'CUSTOMER':
        return TOPIC_CUSTOMERS;
      default:
        return TOPIC_CUSTOMERS;
    }
  }

  // Helper method to get order topic for specific order
  static String getOrderTopic(String orderId) {
    return "order_$orderId";
  }

  // Helper method to get laundry topic for specific laundry
  static String getLaundryTopic(String laundryId) {
    return "laundry_$laundryId";
  }
}

// Example usage in your Spring Boot backend:
/*
@RestController
@RequestMapping("/api/notifications")
public class NotificationController {
    
    @PostMapping("/send-order-update")
    public ResponseEntity<?> sendOrderUpdate(@RequestBody OrderUpdateRequest request) {
        try {
            // Get FCM token for the user
            String fcmToken = userService.getFCMToken(request.getUserId());
            
            // Create notification payload
            Map<String, Object> payload = NotificationHelper.getOrderUpdatePayload(
                fcmToken, 
                request.getOrderId(), 
                request.getStatus()
            );
            
            // Send notification using Firebase Admin SDK
            firebaseMessaging.send(payload);
            
            return ResponseEntity.ok().body(Map.of("message", "Notification sent successfully"));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }
    
    @PostMapping("/send-promotion")
    public ResponseEntity<?> sendPromotion(@RequestBody PromotionRequest request) {
        try {
            // Send to topic for all customers
            Map<String, Object> payload = NotificationHelper.getTopicNotificationPayload(
                NotificationHelper.TOPIC_CUSTOMERS,
                request.getTitle(),
                request.getDescription(),
                Map.of("promotionId", request.getPromotionId())
            );
            
            firebaseMessaging.send(payload);
            
            return ResponseEntity.ok().body(Map.of("message", "Promotion sent successfully"));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }
}

// User Registration with FCM Token - Backend Implementation
@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false)
    private String name;
    
    @Column(unique = true, nullable = false)
    private String email;
    
    @Column(nullable = false)
    private String phone;
    
    @Column(nullable = false)
    private String password;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserRole role;
    
    @Column(name = "fcm_token")
    private String fcmToken;
    
    // Getters and setters
    // ... existing code ...
    
    public String getFcmToken() {
        return fcmToken;
    }
    
    public void setFcmToken(String fcmToken) {
        this.fcmToken = fcmToken;
    }
}

// Registration DTO
public class UserRegistrationRequest {
    private String name;
    private String email;
    private String phone;
    private String password;
    private UserRole role;
    private String fcmToken; // New field for FCM token
    
    // Getters and setters
    public String getFcmToken() {
        return fcmToken;
    }
    
    public void setFcmToken(String fcmToken) {
        this.fcmToken = fcmToken;
    }
    
    // ... other getters and setters ...
}

// User Service
@Service
public class UserService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    public User registerUser(UserRegistrationRequest request) {
        // Check if user already exists
        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new RuntimeException("User with this email already exists");
        }
        
        // Create new user
        User user = new User();
        user.setName(request.getName());
        user.setEmail(request.getEmail());
        user.setPhone(request.getPhone());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setRole(request.getRole());
        user.setFcmToken(request.getFcmToken()); // Save FCM token during registration
        
        // Save user
        User savedUser = userRepository.save(user);
        
        // Subscribe user to appropriate topics based on role
        subscribeUserToTopics(savedUser);
        
        return savedUser;
    }
    
    public void updateFCMToken(Long userId, String fcmToken) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Update FCM token
        user.setFcmToken(fcmToken);
        userRepository.save(user);
        
        // Re-subscribe to topics with new token
        subscribeUserToTopics(user);
    }
    
    public void deleteFCMToken(Long userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Unsubscribe from topics before deleting token
        unsubscribeUserFromTopics(user);
        
        // Clear FCM token
        user.setFcmToken(null);
        userRepository.save(user);
    }
    
    public String getFCMToken(Long userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new RuntimeException("User not found"));
        return user.getFcmToken();
    }
    
    private void subscribeUserToTopics(User user) {
        if (user.getFcmToken() == null) return;
        
        try {
            // Subscribe to general topics based on role
            String roleTopic = getUserTopic(user.getRole());
            firebaseMessaging.subscribeToTopic(
                List.of(user.getFcmToken()), 
                roleTopic
            );
            
            // Subscribe to general order updates
            firebaseMessaging.subscribeToTopic(
                List.of(user.getFcmToken()), 
                "order_updates"
            );
            
            System.out.println("User " + user.getEmail() + " subscribed to topics: " + roleTopic + ", order_updates");
        } catch (Exception e) {
            System.err.println("Error subscribing user to topics: " + e.getMessage());
        }
    }
    
    private void unsubscribeUserFromTopics(User user) {
        if (user.getFcmToken() == null) return;
        
        try {
            // Unsubscribe from all topics
            String roleTopic = getUserTopic(user.getRole());
            firebaseMessaging.unsubscribeFromTopic(
                List.of(user.getFcmToken()), 
                roleTopic
            );
            
            firebaseMessaging.unsubscribeFromTopic(
                List.of(user.getFcmToken()), 
                "order_updates"
            );
            
            System.out.println("User " + user.getEmail() + " unsubscribed from topics");
        } catch (Exception e) {
            System.err.println("Error unsubscribing user from topics: " + e.getMessage());
        }
    }
    
    private String getUserTopic(UserRole role) {
        switch (role) {
            case LAUNDRY:
                return "laundry_owners";
            case CUSTOMER:
                return "customers";
            default:
                return "customers";
        }
    }
}

// Auth Controller
@RestController
@RequestMapping("/auth")
public class AuthController {
    
    @Autowired
    private UserService userService;
    
    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody UserRegistrationRequest request) {
        try {
            // Validate request
            if (request.getName() == null || request.getName().trim().isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "Name is required"));
            }
            if (request.getEmail() == null || request.getEmail().trim().isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "Email is required"));
            }
            if (request.getPassword() == null || request.getPassword().trim().isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "Password is required"));
            }
            if (request.getPhone() == null || request.getPhone().trim().isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "Phone is required"));
            }
            if (request.getRole() == null) {
                return ResponseEntity.badRequest().body(Map.of("error", "Role is required"));
            }
            
            // Register user with FCM token
            User user = userService.registerUser(request);
            
            // Return user data (without password)
            Map<String, Object> response = new HashMap<>();
            response.put("id", user.getId());
            response.put("name", user.getName());
            response.put("email", user.getEmail());
            response.put("phone", user.getPhone());
            response.put("role", user.getRole());
            response.put("message", "User registered successfully");
            
            return ResponseEntity.status(201).body(response);
            
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
    
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        try {
            // Authenticate user
            User user = userService.authenticateUser(request.getEmail(), request.getPassword());
            
            // Return user data
            Map<String, Object> response = new HashMap<>();
            response.put("id", user.getId());
            response.put("name", user.getName());
            response.put("email", user.getEmail());
            response.put("phone", user.getPhone());
            response.put("role", user.getRole());
            response.put("message", "Login successful");
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}

// FCM Token Management Controller
@RestController
@RequestMapping("/users")
public class FCMTokenController {
    
    @Autowired
    private UserService userService;
    
    @PostMapping("/fcm-token")
    public ResponseEntity<?> registerFCMToken(@RequestBody FCMTokenRequest request) {
        try {
            userService.updateFCMToken(request.getUserId(), request.getFcmToken());
            return ResponseEntity.ok().body(Map.of("message", "FCM token registered successfully"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
    
    @PutMapping("/fcm-token/{userId}")
    public ResponseEntity<?> updateFCMToken(@PathVariable Long userId, @RequestBody FCMTokenRequest request) {
        try {
            userService.updateFCMToken(userId, request.getFcmToken());
            return ResponseEntity.ok().body(Map.of("message", "FCM token updated successfully"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
    
    @DeleteMapping("/fcm-token/{userId}")
    public ResponseEntity<?> deleteFCMToken(@PathVariable Long userId) {
        try {
            userService.deleteFCMToken(userId);
            return ResponseEntity.ok().body(Map.of("message", "FCM token deleted successfully"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}

// DTOs
public class FCMTokenRequest {
    private Long userId;
    private String fcmToken;
    
    // Getters and setters
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getFcmToken() { return fcmToken; }
    public void setFcmToken(String fcmToken) { this.fcmToken = fcmToken; }
}

public class LoginRequest {
    private String email;
    private String password;
    private String role;
    
    // Getters and setters
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
}

// Database Migration (if using Flyway or similar)
/*
-- Add FCM token column to users table
ALTER TABLE users ADD COLUMN fcm_token VARCHAR(500);

-- Create index for FCM token lookups
CREATE INDEX idx_users_fcm_token ON users(fcm_token);
*/ 