import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String text;
  final String sender;
  final String timestamp;
  final bool isRead;
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? json['uuid'] ?? '',
      text: json['message'] ?? json['text'] ?? json['content'] ?? '',
      sender: json['sender_type'] ?? json['sender'] ?? '',
      timestamp: json['created_at'] ?? json['timestamp'] ?? DateTime.now().toIso8601String(),
      isRead: json['is_read'] ?? json['read'] ?? false,
      imageUrl: json['image_url'] ?? json['file_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sender': sender,
      'timestamp': timestamp,
      'isRead': isRead,
      'imageUrl': imageUrl,
    };
  }
}

class ProductChat {
  final String id;
  final String title;
  final String category;
  final String price;
  final String imageUrl;
  final String packageType;

  ProductChat({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.packageType,
  });

  factory ProductChat.fromJson(Map<String, dynamic> json) {
    return ProductChat(
      id: json['id_jasa'] ?? json['id'] ?? '',
      title: json['kategori'] ?? json['title'] ?? '',
      category: json['jenis_pesanan'] ?? json['category'] ?? '',
      price: json['harga_paket_jasa']?.toString() ?? json['price'] ?? '',
      imageUrl: json['gambar'] ?? json['imageUrl'] ?? '',
      packageType: json['kelas_jasa'] ?? json['packageType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'packageType': packageType,
    };
  }
}

class ChatRoom {
  final String id;
  final String pesananId;
  final ProductChat product;
  final String lastMessage;
  final String lastSender;
  final String lastTimestamp;
  final int unreadCount;

  ChatRoom({
    required this.id,
    required this.pesananId,
    required this.product,
    required this.lastMessage,
    required this.lastSender,
    required this.lastTimestamp,
    this.unreadCount = 0,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] ?? json['uuid'] ?? '',
      pesananId: json['pesanan_uuid'] ?? json['pesanan_id'] ?? '',
      product: ProductChat.fromJson(json['product'] ?? {}),
      lastMessage: json['last_message'] ?? '',
      lastSender: json['last_sender'] ?? '',
      lastTimestamp: json['updated_at'] ?? DateTime.now().toIso8601String(),
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

class ChatModel {
  final String id;
  final String userId;
  final String adminId;
  final String? orderReference;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String lastMessage;
  final int unreadCount;
  
  ChatModel({
    required this.id,
    required this.userId,
    required this.adminId,
    this.orderReference,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage = '',
    this.unreadCount = 0,
  });
  
  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      adminId: data['admin_id'] ?? '',
      orderReference: data['order_reference'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['last_message'] ?? '',
      unreadCount: data['unread_count'] ?? 0,
    );
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    String parseToString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    int parseToInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          return 0;
        }
      }
      return 0;
    }

    return ChatModel(
      id: parseToString(json['uuid'] ?? json['id']),
      userId: parseToString(json['user_id']),
      adminId: parseToString(json['admin_id']),
      orderReference: json['pesanan_uuid']?.toString() ?? json['order_reference']?.toString(),
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
      lastMessage: json['last_message']?.toString() ?? '',
      unreadCount: parseToInt(json['unread_count']),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'admin_id': adminId,
      'order_reference': orderReference,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'last_message': lastMessage,
      'unread_count': unreadCount,
    };
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final String content;
  final String senderType; // 'user' or 'admin'
  final bool isRead;
  final DateTime createdAt;
  final String? fileUrl;
  final String? messageType;
  
  MessageModel({
    required this.id,
    required this.chatId,
    required this.content,
    required this.senderType,
    this.isRead = false,
    required this.createdAt,
    this.fileUrl,
    this.messageType = 'text',
  });
  
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: data['chat_id'] ?? '',
      content: data['content'] ?? '',
      senderType: data['sender_type'] ?? 'user',
      isRead: data['is_read'] ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fileUrl: data['file_url'],
      messageType: data['message_type'] ?? 'text',
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return MessageModel(
      id: json['uuid'] ?? json['id'] ?? '',
      chatId: json['chat_uuid'] ?? json['chat_id'] ?? '',
      content: json['message'] ?? json['content'] ?? '',
      senderType: json['sender_type'] ?? 'user',
      isRead: json['is_read'] ?? false,
      createdAt: parseDateTime(json['created_at']),
      fileUrl: json['file_url'],
      messageType: json['message_type'] ?? 'text',
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'chat_id': chatId,
      'content': content,
      'sender_type': senderType,
      'is_read': isRead,
      'created_at': Timestamp.fromDate(createdAt),
      'file_url': fileUrl,
      'message_type': messageType,
    };
  }
} 