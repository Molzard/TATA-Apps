import 'package:flutter/material.dart';
import 'package:TATA/models/ChatModel.dart';
import 'package:TATA/services/ChatService.dart';
import 'package:TATA/helper/user_preferences.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:TATA/sendApi/Server.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) 'dart:html' as html;

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  
  const ChatDetailScreen({required this.chatId, Key? key}) : super(key: key);
  
  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  String? _userId;
  ChatModel? _chatData;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _orderInfo;
  
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    print('=== ChatDetailScreen INIT ===');
    print('Chat ID: ${widget.chatId}');
    print('Platform: ${kIsWeb ? "Web" : "Mobile"}');
    print('==============================');
    
    _loadUserId();
    _loadChatData();
    _markMessagesAsRead();
    _loadMessages();
    _loadOrderInfo();
    
    _startPeriodicRefresh();
  }
  
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadMessages();
      } else {
        timer.cancel();
      }
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserId() async {
    try {
      final userData = await UserPreferences.getUser();
      
      if (userData == null) {
        print('No user data found');
        return;
      }
      
      print('ChatDetailScreen userData structure: $userData');
      
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
        if (mounted) {
          setState(() {
            _userId = userId;
          });
        }
        print('ChatDetailScreen userId set to: $userId');
      } else {
        print('Could not extract user ID from userData: $userData');
      }
    } catch (e) {
      print('Error loading user ID: $e');
    }
  }
  
  Future<void> _loadChatData() async {
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();
      
      if (chatDoc.exists && mounted) {
        setState(() {
          _chatData = ChatModel.fromFirestore(chatDoc);
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading chat data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadOrderInfo() async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        print('No token available for order info');
        return;
      }
      
      print('Loading order info for: ${widget.chatId}');
      
      final response = await http.get(
        Server.urlLaravel('mobile/pesanan/order-info/${widget.chatId}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': token,
        },
      );
      
      print('Order info response status: ${response.statusCode}');
      print('Order info response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _orderInfo = data['data'];
          });
          print('Order info loaded successfully: $_orderInfo');
        } else {
          print('Order info API error: ${data['message']}');
        }
      } else {
        print('Order info HTTP error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error loading order info: $e');
    }
  }
  
  void _markMessagesAsRead() {
    if (widget.chatId.isNotEmpty) {
      _chatService.markMessagesAsReadByOrderId(widget.chatId);
    }
  }
  
  Future<void> _loadMessages() async {
    try {
      print('Loading messages for chat: ${widget.chatId}');
      
      final response = await _chatService.getMessagesByOrderId(widget.chatId);
      
      if (response != null && response['status'] == 'success') {
        final messages = response['messages'] as List<dynamic>? ?? [];
        
        if (mounted) {
          setState(() {
            _messages = messages.map((msg) => Map<String, dynamic>.from(msg)).toList();
            _isLoading = false;
          });
        }
        
        print('Loaded ${_messages.length} messages');
      } else {
        print('Failed to load messages: ${response?['message'] ?? 'Unknown error'}');
        if (mounted) {
          setState(() {
            _messages = [];
            _isLoading = false;
          });
        }
        
        if (response?['status'] != 'success' && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response?['message'] ?? 'Gagal memuat pesan'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        setState(() {
          _messages = [];
          _isLoading = false;
        });
      }
      
      if (!e.toString().contains('timeout') && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _showAttachmentOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: CustomColors.primaryColor),
                title: Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: Icon(Icons.camera_alt, color: CustomColors.primaryColor),
                  title: Text('Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ListTile(
                leading: Icon(Icons.cancel, color: Colors.grey),
                title: Text('Batal'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        if (kIsWeb) {
          final Uint8List imageBytes = await image.readAsBytes();
          await _uploadAndSendImageWeb(imageBytes, image.name);
        } else {
          if (!kIsWeb) {
            final dynamic imageFile = await _createFile(image.path);
            await _uploadAndSendImageMobile(imageFile);
          }
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }
  
  dynamic _createFile(String path) {
    if (kIsWeb) {
      return null;
    } else {
      return null;
    }
  }
  
  Future<void> _uploadAndSendImageWeb(Uint8List imageBytes, String fileName) async {
    if (_userId == null) return;
    
    setState(() {
      _isUploadingImage = true;
    });
    
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }
      
      print('Uploading image (web): $fileName, size: ${imageBytes.length} bytes');
      
      final uri = Server.urlLaravel('mobile/chat/upload');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = token;
      request.headers['Accept'] = 'application/json';
      
      final image = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(image);
      
      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      final responseData = jsonDecode(responseString);
      
      print('Upload response status: ${response.statusCode}');
      print('Upload response data: $responseData');
      
      if (response.statusCode == 200 && responseData['status'] == 'success') {
        final fileUrl = responseData['data']['file_url'];
        
        final messageResponse = await _chatService.sendMessageByOrderId(
          widget.chatId,
          'Mengirim gambar',
          messageType: 'image',
          fileUrl: fileUrl,
        );
        
        if (messageResponse != null && messageResponse['status'] == 'success') {
          print('Image message sent successfully');
          await _loadMessages();
        } else {
          throw Exception('Gagal mengirim pesan gambar');
        }
      } else {
        throw Exception('Gagal upload gambar: ${responseData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error uploading image (web): $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim gambar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }
  
  Future<void> _uploadAndSendImageMobile(dynamic imageFile) async {
    if (_userId == null) return;
    
    setState(() {
      _isUploadingImage = true;
    });
    
    try {
      throw Exception('Mobile upload belum diimplementasikan. Gunakan web untuk upload gambar.');
    } catch (e) {
      print('Error uploading image (mobile): $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim gambar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }
  
  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty && _userId != null) {
      final messageText = _messageController.text.trim();
      _messageController.clear();
      
      try {
        final response = await _chatService.sendMessageByOrderId(
          widget.chatId,
          messageText,
        );
        
        if (response != null && response['status'] == 'success') {
          print('Message sent successfully');
          await _loadMessages();
        } else {
          print('Failed to send message: ${response?['message'] ?? 'Unknown error'}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengirim pesan: ${response?['message'] ?? 'Unknown error'}')),
            );
          }
        }
      } catch (e) {
        print('Error sending message: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    } else if (_userId == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User ID tidak ditemukan')),
      );
    }
  }
  
  Widget _buildProductInfoBox() {
    if (_orderInfo == null) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Memuat info pesanan...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: CustomColors.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Kamu bertanya tentang produk ini',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildInfoRow('Nomor Pemesanan', '#${_orderInfo?['order_id'] ?? widget.chatId}'),
                _buildInfoRow('Jenis', 'Desain ${_orderInfo?['jasa']?['kategori'] ?? 'Logo'}'),
                _buildInfoRow('Paket', '${_orderInfo?['paket']?['kelas_jasa'] ?? 'Premium'}'),
                _buildInfoRow('Metode Pembayaran', '${_orderInfo?['metode_pembayaran'] ?? 'Virtual Account'}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(Map<String, dynamic> message, bool isFromUser, bool isSystemMessage) {
    if (isSystemMessage) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message['message'] ?? '',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    final messageType = message['message_type'] ?? 'text';
    final isImage = messageType == 'image';
    
    return Align(
      alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isFromUser ? CustomColors.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isImage && message['file_url'] != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message['file_url'],
                  fit: BoxFit.cover,
                  height: 200,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / 
                                loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.grey),
                            Text('Gagal memuat gambar', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (message['message'] != null && message['message'].toString().isNotEmpty)
                const SizedBox(height: 8),
            ],
            if (message['message'] != null && message['message'].toString().isNotEmpty)
              Text(
                message['message'] ?? '',
                style: TextStyle(
                  color: isFromUser ? Colors.white : Colors.black,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTimestamp(message['created_at'] ?? ''),
                  style: TextStyle(
                    fontSize: 10,
                    color: isFromUser ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(width: 4),
                if (isFromUser)
                  Icon(
                    message['is_read'] == true ? Icons.done_all : Icons.done,
                    size: 12,
                    color: Colors.white70,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat dengan Admin'),
        backgroundColor: CustomColors.primaryColor,
      ),
      body: Column(
        children: [
          _buildProductInfoBox(),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                ? const Center(child: Text('Belum ada pesan'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isFromUser = message['sender_type'] == 'user';
                      final isSystemMessage = message['sender_type'] == 'system';
                      
                      return _buildMessageBubble(message, isFromUser, isSystemMessage);
                    },
                  ),
          ),
          
          if (_isUploadingImage)
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text('Mengirim gambar...', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _isUploadingImage ? null : _showAttachmentOptions,
                  icon: Icon(
                    Icons.attach_file,
                    color: _isUploadingImage ? Colors.grey : Colors.grey[600],
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isUploadingImage,
                  ),
                ),
                IconButton(
                  onPressed: _isUploadingImage ? null : _sendMessage,
                  icon: Icon(
                    Icons.send,
                    color: _isUploadingImage ? Colors.grey : CustomColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Kemarin ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        final weekday = _getIndonesianWeekday(dateTime.weekday);
        return '$weekday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else {
        return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }
  
  String _getIndonesianWeekday(int weekday) {
    const weekdays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return weekdays[weekday - 1];
  }
} 