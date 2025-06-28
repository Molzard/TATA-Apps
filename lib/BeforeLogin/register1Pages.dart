import 'package:TATA/BeforeLogin/page_login.dart';
import 'package:TATA/BeforeLogin/register2Pages.dart';
import 'package:TATA/SendApi/userApi.dart';
import 'package:TATA/models/RegisterModels.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/services/AuthService.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:TATA/src/CustomText.dart';
import 'package:TATA/src/CustomWidget.dart';
import 'package:TATA/src/pageTransition.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:TATA/src/autofilltext.dart';
import 'package:TATA/src/customConfirmDialog.dart';
import 'package:TATA/helper/user_preferences.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final AuthService _authService = AuthService();
  String? _selectedGender;
  String _passwordBaruError = '';
  String _konfirmasiPasswordError = '';
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _konfirmasiPasswordController =
      TextEditingController();
  String _password = '';

  double _strength = 0;
  final bool _isPasswordVisible = false;
  final bool _isKonfirmasiPasswordVisible = false;
  final TextEditingController _noHpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  String _noHpError = '';
  String _emailError = '';
  String _namaError = '';

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearEmailError);
    _noHpController.addListener(_clearNoHpError);
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearEmailError);
    _noHpController.removeListener(_clearNoHpError);
    _emailController.dispose();
    _passwordController.dispose();
    _noHpController.dispose();
    super.dispose();
  }

  RegExp numReg = RegExp(r".*[0-9].*");
  RegExp letterReg = RegExp(r".*[A-Za-z].*");

  void _checkPassword(String value) {
    setState(() {
      _password = value.trim();

      if (_password.isEmpty) {
        _strength = 0;
      } else if (_password.length < 6) {
        _strength = 1 / 4;
      } else if (_password.length < 8) {
        _strength = 2 / 4;
      } else if (!letterReg.hasMatch(_password) ||
          !numReg.hasMatch(_password)) {
        _strength = 3 / 4;
      } else {
        _strength = 1;
      }
    });
  }

  void _clearEmailError() {
    if (_emailError.isNotEmpty) {
      setState(() {
        _emailError = '';
      });
    }
  }

  void _clearNoHpError() {
    if (_noHpError.isNotEmpty) {
      setState(() {
        _noHpError = '';
      });
    }
  }

  String _getPasswordStrengthText() {
    if (_strength <= 1 / 4) {
      return 'Lemah';
    } else if (_strength == 2 / 4) {
      return 'Sedang';
    } else if (_strength == 3 / 4) {
      return 'Kuat';
    } else {
      return 'Sangat Kuat';
    }
  }

  void _validateInputs() async {
    setState(() {
      if (_emailController.text.isEmpty) {
        _emailError = 'Email tidak boleh kosong';
      } else {
        _emailError = '';
      }
      if (_namaController.text.isEmpty) {
        _namaError = 'Nama tidak boleh kosong';
      } else {
        _namaError = '';
      }
      if (_passwordController.text.isEmpty) {
        _passwordBaruError = "Password tidak boleh kosong";
      } else {
        _passwordBaruError = "";
      }
      if (_passwordController.text != _konfirmasiPasswordController.text) {
        _konfirmasiPasswordError = "Konfirmasi kata sandi tidak sesuai";
      } else {
        _konfirmasiPasswordError = "";
      }
      if (_noHpController.text.isEmpty) {
        _noHpError = 'Nomor HP tidak boleh kosong';
      } else if (!_noHpController.text.startsWith('08')) {
        _noHpError = 'Nomor HP Tidak Valid';
      } else if (_noHpController.text.length > 13) {
        _noHpError = 'Nomor HP maksimal 13 digit';
      } else {
        _noHpError = '';
      }
    });

    if (_emailError.isEmpty &&
        _noHpError.isEmpty &&
        _namaError.isEmpty &&
        _passwordBaruError.isEmpty &&
        _konfirmasiPasswordError.isEmpty) {
      bool confirm = await CustomConfirmDialog.show(
        context: context,
        title: 'Konfirmasi',
        message: 'Apakah data yang anda masukkan sudah benar?',
        confirmText: 'Ya',
        cancelText: 'Tidak',
      );
      if (confirm) {
        // Simpan nomor telepon ke UserPreferences
        await UserPreferences.savePhoneNumber(_noHpController.text);
        _CekEmail();
      }
    } else {
      if (_namaError.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_namaError),
            backgroundColor: CustomColors.redColor,
            duration: Duration(seconds: 3),
          ),
        );
      } else if (_emailError.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_emailError),
            backgroundColor: CustomColors.redColor,
            duration: Duration(seconds: 3),
          ),
        );
      } else if (_noHpError.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_noHpError),
            backgroundColor: CustomColors.redColor,
            duration: Duration(seconds: 3),
          ),
        );
      } else if (_passwordBaruError.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_passwordBaruError),
            backgroundColor: CustomColors.redColor,
            duration: Duration(seconds: 3),
          ),
        );
      } else if (_konfirmasiPasswordError.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_konfirmasiPasswordError),
            backgroundColor: CustomColors.redColor,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        CustomWidget.NotifGagal(context);
      }
      print(_emailError);
      print(_noHpError);
      print(_konfirmasiPasswordError);
    }
  }

  void _autoFillForTesting() {
    AutoFillText.autoFillRegister1(
        _emailController, _noHpController, _passwordController);
  }

  Future<void> _CekEmail() async {
    try {
      CustomWidget.NotifLoading(context);
      
      // Cek apakah email sudah terdaftar di Firebase
      try {
        final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(_emailController.text);
        
        if (methods.isNotEmpty) {
          // Email sudah terdaftar
          Navigator.pop(context); // Tutup dialog loading
          setState(() {
            _emailError = 'Email sudah terdaftar';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_emailError),
              backgroundColor: CustomColors.redColor,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
        
        // Email belum terdaftar, lanjutkan ke halaman berikutnya
        Navigator.pop(context); // Tutup dialog loading
        
        final registerDATA = RegisterData(
          namaUser: _namaController.text,
          email: _emailController.text,
          noHp: _noHpController.text,
          pasword: _passwordController.text,
        );
        
        Navigator.push(
          context,
          SmoothPageTransition(
            page: Register2(registerData: registerDATA),
          ),
        );
      } on FirebaseAuthException catch (e) {
        Navigator.pop(context); // Tutup dialog loading
        if (e.code == 'invalid-email') {
          setState(() {
            _emailError = 'Format email tidak valid';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_emailError),
              backgroundColor: CustomColors.redColor,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Terjadi kesalahan: ${e.message}"),
              backgroundColor: CustomColors.redColor,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        Navigator.pop(context); // Tutup dialog loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan: $e"),
            backgroundColor: CustomColors.redColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Tutup dialog loading
      CustomWidget.NotifGagal(context);
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
              height: 530,
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
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Center(
                              child: GestureDetector(
                                onDoubleTap: _autoFillForTesting,
                                child: const Text(
                                  'Daftar untuk bergabung',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.black,
                                    fontFamily: 'OdorMeanChey',
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
                            Container(
                              height: 55,
                              padding: const EdgeInsets.fromLTRB(0, 5, 0, 10),
                              child: TextField(
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9 .a-zA-Z]')),
                                ],
                                controller: _namaController,
                                keyboardType: TextInputType.text,
                                textAlign: TextAlign.start,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: "Nama Lengkap",
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
                                  14,
                                  CustomColors.blackColor,
                                ),
                              ),
                            ),
                            Container(
                              height: 55,
                              padding: const EdgeInsets.fromLTRB(0, 5, 0, 10),
                              child: TextField(
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9@.a-zA-Z]')),
                                ],
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textAlign: TextAlign.start,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: "Alamat Email",
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
                                  14,
                                  CustomColors.blackColor,
                                ),
                              ),
                            ),
                            Container(
                              height: 55,
                              padding: const EdgeInsets.fromLTRB(0, 5, 0, 10),
                              child: TextField(
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9+]')),
                                ],
                                controller: _noHpController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.start,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: "Nomor Telepon",
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
                                  14,
                                  CustomColors.blackColor,
                                ),
                              ),
                            ),
                            Container(
                              height: 55,
                              padding: const EdgeInsets.fromLTRB(0, 5, 0, 10),
                              child: TextField(
                                obscureText: false,
                                onChanged: (value) => _checkPassword(value),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9@.a-zA-Z]')),
                                ],
                                controller: _passwordController,
                                keyboardType: TextInputType.text,
                                textAlign: TextAlign.start,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: "Kata Sandi",
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
                                  14,
                                  CustomColors.blackColor,
                                ),
                              ),
                            ),
                            Container(
                              height: 55,
                              padding: const EdgeInsets.fromLTRB(0, 5, 0, 10),
                              child: TextField(
                                obscureText: false,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9@.a-zA-Z]')),
                                ],
                                controller: _konfirmasiPasswordController,
                                keyboardType: TextInputType.text,
                                textAlign: TextAlign.start,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: "Konfirmasi Kata Sandi",
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
                                  14,
                                  CustomColors.blackColor,
                                ),
                              ),
                            ),
                            // Bar strength password tetap sama
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: 100,
                                  height: 5,
                                  child: LinearProgressIndicator(
                                    value: _strength,
                                    backgroundColor: Colors.grey[300],
                                    color: _strength <= 1 / 4
                                        ? Colors.red
                                        : _strength == 2 / 4
                                            ? Colors.yellow
                                            : _strength == 3 / 4
                                                ? Colors.blue
                                                : Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _getPasswordStrengthText(),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                            //batas bar
                            const SizedBox(height: 20),
                            Center(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.8,
                                child: ElevatedButton(
                                  onPressed: _validateInputs,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: CustomColors.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15.0),
                                  ),
                                  child: const Text(
                                    'Daftar',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontFamily: 'NotoSanSemiBold',
                                        fontWeight: FontWeight.w400),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Center(
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Sudah Punya Akun? ',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: CustomColors.HintColor,
                                        fontFamily: 'NotoSanSemiBold',
                                        fontWeight: FontWeight.bold),
                                    children: [
                                      TextSpan(
                                        text: 'Masuk',
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
                                                page: const page_login(),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
