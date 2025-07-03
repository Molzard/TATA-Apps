import 'package:TATA/BeforeLogin/page_login.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:TATA/helper/user_preferences.dart';
import 'package:TATA/main.dart';
import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Widget? _nextScreen;

  @override
  void initState() {
    super.initState();
    _determineNextScreen();
  }

  Future<void> _determineNextScreen() async {
    try {
      final userData = await UserPreferences.getUser();
      final token = await UserPreferences.getToken();
      
      // Cek apakah user sudah login dan token masih valid
      if (userData != null && token != null && token.isNotEmpty) {
        // User sudah login, set next screen ke MainPage
        setState(() {
          _nextScreen = MainPage();
        });
      } else {
        // User belum login, set next screen ke login
        setState(() {
          _nextScreen = page_login();
        });
      }
    } catch (e) {
      print('Error checking auth status: $e');
      // Jika error, arahkan ke login
      setState(() {
        _nextScreen = page_login();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.primaryColor,
      body: _nextScreen == null
          ? Center(
              child: Image.asset(
                Server.UrlGambar("logotext.png"),
                width: 180,
              ),
            )
          : AnimatedSplashScreen(
              centered: true,
              duration: 3000,
              splash: Image.asset(Server.UrlGambar("logotext.png")),
              nextScreen: _nextScreen!,
              splashIconSize: 180,
              splashTransition: SplashTransition.sizeTransition,
              backgroundColor: CustomColors.primaryColor,
            ),
    );
  }
}
