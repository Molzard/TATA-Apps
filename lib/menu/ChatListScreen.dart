import 'package:flutter/material.dart';
import 'package:TATA/models/ChatModel.dart';
import 'package:TATA/sendApi/ChatService.dart';
import 'package:TATA/helper/user_preferences.dart';
import 'package:TATA/menu/ChatDetailScreen.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);
  
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String? _userId;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  List<ChatModel> _chatList = [];
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }
  
  Future<void> _checkAuthentication() async {
    try {
      final userData = await UserPreferences.getUser();
      
      if (userData == null) {
        print('No user data found for chat');
        setState(() {
          _isLoading = false;
          _isAuthenticated = false;
        });
        return;
      }
      
      print('ChatListScreen userData structure: $userData');
      
      String? userId;
      
      if (userData.containsKey('data') && userData['data'] != null) {
        final data = userData['data'];
        if (data is Map && data.containsKey('user') && data['user'] != null) {
          final user = data['user'];
          if (user is Map && user.containsKey('id')) {
            userId = user['id'].toString();
          }
        }
      } else if (userData.containsKey('user') && userData['user'] != null) {
        final user = userData['user'];
        if (user is Map && user.containsKey('id')) {
          userId = user['id'].toString();
        }
      } else if (userData.containsKey('id')) {
        userId = userData['id'].toString();
      }
      
      if (userId != null && userId.isNotEmpty) {
        setState(() {
          _userId = userId;
          _isAuthenticated = true;
        });
        print('ChatListScreen userId set to: $userId');
        
        await _loadChatList();
      } else {
        print('Could not extract user ID from userData in ChatListScreen');
        setState(() {
          _isLoading = false;
          _isAuthenticated = false;
        });
      }
    } catch (e) {
      print('Error loading user ID: $e');
      setState(() {
        _isLoading = false;
        _isAuthenticated = false;
        _error = e.toString();
      });
    }
  }
  
  Future<void> _loadChatList() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      print('Loading chat list...');
      
      final chatList = await ChatService.getChatList();
      
      setState(() {
        _chatList = chatList;
        _isLoading = false;
      });
      
      print('Loaded ${chatList.length} chats');
    } catch (e) {
      print('Error loading chat list: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }
  
  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return DateFormat.Hm().format(dateTime);
      } else if (difference.inDays == 1) {
        return 'Kemarin';
      } else if (difference.inDays < 7) {
        return DateFormat.EEEE().format(dateTime);
      } else {
        return DateFormat('dd/MM/yyyy').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chat'),
          backgroundColor: CustomColors.primaryColor,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chat'),
          backgroundColor: CustomColors.primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Colors.grey,
              ),
              SizedBox(height: 20),
              Text(
                'Anda harus login untuk mengakses chat',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/login', 
                    (route) => false
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.primaryColor,
                ),
                child: Text(
                  'Login',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          backgroundColor: CustomColors.primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading chats',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadChatList,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.primaryColor,
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: CustomColors.primaryColor,
        actions: [
          IconButton(
            onPressed: _loadChatList,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: _chatList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Anda belum memiliki chat',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadChatList,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CustomColors.primaryColor,
                    ),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadChatList,
              child: ListView.builder(
                itemCount: _chatList.length,
                itemBuilder: (context, index) {
                  final chat = _chatList[index];
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(8),
                      leading: CircleAvatar(
                        backgroundColor: CustomColors.primaryColor,
                        child: const Icon(
                          Icons.support_agent,
                          color: Colors.white,
                        ),
                      ),
                      title: Row(
                        children: [
                          const Text(
                            'Admin TATA',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            _formatTimestamp(chat.updatedAt.toIso8601String()),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (chat.orderReference != null && chat.orderReference!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 4),
                              child: Text(
                                'Pesanan #${chat.orderReference}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CustomColors.secondaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chat.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (chat.unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: CustomColors.accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    chat.unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        final chatId = chat.orderReference ?? chat.id;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(chatId: chatId),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _loadChatList();
        },
        backgroundColor: CustomColors.primaryColor,
        child: const Icon(Icons.refresh),
      ),
    );
  }
} 