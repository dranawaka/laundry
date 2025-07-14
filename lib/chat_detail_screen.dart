import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import 'api_service.dart';
import 'chat_models.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatConversation conversation;
  final int currentUserId;
  final String currentUserRole;

  const ChatDetailScreen({
    Key? key,
    required this.conversation,
    required this.currentUserId,
    required this.currentUserRole,
  }) : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String _errorMessage = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    print('🔵 ChatDetailScreen initState');
    print('🔵 Conversation ID: ${widget.conversation.id}');
    print('🔵 Current User ID: ${widget.currentUserId}');
    print('🔵 Current User Role: ${widget.currentUserRole}');
    _loadMessages();
    _markMessagesAsRead();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    print('🔵 Loading messages for conversation: ${widget.conversation.id}');
    try {
      final result = await ApiService.getMessages(widget.conversation.id);
      print('🔵 Messages result: $result');
      
      setState(() {
        _isLoading = false;
        if (result['success']) {
          // Support paginated or direct list response
          dynamic data = result['data'];
          List<dynamic> messagesData;
          if (data is Map<String, dynamic> && data.containsKey('content')) {
            messagesData = data['content'] as List<dynamic>? ?? [];
          } else if (data is List) {
            messagesData = data;
          } else {
            messagesData = [];
          }
          print('🔵 Messages data: $messagesData');
          _messages = messagesData
              .map((json) => ChatMessage.fromJson(json))
              .toList();
          // Sort by timestamp (oldest first for chat display)
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          print('✅ Loaded ${_messages.length} messages');
        } else {
          _errorMessage = result['message'] ?? 'Failed to load messages';
          print('❌ Failed to load messages: $_errorMessage');
        }
      });

      // Scroll to bottom after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('❌ Exception loading messages: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading messages: ${e.toString()}';
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    print('🔵 Marking messages as read for conversation: ${widget.conversation.id}');
    try {
      await ApiService.markMessagesAsRead(widget.conversation.id, widget.currentUserId);
      print('✅ Messages marked as read');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _refreshMessages();
    });
  }

  Future<void> _refreshMessages() async {
    try {
      final result = await ApiService.getMessages(widget.conversation.id);
      
      // Support paginated or direct list response
      dynamic data = result['data'];
      List<dynamic> messagesData;
      if (data is Map<String, dynamic> && data.containsKey('content')) {
        messagesData = data['content'] as List<dynamic>? ?? [];
      } else if (data is List) {
        messagesData = data;
      } else {
        messagesData = [];
      }

      if (result['success']) {
        final newMessages = messagesData
            .map((json) => ChatMessage.fromJson(json))
            .toList();
        newMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        // Only update if there are new messages
        if (newMessages.length != _messages.length) {
          setState(() {
            _messages = newMessages;
          });
          _scrollToBottom();
          _markMessagesAsRead();
        }
      }
    } catch (e) {
      // Silently handle refresh errors to avoid disturbing the user
      print('Error refreshing messages: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    print('🔵 Attempting to send message: "$messageText"');
    
    if (messageText.isEmpty || _isSending) {
      print('❌ Message empty or already sending');
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      print('🔵 Sending message to API...');
      final result = await ApiService.sendMessage(
        conversationId: widget.conversation.id,
        senderId: widget.currentUserId,
        message: messageText,
      );

      print('🔵 Send message result: $result');

      if (result['success']) {
        print('✅ Message sent successfully');
        _messageController.clear();
        // Add the message locally for immediate feedback
        final newMessage = ChatMessage(
          conversationId: widget.conversation.id,
          senderId: widget.currentUserId,
          senderName: 'You',
          senderRole: widget.currentUserRole,
          message: messageText,
          timestamp: DateTime.now(),
        );
        
        setState(() {
          _messages.add(newMessage);
        });
        
        _scrollToBottom();
        // Refresh to get the actual message from server
        _refreshMessages();
      } else {
        print('❌ Failed to send message: ${result['message']}');
        Fluttertoast.showToast(
          msg: result['message'] ?? 'Failed to send message',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print('❌ Exception sending message: $e');
      Fluttertoast.showToast(
        msg: "Error sending message: ${e.toString()}",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  bool _isMyMessage(ChatMessage message) {
    return message.senderId == widget.currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    final otherPartyName = widget.conversation.getOtherPartyName(widget.currentUserRole);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                otherPartyName.isNotEmpty ? otherPartyName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherPartyName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.currentUserRole.toUpperCase() == 'LAUNDRY' ? 'Customer' : 'Laundry Service',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF424242),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMessages,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF424242)),
                        SizedBox(height: 16),
                        Text('Loading messages...'),
                      ],
                    ),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMessages,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(8),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return _buildMessageBubble(message);
                            },
                          ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation by sending a message',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMyMessage = _isMyMessage(message);
    final showTimestamp = _shouldShowTimestamp(message);

    return Column(
      children: [
        if (showTimestamp) _buildTimestampHeader(message),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          child: Row(
            mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMyMessage) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF424242).withOpacity(0.1),
                  child: Text(
                    message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMyMessage
                        ? const Color(0xFF424242)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.message,
                        style: TextStyle(
                          color: isMyMessage ? Colors.white : const Color(0xFF212121),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.getFormattedTime(),
                        style: TextStyle(
                          color: isMyMessage 
                              ? Colors.white70 
                              : Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isMyMessage) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF424242).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 16,
                    color: Color(0xFF424242),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  bool _shouldShowTimestamp(ChatMessage message) {
    final messageIndex = _messages.indexOf(message);
    if (messageIndex == 0) return true;

    final previousMessage = _messages[messageIndex - 1];
    final timeDifference = message.timestamp.difference(previousMessage.timestamp);
    
    // Show timestamp if more than 1 hour has passed
    return timeDifference.inHours >= 1;
  }

  Widget _buildTimestampHeader(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getDateHeader(message.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _getDateHeader(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[timestamp.weekday - 1];
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: 5,
                minLines: 1,
                enabled: !_isSending,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF424242),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
} 