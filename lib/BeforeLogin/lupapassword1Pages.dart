// import 'package:TATA/SendApi/userApi.dart';
// import 'package:TATA/menu/UserPages/lupapassword2pages.dart';
// import 'package:TATA/src/customFormfield.dart';
import 'package:TATA/BeforeLogin/lupapassword2pages.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/sendApi/userApi.dart';
import 'package:TATA/src/CustomButton.dart';
import 'package:TATA/src/CustomText.dart';
import 'package:TATA/src/CustomWidget.dart';
import 'package:TATA/src/pageTransition.dart';
import 'package:flutter/material.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:flutter/services.dart';
import 'package:TATA/services/AuthService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:TATA/BeforeLogin/page_login.dart';
import 'package:TATA/helper/emailjs_otp.dart';

class LupaPassword1 extends StatefulWidget {
  const LupaPassword1({super.key});

  @override
  _LupaPassword1State createState() => _LupaPassword1State();
}

class _LupaPassword1State extends State<LupaPassword1> {
  final AuthService _authService = AuthService();
  TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  String errorText = '';
  
  Future<void> _sendOTP() async {
    setState(() {
      isLoading = true;
      errorText = '';
    });
    
    if (emailController.text.isEmpty) {
      setState(() {
        isLoading = false;
        errorText = 'Email tidak boleh kosong';
      });
      return;
    }
    
    // Validasi format email
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text)) {
      setState(() {
        isLoading = false;
        errorText = 'Format email tidak valid';
      });
      return;
    }
    
    try {
      // Verify if email exists in the system
      final emailExists = await _authService.checkEmailExists(emailController.text);
      
      if (!emailExists) {
        setState(() {
          isLoading = false;
          errorText = 'Email tidak terdaftar dalam sistem';
        });
        return;
      }
      
      // Generate OTP and send it via EmailJS
      final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      final sent = await EmailJsOtp.sendOtpEmailJS(email: emailController.text, otp: otp);
      
      if (sent) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          
          // Navigate to OTP verification page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LupaPassword2(
                email: emailController.text,
              ),
            ),
          );
        }
      } else {
        setState(() {
          isLoading = false;
          errorText = 'Gagal mengirim kode OTP. Silakan coba lagi.';
        });
      }
    } catch (e) {
      print('Error saat mengirim OTP: $e');
      setState(() {
        isLoading = false;
        errorText = 'Terjadi kesalahan saat memproses permintaan';
      });
    }
  }

  void _validateInputs() async {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email tidak boleh kosong')),
      );
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email tidak valid')),
      );
    } else {
      _sendOTP();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
              child:
                  Center(child: Image.asset(Server.UrlGambar("bgloginn.png"))),
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
              top: 210,
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            alignment: Alignment.topCenter,
                            child: Column(
                              children: [
                                const SizedBox(height: 25),
                                Center(
                                  child: Text('Email Pengguna',
                                      style: CustomText.TextArvoBold(
                                          22, CustomColors.blackColor)
                                      // TextStyle(
                                      //   fontSize: 24,
                                      //   fontWeight: FontWeight.bold,
                                      //   color: Colors.black,
                                      // ),
                                      ),
                                ),
                                const SizedBox(height: 20),
                                TextField(
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
                                  onTap: () {},
                                ),
                                if (errorText.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      errorText,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 130),
                          Container(
                            alignment: Alignment.bottomCenter,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 5, bottom: 20),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: ElevatedButton(
                                      style: CustomButton.DefaultButton(
                                          CustomColors.primaryColor),
                                      onPressed: isLoading ? null : _validateInputs,
                                      child: isLoading 
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text("Masuk",
                                          style: CustomText.TextArvoBold(
                                              18, CustomColors.whiteColor)),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 10),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      side: BorderSide(
                                          color: Colors.black, width: 1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                    ),
                                    child: Center(
                                      child: Text("Kembali",
                                          style: CustomText.TextArvoBold(
                                              16, CustomColors.blackColor)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Belum Punya Akun? ",
                                        style: CustomText.TextArvo(
                                            14, CustomColors.HintColor)),
                                    GestureDetector(
                                      onTap: () {
                                        print("Daftar sekarang ditekan");
                                      },
                                      child: Text(
                                        "Daftar Sekarang",
                                        style: CustomText.TextArvoBold(
                                            14, CustomColors.secondaryColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
