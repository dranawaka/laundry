# Notification Fix Guide: Proper Recipient Targeting

## Problem Description

Currently, when a customer places an order, the customer is receiving the notification instead of the laundry owner. This is incorrect behavior - **laundry owners should receive notifications for new orders**, while **customers should receive notifications for order status updates**.

## Root Cause Analysis

The issue is likely in the backend notification logic where:

1. **Wrong recipient targeting**: Notifications are being sent to the customer instead of the laundry owner
2. **Incorrect topic subscription**: Both user types might be subscribed to the same topics
3. **Missing role-based notification logic**: The backend doesn't properly distinguish between user roles when sending notifications

## Solution Implementation

### 1. Backend Notification Service

Create a proper `NotificationService` in your Spring Boot backend:

```java
@Service
public class NotificationService {
    
    @Autowired
    private UserService userService;
    
    @Autowired
    private FirebaseMessaging firebaseMessaging;
    
    // Send notification to laundry owner when new order is placed
    public void sendNewOrderNotificationToLaundryOwner(Long laundryOwnerId, String orderId, String customerName) {
        try {
            // Get laundry owner's FCM token
            String fcmToken = userService.getFCMToken(laundryOwnerId);
            if (fcmToken == null) {
                System.out.println("No FCM token found for laundry owner: " + laundryOwnerId);
                return;
            }
            
            // Create notification payload
            Map<String, Object> payload = NotificationHelper.getNewOrderPayload(
                fcmToken, 
                orderId, 
                customerName
            );
            
            // Send notification
            firebaseMessaging.send(payload);
            System.out.println("New order notification sent to laundry owner: " + laundryOwnerId);
            
        } catch (Exception e) {
            System.err.println("Error sending new order notification to laundry owner: " + e.getMessage());
        }
    }
    
    // Send notification to customer when order status is updated
    public void sendOrderStatusUpdateToCustomer(Long customerId, String orderId, String status, String laundryName) {
        try {
            // Get customer's FCM token
            String fcmToken = userService.getFCMToken(customerId);
            if (fcmToken == null) {
                System.out.println("No FCM token found for customer: " + customerId);
                return;
            }
            
            // Create notification payload
            Map<String, Object> payload = NotificationHelper.getOrderStatusUpdatePayload(
                fcmToken, 
                orderId, 
                status,
                laundryName
            );
            
            // Send notification
            firebaseMessaging.send(payload);
            System.out.println("Order status update notification sent to customer: " + customerId);
            
        } catch (Exception e) {
            System.err.println("Error sending order status update to customer: " + e.getMessage());
        }
    }
}
```

### 2. Order Controller Integration

Update your order placement endpoint to send notifications to the correct recipients:

```java
@RestController
@RequestMapping("/orders")
public class OrderController {
    
    @Autowired
    private OrderService orderService;
    
    @Autowired
    private NotificationService notificationService;
    
    @PostMapping("/place")
    public ResponseEntity<?> placeOrder(@RequestBody OrderRequest request) {
        try {
            // Place the order
            Order order = orderService.placeOrder(request);
            
            // Get laundry owner ID from the laundry
            Long laundryOwnerId = orderService.getLaundryOwnerId(order.getLaundryId());
            String customerName = orderService.getCustomerName(order.getCustomerId());
            
            // Send notification to LAUNDRY OWNER (not customer)
            notificationService.sendNewOrderNotificationToLaundryOwner(
                laundryOwnerId, 
                order.getId().toString(), 
                customerName
            );
            
            return ResponseEntity.ok(Map.of(
                "message", "Order placed successfully",
                "orderId", order.getId()
            ));
            
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
    
    @PutMapping("/{orderId}/update-status")
    public ResponseEntity<?> updateOrderStatus(
        @PathVariable Long orderId, 
        @RequestBody StatusUpdateRequest request
    ) {
        try {
            // Update order status
            Order order = orderService.updateOrderStatus(orderId, request.getStatus());
            
            // Get customer ID and laundry name
            Long customerId = order.getCustomerId();
            String laundryName = orderService.getLaundryName(order.getLaundryId());
            
            // Send notification to CUSTOMER (not laundry owner)
            notificationService.sendOrderStatusUpdateToCustomer(
                customerId, 
                orderId.toString(), 
                request.getStatus(),
                laundryName
            );
            
            return ResponseEntity.ok(Map.of("message", "Order status updated successfully"));
            
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
```

### 3. User Service Updates

Ensure your `UserService` properly handles role-based topic subscriptions:

```java
@Service
public class UserService {
    
    private void subscribeUserToTopics(User user) {
        if (user.getFcmToken() == null) return;
        
        try {
            // Subscribe to role-specific topics
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
```

### 4. Notification Flow Summary

#### When Customer Places Order:
1. ✅ **Customer places order** → Backend receives order
2. ✅ **Backend saves order** → Order is stored in database
3. ✅ **Backend gets laundry owner ID** → From laundry information
4. ✅ **Backend sends notification to LAUNDRY OWNER** → Using laundry owner's FCM token
5. ❌ **Customer should NOT receive notification** → Only laundry owner gets notified

#### When Laundry Owner Updates Order Status:
1. ✅ **Laundry owner updates status** → Backend receives status update
2. ✅ **Backend updates order** → Status is updated in database
3. ✅ **Backend gets customer ID** → From order information
4. ✅ **Backend sends notification to CUSTOMER** → Using customer's FCM token
5. ❌ **Laundry owner should NOT receive notification** → Only customer gets notified

### 5. Testing the Fix

#### Test Scenario 1: Customer Places Order
1. Customer logs in and places an order
2. **Expected**: Laundry owner receives "New Order Received" notification
3. **Expected**: Customer does NOT receive any notification
4. **Verify**: Check laundry owner's device for notification

#### Test Scenario 2: Laundry Owner Updates Status
1. Laundry owner logs in and updates order status
2. **Expected**: Customer receives "Order Status Updated" notification
3. **Expected**: Laundry owner does NOT receive any notification
4. **Verify**: Check customer's device for notification

### 6. Debugging Steps

If the issue persists, check these points:

1. **FCM Token Storage**: Ensure FCM tokens are properly stored for both user types
2. **User Role Assignment**: Verify that users have correct roles (LAUNDRY vs CUSTOMER)
3. **Backend Logs**: Check backend logs for notification sending attempts
4. **Firebase Console**: Verify notifications are being sent to correct tokens
5. **Topic Subscriptions**: Ensure users are subscribed to correct topics

### 7. Common Mistakes to Avoid

1. ❌ **Sending to customer when order is placed**
2. ❌ **Sending to laundry owner when status is updated**
3. ❌ **Using wrong FCM token for recipient**
4. ❌ **Subscribing all users to same topics**
5. ❌ **Not checking user roles before sending notifications**

### 8. Verification Checklist

- [ ] Laundry owners receive notifications for new orders
- [ ] Customers receive notifications for order status updates
- [ ] Customers do NOT receive notifications when placing orders
- [ ] Laundry owners do NOT receive notifications when updating status
- [ ] FCM tokens are properly stored and retrieved
- [ ] User roles are correctly assigned
- [ ] Backend logs show correct notification recipients
- [ ] Firebase console shows successful message delivery

## Implementation Priority

1. **High Priority**: Fix backend notification logic
2. **Medium Priority**: Update topic subscriptions
3. **Low Priority**: Add additional notification types

This fix ensures that notifications are sent to the correct recipients based on the user's role and the action being performed. 