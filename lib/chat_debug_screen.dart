import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'api_service.dart';
import 'chat_models.dart';
import 'chat_detail_screen.dart';

class ChatDebugScreen extends StatefulWidget {
  const ChatDebugScreen({Key? key}) : super(key: key);

  @override
  _ChatDebugScreenState createState() => _ChatDebugScreenState();
}

class _ChatDebugScreenState extends State<ChatDebugScreen> {
  final List<String> _debugLogs = [];
  bool _isLoading = false;
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? _testConversation;

  @override
  void initState() {
    super.initState();
    _addLog('Debug screen initialized');
  }

  void _addLog(String message) {
    setState(() {
      _debugLogs.add('${DateTime.now().toIso8601String()}: $message');
    });
    print('DEBUG: $message');
  }

  void _clearLogs() {
    setState(() {
      _debugLogs.clear();
    });
  }

  Future<void> _testConnection() async {
    _addLog('Testing API connection...');
    setState(() => _isLoading = true);
    
    try {
      final isConnected = await ApiService.testConnection();
      _addLog('Connection test result: $isConnected');
      
      if (isConnected) {
        Fluttertoast.showToast(
          msg: "Connection successful ✅",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Connection failed ❌",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      _addLog('Connection test exception: $e');
      Fluttertoast.showToast(
        msg: "Connection error: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGetCurrentUser() async {
    _addLog('Testing getCurrentUser...');
    setState(() => _isLoading = true);
    
    try {
      final userData = await ApiService.getCurrentUser();
      setState(() => _currentUser = userData);
      _addLog('Current user data: $userData');
      
      final isLoggedIn = await ApiService.isLoggedIn();
      _addLog('Is logged in: $isLoggedIn');
      
      if (userData['id'] != null) {
        Fluttertoast.showToast(
          msg: "User data retrieved ✅",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: "No user data found ❌",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      _addLog('getCurrentUser exception: $e');
      Fluttertoast.showToast(
        msg: "Error getting user: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testCreateConversation() async {
    if (_currentUser == null || _currentUser!['id'] == null) {
      _addLog('Cannot test conversation - no user data');
      Fluttertoast.showToast(
        msg: "Please test user data first",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    _addLog('Testing createOrGetConversation...');
    setState(() => _isLoading = true);
    
    try {
      final customerId = int.tryParse(_currentUser!['id'] ?? '');
      final laundryId = 1; // Test with a simple laundry ID
      
      if (customerId == null) {
        _addLog('Invalid customer ID');
        Fluttertoast.showToast(
          msg: "Invalid customer ID",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      _addLog('Creating conversation with customerId: $customerId, laundryId: $laundryId');
      
      final result = await ApiService.createOrGetConversation(
        customerId: customerId,
        laundryId: laundryId,
      );
      
      _addLog('Conversation result: $result');
      
      if (result['success']) {
        setState(() => _testConversation = result['data']);
        _addLog('Conversation created successfully');
        Fluttertoast.showToast(
          msg: "Conversation created ✅",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        _addLog('Failed to create conversation: ${result['message']}');
        Fluttertoast.showToast(
          msg: "Failed to create conversation: ${result['message']}",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      _addLog('createOrGetConversation exception: $e');
      Fluttertoast.showToast(
        msg: "Error creating conversation: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testOpenChat() async {
    if (_testConversation == null) {
      _addLog('Cannot open chat - no conversation data');
      Fluttertoast.showToast(
        msg: "Please create a conversation first",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    if (_currentUser == null) {
      _addLog('Cannot open chat - no user data');
      Fluttertoast.showToast(
        msg: "Please test user data first",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    _addLog('Testing chat screen navigation...');
    
    try {
      final conversation = ChatConversation.fromJson(_testConversation!);
      final currentUserId = int.tryParse(_currentUser!['id'] ?? '');
      final currentUserRole = _currentUser!['role'] ?? 'CUSTOMER';
      
      if (currentUserId == null) {
        _addLog('Invalid user ID for chat');
        return;
      }

      _addLog('Opening chat with conversation ID: ${conversation.id}');
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            conversation: conversation,
            currentUserId: currentUserId,
            currentUserRole: currentUserRole,
          ),
        ),
      );
      
      _addLog('Chat screen navigation successful');
    } catch (e) {
      _addLog('Chat screen navigation error: $e');
      Fluttertoast.showToast(
        msg: "Error opening chat: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Test buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testConnection,
                        child: const Text('Test Connection'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testGetCurrentUser,
                        child: const Text('Test User'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testCreateConversation,
                        child: const Text('Test Conversation'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testOpenChat,
                        child: const Text('Test Chat'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Loading indicator
          if (_isLoading)
            const LinearProgressIndicator(),
          
          // User info display
          if (_currentUser != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current User:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('ID: ${_currentUser!['id']}'),
                  Text('Name: ${_currentUser!['name']}'),
                  Text('Role: ${_currentUser!['role']}'),
                ],
              ),
            ),
          
          // Conversation info display
          if (_testConversation != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Test Conversation:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('ID: ${_testConversation!['id']}'),
                  Text('Customer ID: ${_testConversation!['customerId']}'),
                  Text('Laundry ID: ${_testConversation!['laundryId']}'),
                ],
              ),
            ),
          
          // Debug logs
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Debug Logs:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _debugLogs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            _debugLogs[index],
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 