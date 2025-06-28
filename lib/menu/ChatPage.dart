import 'package:flutter/material.dart';
import 'package:TATA/menu/ChatListScreen.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    // Menggunakan ChatListScreen yang terhubung dengan Firestore
    return const ChatListScreen();
  }
}
