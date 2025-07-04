import 'package:flutter/material.dart';
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
// import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'dart:io' show File;

class ChatDetailScreen extends StatefulWidget {
  final String chatId;

  const ChatDetailScreen({required this.chatId, Key? key}) : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _userId;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  String? _pesananUuid;
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _orderInfo;
  bool _hasScrolledToBottomOnce = false; // Flag untuk auto scroll hanya sekali

  Timer? _refreshTimer;

  final StreamController<List<Map<String, dynamic>>> _messagesController = StreamController.broadcast();

  // Tambahkan variable untuk title
  String _chatTitle = 'Chat dengan Admin';
  
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
    _messagesController.close();
    _scrollController.dispose();
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
          _isLoading = false;
          _pesananUuid = chatDoc['pesanan_uuid'];
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

  // Update method _loadOrderInfo untuk trigger _loadChatInfo setelah selesai
  Future<void> _loadOrderInfo() async {
    try {
      final token = await UserPreferences.getToken();
      print('Token yang digunakan: $token');
      if (token == null) {
        print('No token available for order info');
        // Set orderInfo sebagai map kosong untuk direct chat
        if (mounted) {
          setState(() {
            _orderInfo = {}; // Empty map menandakan tidak ada data pesanan
          });
        }
        await _loadChatInfo(); // Trigger update title
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
          // Set orderInfo sebagai map kosong untuk menandakan tidak ada data pesanan
          if (mounted) {
            setState(() {
              _orderInfo = {}; // Empty map menandakan tidak ada data pesanan
            });
          }
        }
      } else {
        print(
            'Order info HTTP error: ${response.statusCode} - ${response.body}');
        // Set orderInfo sebagai map kosong untuk menandakan tidak ada data pesanan
        if (mounted) {
          setState(() {
            _orderInfo = {}; // Empty map menandakan tidak ada data pesanan
          });
        }
      }
      
      // Trigger update title setelah _orderInfo di-set
      await _loadChatInfo();
      
    } catch (e) {
      print('Error loading order info: $e');
      // Set orderInfo sebagai map kosong untuk menandakan tidak ada data pesanan
      if (mounted) {
        setState(() {
          _orderInfo = {}; // Empty map menandakan tidak ada data pesanan
        });
      }
      // Trigger update title bahkan jika error
      await _loadChatInfo();
    }
  }

  void _markMessagesAsRead() {
    if (widget.chatId.isNotEmpty) {
      _chatService.markMessagesAsReadByOrderId(widget.chatId);
      // Tambahan: Mark pesan admin sebagai sudah dibaca oleh user
      _markAdminMessagesAsRead();
    }
  }
  
  // Tambahan fungsi untuk menandai pesan admin sebagai sudah dibaca
  Future<void> _markAdminMessagesAsRead() async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) return;
      
      final response = await http.post(
        Server.urlLaravel('mobile/chat/mark-admin-messages-read'),
        headers: {
          'Accept': 'application/json',
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'chat_uuid': widget.chatId,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          print('Admin messages marked as read successfully');
        }
      }
    } catch (e) {
      print('Error marking admin messages as read: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      print('=== [TATA-DEBUG] Loading messages for chat: ${widget.chatId} ===');
      final response = await _chatService.getMessagesByOrderId(widget.chatId);

      print('=== [TATA-DEBUG] Raw response: $response ===');

      if (response != null && response['status'] == 'success') {
        // Coba berbagai kemungkinan struktur response dari Laravel
        List<dynamic> messages = [];
        
        if (response.containsKey('data')) {
          // Jika response memiliki wrapper 'data'
          final data = response['data'];
          if (data is List) {
            messages = data;
          } else if (data is Map && data.containsKey('messages')) {
            messages = data['messages'] as List<dynamic>? ?? [];
          } else if (data is Map && data.containsKey('data')) {
            messages = data['data'] as List<dynamic>? ?? [];
          }
        } else if (response.containsKey('messages')) {
          // Jika response langsung memiliki 'messages'
          messages = response['messages'] as List<dynamic>? ?? [];
        } else {
          // Jika response adalah array langsung (tidak mungkin karena sudah check status success)
          print('=== [TATA-DEBUG] Unexpected response structure ===');
        }

        print('=== [TATA-DEBUG] Parsed messages count: ${messages.length} ===');
        
        final msgList = messages.map((msg) => Map<String, dynamic>.from(msg)).toList();
        if (mounted) {
          _messages = msgList;
          _messagesController.add(msgList); // <-- push ke stream
          setState(() {
            _isLoading = false;
          });
          // Auto scroll hanya sekali setelah membuka chat
          if (!_hasScrolledToBottomOnce) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                _hasScrolledToBottomOnce = true; // Set flag agar tidak scroll lagi otomatis
              }
            });
          }
        }
        print('=== [TATA-DEBUG] Loaded ${_messages.length} messages successfully ===');
      } else {
        print('Failed to load messages: ${response?['message'] ?? 'Unknown error'}');
        if (mounted) {
          _messages = [];
          _messagesController.add([]);
          setState(() {
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
        _messages = [];
        _messagesController.add([]);
        setState(() {
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
                leading:
                    Icon(Icons.photo_library, color: CustomColors.primaryColor),
                title: Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading:
                      Icon(Icons.camera_alt, color: CustomColors.primaryColor),
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
          final imageFile = File(image.path); // Tidak error lagi
          await _uploadAndSendImageMobile(imageFile);
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

  Future<void> _uploadAndSendImageWeb(
      Uint8List imageBytes, String fileName) async {
    if (_userId == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final token = await UserPreferences.getToken();
      print('=== [TATA-DEBUG] Token yang digunakan: $token ===');
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      print(
          'Uploading image (web): $fileName, size: ${imageBytes.length} bytes');

      final uri = Server.urlLaravel('chat/upload');
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

        print('=== [TATA-DEBUG] Mengirim pesan gambar ===');
        print('pesanan_uuid: ${_pesananUuid ?? widget.chatId}');
        print('file_url: $fileUrl');

        // Gunakan endpoint sendMessageByPesanan yang sesuai dengan Laravel
        final messageResponse = await _chatService.sendMessageByPesanan(
          _pesananUuid ?? widget.chatId,
          'Mengirim gambar',
          messageType: 'image',
          fileUrl: fileUrl,
        );

        print('=== [TATA-DEBUG] Response pesan gambar: $messageResponse ===');

        if (messageResponse != null && messageResponse['status'] == 'success') {
          print('Image message sent successfully');
          await _loadMessages();
          // Scroll ke bawah setelah mengirim gambar (web)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        } else {
          throw Exception('Gagal mengirim pesan gambar: ${messageResponse?['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Gagal upload gambar: ${responseData['message'] ?? 'Unknown error'}');
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
      final token = await UserPreferences.getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final uri = Server.urlLaravel('chat/upload');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = token;
      request.headers['Accept'] = 'application/json';

      // Pastikan imageFile adalah File (dart:io)
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      final responseData = jsonDecode(responseString);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        final fileUrl = responseData['data']['file_url'];

        print('=== [TATA-DEBUG] Mengirim pesan gambar ===');
        print('pesanan_uuid: ${_pesananUuid ?? widget.chatId}');
        print('file_url: $fileUrl');

        // Gunakan endpoint sendMessageByPesanan yang sesuai dengan Laravel
        final messageResponse = await _chatService.sendMessageByPesanan(
          _pesananUuid ?? widget.chatId,
          'Mengirim Gambar',
          messageType: 'image',
          fileUrl: fileUrl,
        );

        print('=== [TATA-DEBUG] Response pesan gambar: $messageResponse ===');

        if (messageResponse != null && messageResponse['status'] == 'success') {
          print('Image message sent successfully');
          await _loadMessages();
          // Scroll ke bawah setelah mengirim gambar (mobile)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        } else {
          throw Exception('Gagal mengirim pesan gambar: ${messageResponse?['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception(
            'Gagal upload gambar: ${responseData['message'] ?? 'Unknown error'}');
      }
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
        print('=== [TATA-DEBUG] Mengirim pesan text ===');
        print('pesanan_uuid: ${_pesananUuid ?? widget.chatId}');
        print('message: $messageText');

        final response = await _chatService.sendMessageByPesanan(
          _pesananUuid ?? widget.chatId,
          messageText,
        );

        print('=== [TATA-DEBUG] Response pesan text: $response ===');

        if (response != null && response['status'] == 'success') {
          print('Message sent successfully');
          await _loadMessages();
          // Mark pesan admin sebagai sudah dibaca setelah mengirim pesan baru
          await _markAdminMessagesAsRead();
          // Scroll ke bawah setelah mengirim pesan
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        } else {
          print(
              'Failed to send message: ${response?['message'] ?? 'Unknown error'}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Gagal mengirim pesan: ${response?['message'] ?? 'Unknown error'}')),
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
    // Jika _orderInfo adalah null, masih loading
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
    
    // Jika _orderInfo adalah map kosong, tidak ada data pesanan (direct chat)
    if (_orderInfo!.isEmpty) {
      return SizedBox.shrink(); // Tidak menampilkan apa-apa
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
                _buildInfoRow('Nomor Pemesanan',
                    '#${_orderInfo?['order_id'] ?? widget.chatId}'),
                _buildInfoRow('Jenis',
                    'Desain ${_orderInfo?['jasa']?['kategori'] ?? 'Logo'}'),
                _buildInfoRow('Paket',
                    '${_orderInfo?['paket']?['kelas_jasa'] ?? 'Premium'}'),
                _buildInfoRow('Metode Pembayaran',
                    '${_orderInfo?['metode_pembayaran'] ?? 'Virtual Account'}'),
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

  Widget _buildMessageBubble(
      Map<String, dynamic> message, bool isFromUser, bool isSystemMessage) {
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
                            Text('Gagal memuat gambar',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (message['message'] != null &&
                  message['message'].toString().isNotEmpty)
                const SizedBox(height: 8),
            ],
            if (message['message'] != null &&
                message['message'].toString().isNotEmpty)
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
                    _getReadStatusIcon(message),
                    size: 12,
                    color: _getReadStatusColor(message),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Update method _loadChatInfo untuk handle title yang lebih dinamis
  Future<void> _loadChatInfo() async {
    try {
      print('Loading chat info - _orderInfo: $_orderInfo');
      
      // Cek apakah ini chat dari pesanan atau direct chat
      if (_orderInfo != null && _orderInfo!.isNotEmpty) {
        // Chat dari pesanan
        final productType = _orderInfo?['jasa']?['kategori'] ?? 'Produk';
        if (mounted) {
          setState(() {
            _chatTitle = 'Chat - $productType';
          });
        }
        print('Set title to: Chat - $productType');
      } else {
        // Direct chat atau chat tanpa pesanan
        if (mounted) {
          setState(() {
            _chatTitle = 'Chat dengan Admin';
          });
        }
        print('Set title to: Chat dengan Admin');
      }
    } catch (e) {
      print('Error loading chat info: $e');
      // Fallback ke title default
      if (mounted) {
        setState(() {
          _chatTitle = 'Chat dengan Admin';
        });
      }
    }
  }
  
  // Fungsi untuk mendapatkan ikon read status
  IconData _getReadStatusIcon(Map<String, dynamic> message) {
    final isRead = message['is_read'];
    if (isRead == 1 || isRead == true) {
      return Icons.done_all; // Double check mark - sudah dibaca
    } else {
      return Icons.done; // Single check mark - terkirim tapi belum dibaca
    }
  }
  
  // Fungsi untuk mendapatkan warna read status
  Color _getReadStatusColor(Map<String, dynamic> message) {
    final isRead = message['is_read'];
    if (isRead == 1 || isRead == true) {
      return Colors.lightBlueAccent; // Biru terang untuk sudah dibaca
    } else {
      return Colors.white70; // Putih transparan untuk belum dibaca
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_chatTitle, // Gunakan variable yang dinamis
            style: TextStyle(color: CustomColors.whiteColor),
            ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
            color: CustomColors.whiteColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: CustomColors.primaryColor,
      ),
      body: Column(
        children: [
          _buildProductInfoBox(),
          Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _messagesController.stream,
                      initialData: _messages,
                      builder: (context, snapshot) {
                        final messages = snapshot.data ?? [];
                        if (messages.isEmpty) {
                          return const Center(child: Text('Belum ada pesan'));
                        }
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isFromUser = message['sender_type'] == 'user';
                            final isSystemMessage = message['sender_type'] == 'system';
                            return _buildMessageBubble(
                                message, isFromUser, isSystemMessage);
                          },
                        );
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
                  onPressed: _isUploadingImage
                      ? null
                      : () async {
                          // Panggil fungsi ChatService.sendMessage secara eksplisit
                          if (_messageController.text.trim().isNotEmpty &&
                              _userId != null) {
                            await _chatService.sendMessage(widget.chatId, _messageController.text.trim(), 'user');
                            _messageController.clear();
                            await _loadMessages();
                          }
                        },
                  icon: Icon(
                    Icons.send,
                    color: _isUploadingImage
                        ? Colors.grey
                        : CustomColors.primaryColor,
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
    const weekdays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    return weekdays[weekday - 1];
  }
}
