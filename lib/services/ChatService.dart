import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:TATA/helper/user_preferences.dart';
import 'package:TATA/models/ChatModel.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:TATA/sendApi/Server.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ✅ TAMBAHKAN METHOD BARU INI - Mengambil pesan dari Laravel API
  Future<Map<String, dynamic>?> getMessagesByOrderId(String orderReference) async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        debugPrint('No token available');
        return null;
      }
      
      debugPrint('Getting messages for order: $orderReference');
      debugPrint('Using token: ${token.substring(0, 20)}...');
      
      final response = await http.get(
        Server.urlLaravel('chat/messages/order/$orderReference'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('Get messages request timeout');
          return http.Response('{"error":"timeout"}', 408);
        },
      );
      
      debugPrint('Get messages response status: ${response.statusCode}');
      debugPrint('Get messages response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Messages loaded successfully: ${data['messages']?.length ?? 0} messages');
        return data;
      } else {
        debugPrint('Failed to get messages: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting messages: $e');
      return null;
    }
  }
  
  // ✅ UPDATE METHOD sendMessageByOrderId UNTUK SUPPORT IMAGE
  Future<Map<String, dynamic>?> sendMessageByOrderId(
    String orderReference, 
    String message, {
    String messageType = 'text',
    String? fileUrl,
  }) async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        debugPrint('No token available');
        return null;
      }
      
      debugPrint('Sending message to order: $orderReference');
      debugPrint('Message: $message');
      debugPrint('Message type: $messageType');
      debugPrint('File URL: $fileUrl');
      
      final response = await http.post(
        Server.urlLaravel('chat/send-by-pesanan'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode({
          'pesanan_uuid': orderReference,
          'message': message,
          'message_type': messageType,
          if (fileUrl != null) 'file_url': fileUrl,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('Send message request timeout');
          return http.Response('{"error":"timeout"}', 408);
        },
      );
      
      debugPrint('Send message response status: ${response.statusCode}');
      debugPrint('Send message response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Message sent successfully');
        return data;
      } else {
        debugPrint('Failed to send message: ${response.body}');
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }
  
  // ✅ TAMBAHKAN METHOD BARU INI - Mark messages as read via Laravel API
  Future<Map<String, dynamic>?> markMessagesAsReadByOrderId(String orderReference) async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        debugPrint('No token available');
        return null;
      }
      
      final response = await http.post(
        Server.urlLaravel('chat/mark-read'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode({
          'pesanan_uuid': orderReference,
        }),
      );
      
      if (response.statusCode == 200) {
        debugPrint('Messages marked as read successfully');
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to mark messages as read: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
      return null;
    }
  }
  
  // ✅ TAMBAHKAN METHOD BARU INI - Send message by pesanan UUID
  Future<Map<String, dynamic>?> sendMessageByPesanan(
    String pesananUuid,
    String message, {
    String messageType = 'text',
    String? fileUrl,
  }) async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        debugPrint('No token available');
        return null;
      }

      debugPrint('=== [TATA-DEBUG] sendMessageByPesanan ===');
      debugPrint('pesanan_uuid: $pesananUuid');
      debugPrint('message: $message');
      debugPrint('message_type: $messageType');
      debugPrint('file_url: $fileUrl');
      debugPrint('=== [TATA-DEBUG] Token: ${token.substring(0, 30)}... ===');
      
      final requestBody = <String, dynamic>{
        'pesanan_uuid': pesananUuid,
        'message': message,
        'message_type': messageType,
      };
      
      // Only add file_url if it's not null
      if (fileUrl != null && fileUrl.isNotEmpty) {
        requestBody['file_url'] = fileUrl;
      }
      
      debugPrint('=== [TATA-DEBUG] Request body: $requestBody ===');
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': token,
        'Accept': 'application/json',
      };
      debugPrint('=== [TATA-DEBUG] Headers: $headers ===');
      
      // Use the exact endpoint that exists in Laravel routes
      final url = Server.urlLaravel('chat/send-by-pesanan');
      debugPrint('=== [TATA-DEBUG] Final URL: $url ===');
      debugPrint('=== [TATA-DEBUG] URL toString(): ${url.toString()} ===');
      debugPrint('=== [TATA-DEBUG] Expected: https://tata-apps.mazkama.web.id/api/mobile/chat/send-by-pesanan ===');
      
      // Test with simpler send endpoint first
      try {
        final simpleUrl = Server.urlLaravel('chat/send');
        debugPrint('=== [TATA-DEBUG] Testing simpler endpoint: $simpleUrl ===');
        
        // Try the simple endpoint with a different request format
        final simpleRequestBody = <String, dynamic>{
          'message': message,
          'message_type': messageType,
          'chat_uuid': pesananUuid,  // Use chat_uuid instead of pesanan_uuid for this endpoint
        };
        
        if (fileUrl != null && fileUrl.isNotEmpty) {
          simpleRequestBody['file_url'] = fileUrl;
        }
        
        debugPrint('=== [TATA-DEBUG] Simple endpoint request body: $simpleRequestBody ===');
        
        final testResponse = await http.post(
          simpleUrl,
          headers: headers,
          body: jsonEncode(simpleRequestBody),
        ).timeout(const Duration(seconds: 10));
        
        debugPrint('=== [TATA-DEBUG] Simple send test status: ${testResponse.statusCode} ===');
        if (testResponse.body.length <= 200) {
          debugPrint('=== [TATA-DEBUG] Simple send test body: ${testResponse.body} ===');
        } else {
          debugPrint('=== [TATA-DEBUG] Simple send test body: ${testResponse.body.substring(0, 200)}... ===');
        }
        
        if (testResponse.statusCode == 200) {
          final data = jsonDecode(testResponse.body);
          debugPrint('=== [TATA-DEBUG] Simple send worked! Using that instead ===');
          return data;
        }
      } catch (e) {
        debugPrint('=== [TATA-DEBUG] Simple send test failed: $e ===');
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('Send message by pesanan request timeout');
          return http.Response('{"error":"timeout"}', 408);
        },
      );

      debugPrint('=== [TATA-DEBUG] Response status: ${response.statusCode} ===');
      debugPrint('=== [TATA-DEBUG] Response body: ${response.body} ===');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Message sent by pesanan successfully');
        return data;
      } else if (response.statusCode == 404) {
        // Try alternative request body format for send-by-pesanan
        debugPrint('=== [TATA-DEBUG] 404 error, trying alternative request format ===');
        
        final altRequestBody = <String, dynamic>{
          'pesanan_uuid': pesananUuid,  // Keep pesanan_uuid since the error said it's required
          'message': message,
          'message_type': messageType,  // Keep original message_type format
        };
        
        if (fileUrl != null && fileUrl.isNotEmpty) {
          altRequestBody['file_url'] = fileUrl;
        }
        
        debugPrint('=== [TATA-DEBUG] Alternative request body: $altRequestBody ===');
        
        final altResponse = await http.post(
          url,
          headers: headers,
          body: jsonEncode(altRequestBody),
        ).timeout(const Duration(seconds: 15));
        
        debugPrint('=== [TATA-DEBUG] Alternative response status: ${altResponse.statusCode} ===');
        if (altResponse.body.length <= 200) {
          debugPrint('=== [TATA-DEBUG] Alternative response body: ${altResponse.body} ===');
        } else {
          debugPrint('=== [TATA-DEBUG] Alternative response body: ${altResponse.body.substring(0, 200)}... ===');
        }
        
        if (altResponse.statusCode == 200) {
          final data = jsonDecode(altResponse.body);
          debugPrint('Message sent with alternative format successfully');
          return data;
        } else {
          debugPrint('Failed to send message by pesanan: ${altResponse.body}');
          return jsonDecode(altResponse.body);
        }
      } else {
        debugPrint('Failed to send message by pesanan: ${response.body}');
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error sending message by pesanan: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }
  
  // Stream untuk mendapatkan pesan real-time
  Stream<List<MessageModel>> getMessagesForChat(String chatId) {
    return _firestore
        .collection('messages')
        .where('chat_id', isEqualTo: chatId)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList();
        });
  }
  
  // Stream untuk mendapatkan daftar chat room
  Stream<List<ChatModel>> getChatRooms(String userId) {
    return _firestore
        .collection('chats')
        .where('user_id', isEqualTo: userId)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatModel.fromFirestore(doc))
              .toList();
        });
  }
  
  // Mengirim pesan
  Future<void> sendMessage(String chatId, String content, String senderType) async {
    try {
      // Ambil ID pengguna dari UserPreferences dengan handling yang aman
      final userData = await UserPreferences.getUser();
      
      String? userId;
      
      if (userData != null) {
        // Handle berbagai struktur data user
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
      }
      
      if (userId == null) {
        throw Exception('User ID not found');
      }
      
      // Buat data pesan
      final message = {
        'chat_id': chatId,
        'content': content,
        'sender_type': senderType,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      };
      
      // 1. Tambahkan ke Firestore
      await _firestore.collection('messages').add(message);
      
      // 2. Update chat room dengan pesan terakhir di Firestore
      final chatDoc = _firestore.collection('chats').doc(chatId);
      final chatSnapshot = await chatDoc.get();

      if (!chatSnapshot.exists) {
        await chatDoc.set({
          'last_message': content,
          'updated_at': FieldValue.serverTimestamp(),
          'unread_count': 1,
          // tambahkan field lain yang diperlukan
        });
      } else {
        await chatDoc.update({
          'last_message': content,
          'updated_at': FieldValue.serverTimestamp(),
          'unread_count': FieldValue.increment(1),
        });
      }
      
      // 3. ✅ SINKRONISASI KE LARAVEL DATABASE
      await _syncMessageToLaravel(chatId, content, senderType);
      
      // 4. Kirim notifikasi ke backend untuk diteruskan ke FCM
      await _sendMessageNotification(chatId, content);
      
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }
  
  // ✅ SINKRONISASI KE LARAVEL DATABASE
  Future<void> _syncMessageToLaravel(String chatId, String content, String senderType) async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        debugPrint('No token available for sync');
        return;
      }
      
      final response = await http.post(
        Server.urlLaravel('chat/sync-message'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode({
          'chat_uuid': chatId,
          'message': content,
          'sender_type': senderType,
          'message_type': 'text',
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Sync message request timeout');
          return http.Response('{"error":"timeout"}', 408);
        },
      );
      
      debugPrint('Sync message response status: ${response.statusCode}');
      debugPrint('Sync message response body: ${response.body}');
      
      if (response.statusCode == 200) {
        debugPrint('Message synced to Laravel successfully');
      } else {
        debugPrint('Failed to sync message to Laravel: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error syncing message to Laravel: $e');
      // Jangan throw error, karena pesan tetap harus terkirim meskipun sync gagal
    }
  }
  
  // Membuat chat room baru
  Future<String> createChatRoom(String userId, String adminId, {String? orderReference}) async {
    try {
      final chatData = {
        'user_id': userId,
        'admin_id': adminId,
        'order_reference': orderReference,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'last_message': 'Chat dibuat',
        'unread_count': 0,
      };
      
      final docRef = await _firestore.collection('chats').add(chatData);
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating chat room: $e');
      throw e;
    }
  }
  
  // Menandai pesan sebagai sudah dibaca
  Future<void> markMessagesAsRead(String chatId, [String? currentUserType]) async {
    try {
      // If currentUserType is provided, use Firebase method
      if (currentUserType != null) {
        final batch = _firestore.batch();
        
        // Ambil semua pesan yang belum dibaca dan bukan dari pengguna saat ini
        final snapshot = await _firestore
            .collection('messages')
            .where('chat_id', isEqualTo: chatId)
            .where('is_read', isEqualTo: false)
            .where('sender_type', isNotEqualTo: currentUserType)
            .get();
        
        for (var doc in snapshot.docs) {
          batch.update(doc.reference, {'is_read': true});
        }
        
        // Reset unread count di chat room
        batch.update(_firestore.collection('chats').doc(chatId), {'unread_count': 0});
        
        await batch.commit();
      } else {
        // Use Laravel API method
        await markMessagesAsReadByOrderId(chatId);
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
      rethrow;
    }
  }
  
  // Mengirim notifikasi pesan ke backend untuk diteruskan ke FCM
  Future<void> _sendMessageNotification(String chatId, String message) async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        debugPrint('No token available for notification');
        return;
      }
      
      final response = await http.post(
        Server.urlLaravel('chat/send-notification'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode({
          'chat_id': chatId,
          'message': message,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Notification request timeout');
          return http.Response('{"error":"timeout"}', 408);
        },
      );
      
      debugPrint('Notification response status: ${response.statusCode}');
      debugPrint('Notification response body: ${response.body}');
      
      if (response.statusCode == 200) {
        debugPrint('Notification sent successfully');
      } else {
        debugPrint('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
      // Jangan throw error, karena pesan tetap harus terkirim meskipun notifikasi gagal
    }
  }
  
  // Mendapatkan atau membuat chat untuk pesanan
  Future<String> getOrCreateChatForOrder(String orderReference) async {
    try {
      final userData = await UserPreferences.getUser();
      
      String? userId;
      
      if (userData != null) {
        print('ChatService userData structure: $userData');
        
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
      }
      
      if (userId == null) {
        throw Exception('User not authenticated or invalid user data structure');
      }
      
      print('ChatService extracted userId: $userId');
      
      final token = await UserPreferences.getToken();
      
      print('Creating chat for order: $orderReference');
      print('Using token: ${token?.substring(0, 20)}...');
      
      final response = await http.post(
        Server.urlLaravel('chat/create-for-order'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': token!,
        },
        body: jsonEncode({
          'order_id': orderReference,
          'pesanan_uuid': orderReference,
        }),
      );
      
      print('Create chat response status: ${response.statusCode}');
      print('Create chat response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final chatUuid = data['data']['chat_id'] ?? data['data']['uuid'];
          
          print('Chat ID received: $chatUuid');
          
          return orderReference;
        }
      }
      
      throw Exception('Failed to create chat for order: ${response.body}');
    } catch (e) {
      debugPrint('Error getting or creating chat for order: $e');
      throw e;
    }
  }
} 