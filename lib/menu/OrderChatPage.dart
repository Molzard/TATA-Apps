import 'dart:convert';
import 'package:TATA/helper/fcm_helper.dart';
import 'package:TATA/helper/user_preferences.dart';
import 'package:TATA/models/ChatModel.dart';
import 'package:TATA/sendApi/ChatService.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderChatPage extends StatefulWidget {
  final String pesananUuid;
  final String? jasaId;
  final String? jasaTitle;
  final String? jasaCategory;
  final String? packageType;
  final String? price;

  const OrderChatPage({
    super.key,
    required this.pesananUuid,
    this.jasaId,
    this.jasaTitle,
    this.jasaCategory,
    this.packageType,
    this.price,
  });

  @override
  State<OrderChatPage> createState() => _OrderChatPageState();
}

class _OrderChatPageState extends State<OrderChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _canSendMessage = false;

  List<MessageModel> messages = [];
  bool isLoading = true;
  String? chatId;
  bool isAdmin = false;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _scrollController.addListener(_onScroll);
    _controller.addListener(() {
      setState(() {
        _canSendMessage = _controller.text.trim().isNotEmpty;
      });
    });
    
    // Pastikan pengguna sudah login dan token ada sebelum mengambil data
    UserPreferences.getToken().then((token) {
      if (token != null) {
        _getOrCreateChatForOrder();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anda perlu login terlebih dahulu')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
    
    // Subscribe to FCM updates
    FCMHelper().chatMessageStream.listen(_handleIncomingFCMMessage);
  }
  
  Future<void> _checkUserRole() async {
    try {
      final userData = await UserPreferences.getUser();
      if (userData != null && userData['user'] != null && userData['user']['role'] != null) {
        setState(() {
          userRole = userData['user']['role'];
          isAdmin = ['admin', 'admin_chat', 'super_admin'].contains(userRole);
        });
      }
    } catch (e) {
      debugPrint('Error checking user role: $e');
    }
  }

  Future<void> _getOrCreateChatForOrder() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Dapatkan atau buat chat untuk pesanan ini
      final result = await ChatService.createChatForOrder(widget.pesananUuid);
      
      if (result != null && result['status'] == 'success' && result['data'] != null) {
        setState(() {
          chatId = result['data']['chat_id'] ?? result['data']['uuid'];
        });
        
        // Sekarang ambil pesan-pesan
        _loadChat();
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat chat untuk pesanan ini')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      // Tampilkan pesan template jika gagal memuat chat
      _loadTemplateMessage();
    }
  }

  Future<void> _loadChat() async {
    if (chatId == null) {
      _getOrCreateChatForOrder();
      return;
    }
    
    setState(() {
      isLoading = true;
    });

    try {
      // Ambil pesan-pesan chat
      final result = await ChatService.getChatDetail(chatId!);
      
      if (result != null && result['status'] == 'success' && result['data'] != null) {
        final List<dynamic> chatMessages = result['data']['messages'] ?? [];
        
        setState(() {
          messages = chatMessages.map((msg) => MessageModel.fromJson(msg)).toList();
          isLoading = false;
        });

        // Scroll ke bawah setelah memuat pesan
        _scrollToBottom();

        // Mark messages as read
        await ChatService.markMessagesAsRead(chatId!);
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading chat: $e");
      setState(() {
        isLoading = false;
      });
      // Tampilkan pesan template jika gagal memuat chat
      _loadTemplateMessage();
    }
  }

  void _loadTemplateMessage() {
    if (messages.isEmpty) {
      setState(() {
        messages.add(MessageModel(
          id: '1',
          chatId: chatId ?? '',
          content: "Selamat! Pesanan Anda telah diterima. Admin akan segera menghubungi Anda untuk informasi lebih lanjut.",
          senderType: 'admin',
          createdAt: DateTime.now(),
          isRead: true,
        ));
      });
    }
  }

  void _handleIncomingFCMMessage(Map<String, dynamic> messageData) {
    // Handle incoming FCM message
    if (messageData['chat_id'] == chatId) {
      final newMessage = MessageModel(
        id: messageData['message_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: chatId ?? '',
        content: messageData['body'] ?? '',
        senderType: 'admin',
        createdAt: DateTime.now(),
        isRead: false,
      );
      
      setState(() {
        messages.add(newMessage);
      });
      
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || chatId == null) return;

    _controller.clear();
    final newMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId!,
      content: text,
      senderType: 'user',
      createdAt: DateTime.now(),
      isRead: false,
    );
    
    setState(() {
      messages.add(newMessage);
    });

    // Scroll ke bawah
    _scrollToBottom();

    // Kirim pesan ke server
    try {
      await ChatService.sendMessage(chatId!, text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengirim pesan: $e")),
      );
    }
  }

  Widget buildProductCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Pesanan", style: TextStyle(fontSize: 12, color: Colors.grey)),
          SizedBox(height: 8),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade300,
                  child: widget.jasaCategory == 'logo' 
                      ? Icon(Icons.design_services, color: Colors.grey.shade800, size: 30)
                      : widget.jasaCategory == 'banner'
                          ? Icon(Icons.image, color: Colors.grey.shade800, size: 30)
                          : Icon(Icons.work, color: Colors.grey.shade800, size: 30),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.jasaTitle ?? 'Pesanan',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.packageType ?? '-',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(widget.price ?? '-',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildMessageBubble(MessageModel message) {
    bool isUser = message.senderType == 'user';
    
    // Format timestamp
    String formattedTime = DateFormat('HH:mm').format(message.createdAt);
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: isUser
            ? EdgeInsets.only(top: 4, bottom: 4, left: 60, right: 16)
            : EdgeInsets.only(top: 4, bottom: 4, right: 60, left: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.green : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(color: isUser ? Colors.white : Colors.black87),
            ),
            SizedBox(height: 2),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 10,
                  color: isUser ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onScroll() {
    // Implementasi dasar untuk mencegah error
    // Bisa digunakan untuk implementasi load more messages jika diperlukan
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Pesanan'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadChat,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            child: Align(
              alignment: Alignment.topLeft,
              child: Image.asset(
                Server.UrlGambar("atributhomecircle.png"),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Image.asset(
                Server.UrlGambar("atributhomebigcircle.png"),
              ),
            ),
          ),
          Column(
            children: [
              // Product card if data is available
              if (widget.jasaId != null && widget.jasaTitle != null) 
                buildProductCard(),
              
              // Chat messages
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return buildMessageBubble(msg);
                        },
                      ),
              ),
              
              // Chat input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Scrollbar(
                        child: TextField(
                          controller: _controller,
                          keyboardType: TextInputType.multiline,
                          maxLines: 4,
                          minLines: 1,
                          scrollPhysics: BouncingScrollPhysics(),
                          decoration: const InputDecoration(
                            hintText: 'Ketik pesan...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.green,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _canSendMessage ? () => sendMessage(_controller.text) : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 