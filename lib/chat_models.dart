class ChatMessage {
  final int? id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String senderRole; // 'CUSTOMER' or 'LAUNDRY'
  final String message;
  final String messageType; // 'text', 'image', 'order_update'
  final DateTime timestamp;
  final bool isRead;
  final DateTime? readAt;

  ChatMessage({
    this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.messageType = 'text',
    required this.timestamp,
    this.isRead = false,
    this.readAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      conversationId: json['conversationId'] ?? json['conversation_id'] ?? 0,
      senderId: json['senderId'] ?? json['sender_id'] ?? 0,
      senderName: json['senderName'] ?? json['sender_name'] ?? 'Unknown',
      senderRole: json['senderRole'] ?? json['sender_role'] ?? 'CUSTOMER',
      message: json['message'] ?? '',
      messageType: json['messageType'] ?? json['message_type'] ?? 'text',
      timestamp: DateTime.tryParse(json['timestamp'] ?? json['created_at'] ?? '') ?? DateTime.now(),
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message,
      'messageType': messageType,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
    };
  }

  ChatMessage copyWith({
    int? id,
    int? conversationId,
    int? senderId,
    String? senderName,
    String? senderRole,
    String? message,
    String? messageType,
    DateTime? timestamp,
    bool? isRead,
    DateTime? readAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }
}

class ChatConversation {
  final int id;
  final int customerId;
  final String customerName;
  final int laundryId;
  final String laundryName;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.laundryId,
    required this.laundryName,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] ?? 0,
      customerId: json['customerId'] ?? json['customer_id'] ?? 0,
      customerName: json['customerName'] ?? json['customer_name'] ?? 'Unknown Customer',
      laundryId: json['laundryId'] ?? json['laundry_id'] ?? 0,
      laundryName: json['laundryName'] ?? json['laundry_name'] ?? 'Unknown Laundry',
      lastMessage: json['lastMessage'] != null 
          ? ChatMessage.fromJson(json['lastMessage'])
          : json['last_message'] != null 
              ? ChatMessage.fromJson(json['last_message'])
              : null,
      unreadCount: json['unreadCount'] ?? json['unread_count'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'laundryId': laundryId,
      'laundryName': laundryName,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ChatConversation copyWith({
    int? id,
    int? customerId,
    String? customerName,
    int? laundryId,
    String? laundryName,
    ChatMessage? lastMessage,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      laundryId: laundryId ?? this.laundryId,
      laundryName: laundryName ?? this.laundryName,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  String getOtherPartyName(String currentUserRole) {
    return currentUserRole.toUpperCase() == 'LAUNDRY' ? customerName : laundryName;
  }

  int getOtherPartyId(String currentUserRole) {
    return currentUserRole.toUpperCase() == 'LAUNDRY' ? customerId : laundryId;
  }

  String getFormattedLastMessageTime() {
    if (lastMessage == null) return '';
    
    final now = DateTime.now();
    final messageTime = lastMessage!.timestamp;
    final difference = now.difference(messageTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String getLastMessagePreview({int maxLength = 50}) {
    if (lastMessage == null) return 'No messages yet';
    
    final message = lastMessage!.message;
    if (message.length <= maxLength) return message;
    return '${message.substring(0, maxLength)}...';
  }
}

class ChatUser {
  final int id;
  final String name;
  final String role; // 'CUSTOMER' or 'LAUNDRY'
  final String? profileImage;
  final bool isOnline;
  final DateTime? lastSeen;

  ChatUser({
    required this.id,
    required this.name,
    required this.role,
    this.profileImage,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      role: json['role'] ?? 'CUSTOMER',
      profileImage: json['profileImage'] ?? json['profile_image'],
      isOnline: json['isOnline'] ?? json['is_online'] ?? false,
      lastSeen: json['lastSeen'] != null 
          ? DateTime.tryParse(json['lastSeen'])
          : json['last_seen'] != null
              ? DateTime.tryParse(json['last_seen'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'profileImage': profileImage,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }
}

// Enum for message types
enum MessageType {
  text,
  image,
  orderUpdate,
  systemMessage,
}

// Enum for conversation status
enum ConversationStatus {
  active,
  archived,
  blocked,
}

// Extension methods for better formatting
extension ChatMessageExtensions on ChatMessage {
  bool get isSentByCurrentUser => false; // This will be set based on current user context
  
  String getFormattedTime() {
    final now = DateTime.now();
    final messageDate = timestamp;
    
    if (now.difference(messageDate).inDays == 0) {
      // Same day - show time
      return '${messageDate.hour.toString().padLeft(2, '0')}:${messageDate.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(messageDate).inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      // This week - show day
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[messageDate.weekday - 1];
    } else {
      // Older - show date
      return '${messageDate.day}/${messageDate.month}/${messageDate.year}';
    }
  }
} 