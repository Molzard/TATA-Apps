import 'package:TATA/helper/fcm_helper.dart';
import 'package:TATA/helper/user_preferences.dart';
import 'package:TATA/menu/AkunPage.dart';
import 'package:TATA/menu/ChatPage.dart';
import 'package:TATA/menu/HomePage.dart';
import 'package:TATA/menu/PemesananPage.dart';
import 'package:TATA/splashscreen.dart';
import 'package:TATA/BeforeLogin/page_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:TATA/src/bottomnav.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

// Key global untuk navigasi di seluruh aplikasi
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Preload asset manifest to avoid "AssetManifest.bin.json" error
  await _preloadAssets();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  FirebaseAuth.instance.setLanguageCode('id');
  
  final fcmHelper = FCMHelper();
  await fcmHelper.initialize();

  if (kIsWeb) {
    await fcmHelper.setupWebFCM();
  }
  
  await UserPreferences.init();
  
  runApp(const MyApp());
}

// Function to preload assets
Future<void> _preloadAssets() async {
  try {
    // Force load the asset manifest
    await rootBundle.loadString('AssetManifest.json');
    debugPrint('Asset manifest loaded successfully');
  } catch (e) {
    debugPrint('Error loading asset manifest: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      routes: {
        '/login': (context) => page_login(),
        '/home': (context) => MainPage(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (context) => page_login());
          case '/home':
            return MaterialPageRoute(builder: (context) => MainPage());
          default:
            return MaterialPageRoute(builder: (context) => SplashScreen());
        }
      },
    );
  }
}

class MainPage extends StatefulWidget {
  final int initialIndex;

  const MainPage({super.key, this.initialIndex = 0});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _currentIndex;
  String? id_user;
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    getIdUser();
  }

  Future<void> getIdUser() async {
    try {
      final data = await UserPreferences.getUser();
      print("ALLDATAA : $data");
      
      if (data == null) {
        print("User data is null, redirecting to login");
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/login', 
          (route) => false
        );
        return;
      }
      
      setState(() {
        if (data.containsKey('user') && data['user'] != null) {
          id_user = data['user']['id'] ?? '';
        } else if (data.containsKey('data') && 
                   data['data'] != null && 
                   data['data'].containsKey('user') &&
                   data['data']['user'] != null) {
          id_user = data['data']['user']['id'] ?? '';
        } else {
          id_user = 'unknown';
          print("User ID not found in data structure");
        }
        
        _pages = [
          const HomePage(),
          PemesananPage(),
          ChatPage(),
          Akunpage(),
        ];
      });
    } catch (e) {
      print("Error getting user data: $e");
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/login', 
        (route) => false
      );
    }
  }

  void _onItemTapped(int index) {
    // Jika user ingin mengakses chat (index 2), cek autentikasi dulu
    if (index == 2) {
      _checkAuthenticationForChat(index);
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Future<void> _checkAuthenticationForChat(int index) async {
    try {
      final userData = await UserPreferences.getUser();
      
      if (userData == null) {
        _showLoginRequired();
        return;
      }
      
      // Cek apakah bisa extract user ID dengan aman
      String? userId;
      
      if (userData.containsKey('data') && 
          userData['data'] != null && 
          userData['data'].containsKey('user') && 
          userData['data']['user'] != null) {
        final user = userData['data']['user'];
        if (user is Map && user.containsKey('id')) {
          userId = user['id'].toString();
        }
      } else if (userData.containsKey('user') && userData['user'] != null) {
        final user = userData['user'];
        if (user is Map && user.containsKey('id')) {
          userId = user['id'].toString();
        }
      } else if (userData.containsKey('id')) {
        userId = userData['id'].toString();
      }
      
      if (userId == null || userId.isEmpty) {
        print('Could not extract user ID for chat access');
        _showLoginRequired();
        return;
      }
      
      // Jika berhasil extract user ID, lanjutkan ke chat
      setState(() {
        _currentIndex = index;
      });
      
    } catch (e) {
      print('Error checking authentication for chat: $e');
      _showLoginRequired();
    }
  }

  void _showLoginRequired() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login Diperlukan'),
        content: Text('Anda harus login untuk mengakses fitur chat'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/login', 
                (route) => false
              );
            },
            child: Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (id_user == null || _pages.isEmpty) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Bottomnav(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
