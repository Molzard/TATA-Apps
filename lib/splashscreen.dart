import 'package:TATA/BeforeLogin/page_login.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.primaryColor,
      body: AnimatedSplashScreen(
          centered: true,
          duration: 3000,
          splash: Image.asset(Server.UrlGambar("logotext.png")),
          nextScreen: page_login(),
          // nextScreen: page_login.id_user.isEmpty ? SliderP() : utama(),
          splashIconSize: 180,
          splashTransition: SplashTransition.sizeTransition,
          backgroundColor: CustomColors.primaryColor),
    );
  }
}
