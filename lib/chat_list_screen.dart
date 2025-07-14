import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'api_service.dart';
import 'chat_models.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _currentUserRole;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserInfoAndConversations();
  }

  Future<void> _loadUserInfoAndConversations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get current user info
      final userData = await ApiService.getCurrentUser();
      _currentUserId = int.tryParse(userData['id'] ?? '');
      _currentUserRole = userData['role'];

      if (_currentUserId == null) {
        throw Exception('Invalid user ID');
      }

      // Load conversations
      await _loadConversations();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load user info: ${e.toString()}';
      });
    }
  }

  Future<void> _loadConversations() async {
    if (_currentUserId == null) return;

    try {
      final result = await ApiService.getConversations(_currentUserId!);
      
      setState(() {
        _isLoading = false;
        if (result['success']) {
          final conversationsData = result['data'] as List<dynamic>? ?? [];
          _conversations = conversationsData
              .map((json) => ChatConversation.fromJson(json))
              .toList();
          // Sort by last message time (most recent first)
          _conversations.sort((a, b) {
            if (a.lastMessage == null && b.lastMessage == null) return 0;
            if (a.lastMessage == null) return 1;
            if (b.lastMessage == null) return -1;
            return b.lastMessage!.timestamp.compareTo(a.lastMessage!.timestamp);
          });
        } else {
          _errorMessage = result['message'] ?? 'Failed to load conversations';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading conversations: ${e.toString()}';
      });
      Fluttertoast.showToast(
        msg: "Error loading chats: ${e.toString()}",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _refreshConversations() async {
    await _loadConversations();
  }

  void _openChat(ChatConversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          conversation: conversation,
          currentUserId: _currentUserId!,
          currentUserRole: _currentUserRole!,
        ),
      ),
    ).then((_) {
      // Refresh conversations when returning from chat
      _refreshConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: const Color(0xFF424242),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshConversations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF424242)),
                  SizedBox(height: 16),
                  Text('Loading conversations...'),
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
                        onPressed: _loadConversations,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _conversations.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _refreshConversations,
                      child: ListView.builder(
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = _conversations[index];
                          return _buildConversationItem(conversation);
                        },
                      ),
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
            'No conversations yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentUserRole?.toUpperCase() == 'LAUNDRY'
                ? 'Customers will contact you when they have questions'
                : 'Start a conversation with a laundry service',
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

  Widget _buildConversationItem(ChatConversation conversation) {
    final otherPartyName = conversation.getOtherPartyName(_currentUserRole ?? '');
    final hasUnread = conversation.unreadCount > 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF424242).withOpacity(0.1),
          child: Text(
            otherPartyName.isNotEmpty ? otherPartyName[0].toUpperCase() : '?',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF424242),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherPartyName,
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                  fontSize: 16,
                  color: const Color(0xFF212121),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (conversation.lastMessage != null)
              Text(
                conversation.getFormattedLastMessageTime(),
                style: TextStyle(
                  fontSize: 12,
                  color: hasUnread ? const Color(0xFF424242) : Colors.grey[600],
                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                conversation.getLastMessagePreview(),
                style: TextStyle(
                  fontSize: 14,
                  color: hasUnread ? const Color(0xFF424242) : Colors.grey[600],
                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (hasUnread)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  conversation.unreadCount > 99 ? '99+' : '${conversation.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: () => _openChat(conversation),
      ),
    );
  }
} 