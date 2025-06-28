import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:TATA/helper/user_preferences.dart';
import 'package:TATA/main.dart';
import 'package:TATA/menu/ChatPage.dart';
import 'package:TATA/menu/ChatDetailScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/firebase_options.dart';
import 'dart:math' as Math;
import 'package:TATA/helper/auth_helper.dart';

// Background handler untuk FCM (harus di luar class, top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling a background message: ${message.messageId}');
} 

class FCMHelper {
  static final FCMHelper _instance = FCMHelper._internal();
  factory FCMHelper() => _instance;

  FCMHelper._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Stream controller untuk broadcast pesan chat
  final StreamController<Map<String, dynamic>> _chatMessageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Getter untuk stream
  Stream<Map<String, dynamic>> get chatMessageStream => _chatMessageController.stream;

  // Flag untuk menghindari multiple initialization
  bool _initialized = false;
  
  // Method untuk menginisialisasi FCM
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Pastikan Firebase sudah diinisialisasi
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      
      // Skip untuk web dalam mode development
      if (kIsWeb && !kReleaseMode) {
        debugPrint('Skipping FCM initialization in web development mode');
        _initialized = true;
        return;
      }
      
      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: true,
        sound: true,
      );
      
      debugPrint('FCM notification permissions: ${settings.authorizationStatus}');
      
      // Setup foreground notification presentation
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      
      // Initialize local notifications for Android
      if (!kIsWeb && Platform.isAndroid) {
        await _setupLocalNotifications();
      }
      
      // Listen for token refreshes
      _messaging.onTokenRefresh.listen((token) {
        _updateFCMToken(token);
      });
      
      // Get current token (skip for web in development mode)
      if (!kIsWeb || kReleaseMode) {
    try {
          String? token;
          if (kIsWeb) {
            // Untuk web, gunakan VAPID key
            token = await _messaging.getToken(
              vapidKey: 'BJ7Nle1g-lfmypL4jngAW-8cDnnyq9JO2HtID_WVviL-lf8HRCQ8leegxkhKqQgLpZ3xa5vZnLoeHB_O4KKg1TI',
            );
            } else {
            // Untuk mobile
            token = await _messaging.getToken();
          }
          
          if (token != null) {
            await _updateFCMToken(token);
            }
          } catch (e) {
          debugPrint('Error getting FCM token: $e');
          // Lanjutkan inisialisasi meskipun gagal mendapatkan token
        }
      }
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
      // Tetapkan initialized ke true untuk menghindari percobaan inisialisasi berulang
      _initialized = true;
    }
  }
  
  // Setup local notifications for Android
  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null) {
          final data = json.decode(payload);
          _navigateToMessage(data);
  }
      },
    );
    
    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  
  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');
    
    if (message.notification != null) {
      debugPrint('Message notification: ${message.notification!.title} - ${message.notification!.body}');
    
      // Show local notification on Android
      if (!kIsWeb && Platform.isAndroid) {
        _localNotifications.show(
          message.hashCode,
          message.notification!.title,
          message.notification!.body,
        NotificationDetails(
            android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
              channelDescription: 'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
              importance: Importance.high,
            priority: Priority.high,
          ),
        ),
          payload: json.encode(message.data),
      );
    }
    }
  }

  // Handle notification taps
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped!');
    debugPrint('Message data: ${message.data}');
    
    if (message.data.isNotEmpty) {
      _navigateToMessage(message.data);
    }
  }

  // Navigate to the appropriate screen based on the notification data
  void _navigateToMessage(Map<String, dynamic> data) {
    final chatId = data['chat_id'];
    final orderId = data['order_id'];
    
    if (chatId != null && chatId.isNotEmpty) {
      // Navigate to chat detail screen
            navigatorKey.currentState?.push(
              MaterialPageRoute(
          builder: (context) => ChatDetailScreen(chatId: chatId),
              ),
            );
    } else if (orderId != null && orderId.isNotEmpty) {
      // Navigate to order detail screen
      // You'll need to implement this navigation
      debugPrint('Navigate to order $orderId');
    }
  }
  
  // Update FCM token in backend
  Future<void> _updateFCMToken(String token) async {
    try {
      debugPrint('FCM Token: $token');
      
      // Store locally
      await UserPreferences.setFCMToken(token);
      
      // Skip untuk web dalam mode development
      if (kIsWeb && !kReleaseMode) {
        debugPrint('Skipping FCM token update to backend in web development mode');
        return;
      }
      
      // Cek apakah user sudah login
      final authHelper = AuthHelper();
      final isAuthenticated = await authHelper.isAuthenticated();
      
      if (isAuthenticated) {
        // Gunakan AuthHelper untuk permintaan API
        final response = await authHelper.authenticatedRequest(
          'mobile/user/profile/update',
          method: 'POST',
          body: jsonEncode({'fcm_token': token}),
        );
        
        if (response.statusCode != 200) {
          debugPrint('Failed to update FCM token: ${response.statusCode} - ${response.body}');
        } else {
          debugPrint('FCM token updated successfully');
        }
      } else {
        debugPrint('User not authenticated, skipping FCM token update to backend');
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  // Metode untuk membuat token FCM di platform web
  Future<void> setupWebFCM() async {
    if (kIsWeb) {
      try {
        // Skip untuk web dalam mode development
        if (!kReleaseMode) {
          debugPrint('Skipping web FCM setup in development mode');
          return;
        }
        
        // Minta izin notifikasi di web
        await _messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        
        // Dapatkan token FCM untuk web
        String? token = await _messaging.getToken(
          vapidKey: 'BJ7Nle1g-lfmypL4jngAW-8cDnnyq9JO2HtID_WVviL-lf8HRCQ8leegxkhKqQgLpZ3xa5vZnLoeHB_O4KKg1TI',
        );
        
        debugPrint('Web FCM Token: $token');
        if (token != null) {
          await _updateFCMToken(token);
              }
            } catch (e) {
        debugPrint('Error setting up web FCM: $e');
            }
          }
        }
        
  // Untuk digunakan di navigasi
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
          
  // Alias untuk _updateFCMToken agar kompatibel dengan kode yang sudah ada
  Future<void> updateFCMToken() async {
    // Skip untuk web dalam mode development
    if (kIsWeb && !kReleaseMode) {
      debugPrint('Skipping FCM token update in web development mode');
      return;
    }
    
    try {
      String? token;
      if (kIsWeb) {
        // Untuk web, gunakan VAPID key
        token = await _messaging.getToken(
          vapidKey: 'BJ7Nle1g-lfmypL4jngAW-8cDnnyq9JO2HtID_WVviL-lf8HRCQ8leegxkhKqQgLpZ3xa5vZnLoeHB_O4KKg1TI',
        );
      } else {
        // Untuk mobile
        token = await _messaging.getToken();
      }
      
      if (token != null) {
        await _updateFCMToken(token);
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }
} 