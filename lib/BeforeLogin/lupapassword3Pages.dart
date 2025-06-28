import 'package:TATA/SendApi/userApi.dart';
import 'package:TATA/BeforeLogin/lupapassword4Pages.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/src/CustomButton.dart';
import 'package:TATA/src/CustomText.dart';
import 'package:TATA/src/CustomWidget.dart';
import 'package:TATA/src/customFormfield.dart';
import 'package:flutter/material.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:lottie/lottie.dart';
import 'package:TATA/src/customConfirmDialog.dart';
import 'package:TATA/services/AuthService.dart';

class Lupapassword3 extends StatefulWidget {
  final String email;
  const Lupapassword3({super.key, required this.email});

  @override
  _Lupapassword3State createState() => _Lupapassword3State();
}

class _Lupapassword3State extends State<Lupapassword3> {
  String _passwordBaruError = '';
  String _konfirmasiPasswordError = '';
  bool _isPasswordVisible = false;
  bool _isKonfirmasiPasswordVisible = false;
  String _password = '';
  double _strength = 0;
  bool _isPasswordMatch = true;
  bool _isLoading = false;

  final TextEditingController _passwordBaruController = TextEditingController();
  final TextEditingController _konfirmasiPasswordController =
      TextEditingController();

  bool get _isButtonEnabled =>
      _passwordBaruController.text.isNotEmpty &&
      _konfirmasiPasswordController.text.isNotEmpty &&
      _passwordBaruController.text == _konfirmasiPasswordController.text &&
      _strength >= 2 / 4;

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
  
  void _checkPasswordMatch(String value) {
    setState(() {
      _isPasswordMatch = _passwordBaruController.text == value;
      if (!_isPasswordMatch) {
        _konfirmasiPasswordError = 'Password tidak sama';
      } else {
        _konfirmasiPasswordError = '';
      }
    });
  }

  void _validateForm() {
    setState(() {
      // Validate password
      if (_passwordBaruController.text.isEmpty) {
        _passwordBaruError = 'Password tidak boleh kosong';
      } else if (_passwordBaruController.text.length < 6) {
        _passwordBaruError = 'Password minimal 6 karakter';
      } else {
        _passwordBaruError = '';
      }
      
      // Validate confirmation password
      if (_konfirmasiPasswordController.text.isEmpty) {
        _konfirmasiPasswordError = 'Konfirmasi password tidak boleh kosong';
      } else if (_konfirmasiPasswordController.text != _passwordBaruController.text) {
        _konfirmasiPasswordError = 'Password tidak sama';
        _isPasswordMatch = false;
      } else {
        _konfirmasiPasswordError = '';
        _isPasswordMatch = true;
      }
    });
    
    if (_passwordBaruError.isEmpty && _konfirmasiPasswordError.isEmpty) {
      _handleNext();
    }
  }

  void _handleNext() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('Mencoba reset password hybrid untuk email: ${widget.email}');
      final result = await AuthService().resetPasswordHybrid(widget.email, _passwordBaruController.text);
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (result['status'] == "success") {
        // Tampilkan pesan sukses
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Password Berhasil Diubah'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result['message'] ?? 'Password berhasil diubah'),
                if (result.containsKey('warning'))
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Info: ${result['warning']}',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LupaPassword4()),
                  );
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        String errorMessage = result['message'] ?? 'Terjadi kesalahan';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah password: $errorMessage'),
            backgroundColor: Colors.red,
          )
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      print('Error saat reset password: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Center(
                                child: Text('Lupa Password',
                                    style: CustomText.TextArvoBold(
                                        22, CustomColors.blackColor)),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Password Baru',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              TextField(
                                controller: _passwordBaruController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  hintText: 'Masukkan Password Baru',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: CustomColors.primaryColor,
                                    ),
                                  ),
                                  errorText: _passwordBaruError.isNotEmpty ? _passwordBaruError : null,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.black,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                onChanged: _checkPassword,
                              ),
                              const SizedBox(height: 5),
                              // Bar strength password
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
                              const SizedBox(height: 20),
                              Text(
                                'Konfirmasi Password Baru',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              TextField(
                                controller: _konfirmasiPasswordController,
                                obscureText: !_isKonfirmasiPasswordVisible,
                                decoration: InputDecoration(
                                  hintText: 'Masukkan Konfirmasi Password Baru',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: CustomColors.primaryColor,
                                    ),
                                  ),
                                  errorText: _konfirmasiPasswordError.isNotEmpty ? _konfirmasiPasswordError : null,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isKonfirmasiPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.black,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isKonfirmasiPasswordVisible = !_isKonfirmasiPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                onChanged: _checkPasswordMatch,
                              ),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: CustomButton.DefaultButton(
                                      CustomColors.primaryColor),
                                  onPressed: _isLoading ? null : _validateForm,
                                  child: _isLoading
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
                              const SizedBox(height: 15),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    side: BorderSide(color: Colors.black, width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                  ),
                                  child: Text("Kembali",
                                      style: CustomText.TextArvoBold(
                                          16, CustomColors.blackColor)),
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
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
