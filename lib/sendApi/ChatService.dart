import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:TATA/helper/user_preferences.dart';
import 'package:TATA/models/ChatModel.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:http/http.dart' as http;

class ChatService {
  // Mengambil daftar chat
  static Future<List<ChatModel>> getChatList() async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http.get(
        Server.urlLaravel('mobile/chat/list'),
        headers: {
          'Accept': 'application/json',
          'Authorization': token,
        },
      );
      
      debugPrint('Get chat list status: ${response.statusCode}');
      debugPrint('Get chat list response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Parsed data: $data');
        
        final List<dynamic> chats = data['data'];
        debugPrint('Chats array: $chats');
        
        List<ChatModel> chatModels = [];
        for (int i = 0; i < chats.length; i++) {
          try {
            debugPrint('Processing chat $i: ${chats[i]}');
            final chatModel = ChatModel.fromJson(chats[i]);
            chatModels.add(chatModel);
            debugPrint('Chat $i converted successfully');
          } catch (e) {
            debugPrint('Error converting chat $i: $e');
            debugPrint('Chat $i data types:');
            final chat = chats[i];
            chat.forEach((key, value) {
              debugPrint('  $key: ${value.runtimeType} = $value');
            });
            continue;
          }
        }
        
        return chatModels;
      } else if (response.statusCode == 401) {
        // Token tidak valid, hapus token
        await UserPreferences.clearToken();
        throw Exception('Sesi telah berakhir, silahkan login kembali');
      } else {
        throw Exception('Gagal mengambil daftar chat: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting chat list: $e');
      rethrow;
    }
  }

  // Mengambil detail chat berdasarkan ID
  static Future<Map<String, dynamic>> getChatDetail(String chatId) async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http.get(
        Server.urlLaravel('mobile/chat/messages?chat_uuid=$chatId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': token,
        },
      );
      
      debugPrint('Get chat detail status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        // Token tidak valid, hapus token
        await UserPreferences.clearToken();
        throw Exception('Sesi telah berakhir, silahkan login kembali');
      } else {
        throw Exception('Gagal mengambil detail chat: ${response.body}');
        }
    } catch (e) {
      debugPrint('Error getting chat detail: $e');
      rethrow;
    }
  }

  // Mengirim pesan
  static Future<Map<String, dynamic>> sendMessage(String chatId, String message) async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http.post(
        Server.urlLaravel('mobile/chat/send'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode({
          'chat_uuid': chatId,
          'message': message,
          'message_type': 'text',
        }),
      );
      
      debugPrint('Send message status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        // Token tidak valid, hapus token
        await UserPreferences.clearToken();
        throw Exception('Sesi telah berakhir, silahkan login kembali');
      } else {
        throw Exception('Gagal mengirim pesan: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Membuat chat untuk pesanan
  static Future<Map<String, dynamic>> createChatForOrder(String pesananUuid) async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http.post(
        Server.urlLaravel('mobile/chat/create-for-order'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode({
          'order_id': pesananUuid,
          'pesanan_uuid': pesananUuid,
        }),
      );
      
      debugPrint('Create chat for order status: ${response.statusCode}');
      debugPrint('Create chat for order response: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        // Token tidak valid, hapus token
        await UserPreferences.clearToken();
        throw Exception('Sesi telah berakhir, silahkan login kembali');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Gagal membuat chat: ${errorData['message'] ?? response.body}');
      }
    } catch (e) {
      debugPrint('Error creating chat for order: $e');
      rethrow;
    }
  }
  
  // Menandai pesan sebagai sudah dibaca
  static Future<Map<String, dynamic>> markMessagesAsRead(String chatId) async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }
      
      final response = await http.post(
        Server.urlLaravel('mobile/chat/mark-read'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode({
          'chat_uuid': chatId,
        }),
      );
      
      debugPrint('Mark messages as read status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        // Token tidak valid, hapus token
        await UserPreferences.clearToken();
        throw Exception('Sesi telah berakhir, silahkan login kembali');
      } else {
        throw Exception('Gagal menandai pesan sebagai sudah dibaca: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
      rethrow;
    }
  }

  // Menandai pesan sebagai sudah dibaca berdasarkan ID order
  static Future<Map<String, dynamic>?> markMessagesAsReadByOrderId(String orderId) async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        debugPrint('No token available');
        return null;
      }
      
      debugPrint('Marking messages as read for order: $orderId');
      
      final response = await http.post(
        Server.urlLaravel('mobile/chat/mark-read'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode({
          'order_id': orderId,
        }),
      );
      
      debugPrint('Mark messages as read status: ${response.statusCode}');
      debugPrint('Mark messages as read response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        // Token tidak valid, hapus token
        await UserPreferences.clearToken();
        throw Exception('Sesi telah berakhir, silahkan login kembali');
      } else {
        throw Exception('Gagal menandai pesan sebagai sudah dibaca: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error marking messages as read by order ID: $e');
      return null;
    }
  }

  // Mengambil pesan berdasarkan ID pesanan
  static Future<Map<String, dynamic>> getMessagesByPesanan(String pesananUuid) async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }
      
      final response = await http.get(
        Server.urlLaravel('mobile/chat/messages-by-pesanan/$pesananUuid'),
        headers: {
          'Accept': 'application/json',
          'Authorization': token,
        },
      );
      
      debugPrint('Get messages by pesanan status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        // Token tidak valid, hapus token
        await UserPreferences.clearToken();
        throw Exception('Sesi telah berakhir, silahkan login kembali');
      } else {
        throw Exception('Gagal mengambil pesan: ${response.body}');
        }
    } catch (e) {
      debugPrint('Error getting messages by pesanan: $e');
      rethrow;
    }
  }
  
  // Mengambil pesan berdasarkan ID order
  static Future<Map<String, dynamic>?> getMessagesByOrderId(String orderReference) async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        debugPrint('No token available');
        return null;
      }
      
      debugPrint('Getting messages for order: $orderReference');
      debugPrint('Using token: ${token.substring(0, 20)}...');
      
      final response = await http.get(
        Server.urlLaravel('mobile/chat/messages/order/$orderReference'),
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
        return data;
      } else if (response.statusCode == 401) {
        // Token tidak valid, hapus token
        await UserPreferences.clearToken();
        throw Exception('Sesi telah berakhir, silahkan login kembali');
      } else {
        throw Exception('Failed to get messages: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      return null;
    }
  }

  // Membuat chat langsung dengan admin dengan konteks produk
  static Future<Map<String, dynamic>> createDirectChatWithContext(Map<String, dynamic> productContext) async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      debugPrint('Creating direct chat with product context: $productContext');

      // Debug URL
      final url = Server.urlLaravel('mobile/chat/create-direct');
      debugPrint('API URL: $url');
      debugPrint('Token: ${token.substring(0, math.min(20, token.length))}...');

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode({
          'context_type': 'product_info',
          'context_data': productContext,
          'initial_message': 'Halo, saya tertarik dengan produk ini',
        }),
      );
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Failed to create chat: ${response.statusCode}'
        };
      }
    } catch (e) {
      debugPrint('Error creating direct chat: $e');
      return {
        'status': 'error',
        'message': 'Error creating direct chat: $e'
      };
    }
  }

  // Metode untuk menguji koneksi API chat secara langsung
  static Future<Map<String, dynamic>> testChatApi() async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        return {
          'status': 'error',
          'message': 'Token tidak ditemukan'
        };
      }

      // Test direct chat endpoint
      final directChatResponse = await http.get(
        Server.urlLaravel('debug/test-direct-chat'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );
      
      // Test routes endpoint
      final routesResponse = await http.get(
        Server.urlLaravel('debug/routes'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );
      
      return {
        'status': 'success',
        'direct_chat_test': {
          'status_code': directChatResponse.statusCode,
          'body': directChatResponse.body.length > 1000 
              ? directChatResponse.body.substring(0, 1000) + '...' 
              : directChatResponse.body
        },
        'routes_test': {
          'status_code': routesResponse.statusCode,
          'body': routesResponse.body.length > 1000 
              ? routesResponse.body.substring(0, 1000) + '...' 
              : routesResponse.body
        }
      };
    } catch (e) {
      debugPrint('Error testing chat API: $e');
      return {
        'status': 'error',
        'message': 'Error testing chat API: $e'
      };
    }
  }
} 