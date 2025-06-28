import 'dart:convert';

// import 'package:TATA/pageSebelumLogin/page_lupa_katasandi.dart';
import 'package:TATA/BeforeLogin/logingoogle.dart';
import 'package:TATA/BeforeLogin/lupapassword1Pages.dart';
import 'package:TATA/BeforeLogin/register1Pages.dart';
import 'package:TATA/helper/user_preferences.dart';
import 'package:TATA/main.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/sendApi/userApi.dart';
import 'package:TATA/services/AuthService.dart';
import 'package:TATA/src/CustomWidget.dart';
// import 'package:TATA/src/Server.dart';
import 'package:TATA/src/pageTransition.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:TATA/src/CustomButton.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:TATA/src/CustomText.dart';
// import 'package:TATA/navigation/utama.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as Math;

// import 'package:google_sign_in/google_sign_in.dart';

import 'package:http/http.dart' as http;
import 'package:TATA/helper/fcm_helper.dart';

class page_login extends StatefulWidget {
  static String id_user = "";

  const page_login({super.key});
  @override
  State<page_login> createState() => _page_login();
}

class _page_login extends State<page_login> {
  final AuthService _authService = AuthService();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  
  Future<void> _ceklogin() async {
    try {
      print("Login pressed");
      CustomWidget.NotifLoading(context);
      
      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
        setState(() {
          Navigator.pop(context);
          isWrong = true;
          sizeerror = 14;
          errorText = "Masukkan Email dan Password\ndengan benar!";
        });
        return;
      }
      
      try {
        // Login menggunakan sistem hybrid
        final result = await _authService.signInWithEmailPasswordHybrid(
          emailController.text,
          passwordController.text,
        );
        
        Navigator.pop(context); // Tutup dialog loading
        
        if (result['status'] == 'success') {
          // Login berhasil
          isWrong = false;
          
          // Tampilkan pesan sesuai metode yang berhasil
          String successMessage = result['message'] ?? 'Login berhasil';
          if (result.containsKey('warning')) {
            print('Warning: ${result['warning']}');
          }
          
          final userData = await UserPreferences.getUser();
          print('Login method: ${result['method']}');
          print('Stored user data: ${userData != null ? 'Data ada' : 'Data tidak ada'}');
          
          // Navigasi ke halaman utama
          CustomWidget.NotifBerhasilLogin(context, MainPage());
          
          // Set user ID
          if (userData != null) {
            if (userData['data'] != null && userData['data']['user'] != null) {
              page_login.id_user = userData['data']['user']['id'].toString();
              print("id user = ${userData['data']['user']['id']}");
            } else if (userData['user'] != null) {
              page_login.id_user = userData['user']['id'].toString();
              print("id user = ${userData['user']['id']}");
            }
          }
          
          // Tampilkan notifikasi jika ada warning
          if (result.containsKey('warning')) {
            Future.delayed(Duration(seconds: 2), () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Info: ${result['warning']}'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            });
          }
        } else {
          // Login gagal
          setState(() {
            isWrong = true;
            errorText = result['message'] ?? 'Login gagal';
            sizeerror = 14;
          });
          
          // Debug info
          if (result.containsKey('firebase_error')) {
            print('Firebase error: ${result['firebase_error']}');
          }
          if (result.containsKey('laravel_error')) {
            print('Laravel error: ${result['laravel_error']}');
          }
        }
      } catch (e) {
        Navigator.pop(context);
        setState(() {
          isWrong = true;
          errorText = "Gagal login: $e";
          sizeerror = 14;
        });
        print("Login error: $e");
      }
    } catch (e) {
      Navigator.pop(context);
      CustomWidget.NotifGagal(context);
      print("General error: $e");
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      CustomWidget.NotifLoading(context);
      
      try {
        // Google login menggunakan sistem hybrid
        final result = await _authService.signInWithGoogleHybrid();
        
        Navigator.pop(context); // Tutup dialog loading
        
        if (result['status'] == 'success') {
          // Login berhasil
          final userData = await UserPreferences.getUser();
          print('Google login method: ${result['method']}');
          print('Google login user data: $userData');
          
          if (userData != null) {
            // Set user ID
            if (userData['data'] != null && userData['data']['user'] != null) {
              page_login.id_user = userData['data']['user']['id'].toString();
            } else if (userData['user'] != null) {
              page_login.id_user = userData['user']['id'].toString();
            }
            
            print("Google login berhasil, id user = ${page_login.id_user}");
            
            // Navigasi ke halaman utama
            CustomWidget.NotifBerhasilLogin(context, MainPage());
            
            // Tampilkan warning jika ada
            if (result.containsKey('warning')) {
              Future.delayed(Duration(seconds: 2), () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Info: ${result['warning']}'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              });
            }
          } else {
            setState(() {
              isWrong = true;
              errorText = "Format data user tidak valid";
              sizeerror = 14;
            });
          }
        } else {
          setState(() {
            isWrong = true;
            errorText = result['message'] ?? 'Google login gagal';
            sizeerror = 14;
          });
          
          // Debug info
          if (result.containsKey('firebase_error')) {
            print('Google Firebase error: ${result['firebase_error']}');
          }
          if (result.containsKey('laravel_error')) {
            print('Google Laravel error: ${result['laravel_error']}');
          }
        }
      } catch (e) {
        Navigator.pop(context);
        print('Error saat Google login: $e');
        setState(() {
          isWrong = true;
          errorText = "Gagal login dengan Google: $e";
          sizeerror = 14;
        });
      }
    } catch (e) {
      Navigator.pop(context);
      CustomWidget.NotifGagal(context);
      print("Google login general error: $e");
    }
  }

  bool isAuthorized = false;
  String contactText = '';

  String errorText = "";
  bool isObscured = true;
  bool isHovered = true;
  bool isEmailFocused = false;
  bool isPasswordFocused = false;
  bool isWrong = false;
  double sizeerror = 0;
  bool isKeyboardActive = false;
  String statusKeyboard = "tidak aktif";
  @override
  void initState() {
    super.initState();

    RawKeyboard.instance.addListener(_handleKeyEvent);
  }

  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();
  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleKeyEvent);

    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQuery = MediaQuery.of(context);
    isKeyboardActive = mediaQuery.viewInsets.bottom > 0;
    return WillPopScope(
      onWillPop: () async {
        print("tombol kembali di tekan");
        if (isKeyboardActive) {
          // Jika keyboard aktif, hanya tutup keyboard
          setState(() {
            _keyboardActiveFunction();
            statusKeyboard = "tidak aktif";
            isEmailFocused = false;
            isPasswordFocused = false;
          });
          isWrong = false;
          FocusScope.of(context).unfocus();
          return false; // Jangan keluar dari halaman
        } else {
          // Jika keyboard tidak aktif, kembali ke halaman utama
          _keyboardInactiveFunction();
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => MainPage())
          );
          return false; // Jangan gunakan back system karena kita sudah handle navigasi
        }
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: CustomColors.whiteColor,
          body: GestureDetector(
            onTap: () {
              setState(() {
                if (isKeyboardActive) {
                  // Jika keyboard aktif
                  _keyboardActiveFunction();
                } else {
                  // Jika keyboard tidak aktif
                  _keyboardInactiveFunction();
                }
                statusKeyboard = "tidak aktif";
                isWrong = false;
                isEmailFocused = false;
                isPasswordFocused = false;
                FocusScope.of(context).unfocus();
              });
            },
            child: SafeArea(
              child: Stack(
                alignment: const Alignment(0, 0),
                fit: StackFit.expand,
                children: [
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Image.asset(Server.UrlGambar("atributlogin.png")),
                  ),
                  Positioned(
                    top: -200,
                    width: 800,
                    child: Center(
                        child: Image.asset(Server.UrlGambar("bgloginn.png"))),
                  ),
                  Positioned(
                    top: -20,
                    left: 5,
                    right: 5,
                    height: 200,
                    child: Image.asset(Server.UrlGambar("logotext.png")),
                  ),
                  Positioned(
                    height: 500,
                    top: 200,
                    left: 30,
                    right: 30,
                    child: Container(
                      child: Card(
                        color: CustomColors.whiteColor,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10)),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Align(
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        15, 25, 15, 20),
                                    child: Text(
                                      "Selamat Datang",
                                      style: CustomText.TextArvoBold(
                                          24, CustomColors.blackColor),
                                    ),
                                  )),
                              Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(25, 1, 25, 5),
                                  child: ElevatedButton(
                                    style: CustomButton.GoogleButton(
                                        CustomColors.whiteColor),
                                    onPressed: () async {
                                      await _loginWithGoogle();
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                            margin: const EdgeInsets.all(10),
                                            width: 20,
                                            height: 20,
                                            child: Image.asset(Server.UrlGambar(
                                                'google.png'))),
                                        Container(
                                          child: Text(
                                            "Masuk Dengan Google",
                                            style: CustomText.TextArvoBold(
                                                13, CustomColors.blackColor),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    margin: const EdgeInsets.fromLTRB(
                                        10, 15, 10, 0),
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            height: 2,
                                            width: 130,
                                            color: CustomColors.HintColor,
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          Text("Atau",
                                              style: CustomText.TextArvoBold(
                                                  12, CustomColors.HintColor)),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          Container(
                                            height: 2,
                                            width: 130,
                                            color: CustomColors.HintColor,
                                          ),
                                        ]),
                                  )),
                              Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(15, 10, 15, 10),
                                  child: Visibility(
                                    visible: isWrong,
                                    child: Text(errorText,
                                        textAlign: TextAlign.center,
                                        style: CustomText.TextArvoBold(
                                            16, CustomColors.redColor)),
                                  ),
                                ),
                              ),
                              Container(
                                height: 55,
                                padding:
                                    const EdgeInsets.fromLTRB(30, 5, 30, 10),
                                child: TextField(
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9@.a-zA-Z]')),
                                  ],
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textAlign: TextAlign.start,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    hintText: "Masukkan Email Anda",
                                    border: const OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(10)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                        color: CustomColors
                                            .primaryColor, // Warna border saat aktif
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                        color: CustomColors
                                            .blackColor, // Warna border saat tidak aktif
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 0, horizontal: 10.0),
                                    hintStyle: CustomText.TextArvo(
                                        14, CustomColors.HintColor),
                                  ),
                                  style: CustomText.TextArvo(
                                    16,
                                    CustomColors.blackColor,
                                  ),
                                  focusNode: emailFocusNode,
                                  onTap: () {
                                    isWrong = false;
                                    setState(() {
                                      emailFocusNode.requestFocus();
                                      isEmailFocused = true;
                                      isPasswordFocused = false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Container(
                                height: 50,
                                padding:
                                    const EdgeInsets.fromLTRB(30, 5, 30, 5),
                                child: TextField(
                                  controller: passwordController,
                                  keyboardType: TextInputType.visiblePassword,
                                  textAlign: TextAlign.start,
                                  textInputAction: TextInputAction.next,
                                  obscureText: isObscured,
                                  decoration: InputDecoration(
                                    hintText: "Masukkan Kata Sandi Anda",
                                    border: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                        color: isPasswordFocused
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                        color: CustomColors
                                            .primaryColor, // Warna border saat aktif
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      borderSide: BorderSide(
                                        color: CustomColors
                                            .blackColor, // Warna border saat tidak aktif
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 0, horizontal: 10.0),
                                    hintStyle: CustomText.TextArvo(
                                        14, CustomColors.HintColor),
                                    suffixIcon: IconButton(
                                      alignment: Alignment.center,
                                      onPressed: () {
                                        setState(() {
                                          isObscured = !isObscured;
                                        });
                                      },
                                      icon: Icon(
                                        isObscured
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      iconSize: 25,
                                    ),
                                  ),
                                  style: CustomText.TextArvo(
                                    16,
                                    CustomColors.blackColor,
                                  ),
                                  focusNode: passwordFocusNode,
                                  onTap: () {
                                    if (isKeyboardActive) {
                                      // Jika keyboard aktif
                                      _keyboardActiveFunction();
                                    } else {
                                      // Jika keyboard tidak aktif
                                      _keyboardInactiveFunction();
                                    }
                                    isWrong = false;
                                    setState(() {
                                      statusKeyboard = "aktif";
                                      passwordFocusNode.requestFocus();
                                      isPasswordFocused = true;
                                      isEmailFocused = false;
                                    });
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 10),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      print("Lupa sandi pressed");
                                      Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: ((context, animation,
                                                    secondaryAnimation) =>
                                                const LupaPassword1()),
                                            transitionsBuilder: (context,
                                                animation,
                                                secondaryAnimation,
                                                child) {
                                              return FadeTransition(
                                                  opacity: animation,
                                                  child: child);
                                            },
                                          ));
                                    },
                                    child: Text("Lupa Kata Sandi?",
                                        style: CustomText.TextArvoItalic(
                                            16, CustomColors.HintColor)),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 5, bottom: 20),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: ElevatedButton(
                                    style: CustomButton.DefaultButton(
                                        CustomColors.primaryColor),
                                    onPressed: () {
                                      setState(() {
                                        print("Login presseedd");
                                        try {
                                          _ceklogin();
                                          print("press");
                                        } catch ($e) {
                                          CustomWidget.NotifGagal(context);
                                          print("ERRORRR ${$e}");
                                        }
                                      });
                                    },
                                    child: Text("Masuk",
                                        style: CustomText.TextArvoBold(
                                            20, CustomColors.whiteColor)),
                                  ),
                                ),
                              ),
                              Text(
                                'Status Keyboard: ${isKeyboardActive ? statusKeyboard = 'Aktif' : statusKeyboard = "tidak aktif"}$statusKeyboard',
                                style: const TextStyle(
                                  fontSize: 0,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Center(
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'Belum Punya Akun? ',
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: CustomColors.HintColor,
                                          fontFamily: 'NotoSanSemiBold',
                                          fontWeight: FontWeight.bold),
                                      children: [
                                        TextSpan(
                                          text: 'Daftar Sekarang',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: CustomColors
                                                  .secondaryColor, // Mengubah warna di sini
                                              fontFamily: 'NotoSanSemiBold',
                                              fontWeight: FontWeight.bold),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              print("Pressed");
                                              Navigator.push(
                                                context,
                                                SmoothPageTransition(
                                                  page: const Register(),
                                                ),
                                              );
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _keyboardActiveFunction() {
    print('Keyboard aktif');
  }

  void _keyboardInactiveFunction() {
    print('Keyboard tidak aktif');
    // Tidak perlu navigasi di sini karena sudah ditangani di onWillPop
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyUpEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      // Memastikan bahwa peristiwa tombol kembali terjadi
      print('Tombol kembali ditekan');
      // Mengubah variabel boolean menjadi true
      setState(() {
        isKeyboardActive = true;
      });
    }
  }
}
