import 'package:TATA/BeforeLogin/lupapassword3Pages.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/src/CustomButton.dart';
import 'package:TATA/src/CustomText.dart';
import 'package:email_otp/email_otp.dart';
import 'package:flutter/material.dart';
import 'package:TATA/src/CustomColors.dart';
import 'dart:async';
import 'package:pinput/pinput.dart';
import 'package:lottie/lottie.dart';
import 'package:TATA/helper/emailjs_otp.dart';

class LupaPassword2 extends StatefulWidget {
  final String email;
  const LupaPassword2({super.key, required this.email});

  @override
  _LupaPassword2State createState() => _LupaPassword2State();
}

class _LupaPassword2State extends State<LupaPassword2> {
  final pinController = TextEditingController();
  final focusNode = FocusNode();
  final formKey = GlobalKey<FormState>();
  String _otpError = '';
  bool _isLoading = false;
  int _timerSeconds = 60;
  Timer? _timer;
  bool _isTimerRunning = true;
  String? _sentOtp;
  bool _isSendingOtp = false;

  @override
  void initState() {
    super.initState();
    startTimer();
    resendOTP(); // Kirim OTP pertama kali
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timerSeconds > 0) {
            _timerSeconds--;
          } else {
            _isTimerRunning = false;
            _timer?.cancel();
          }
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> resendOTP() async {
    if (_isSendingOtp) return;
    if (!mounted) return;
    
    setState(() {
      _isSendingOtp = true;
      _timerSeconds = 60;
      _isTimerRunning = true;
      _otpError = '';
    });
    startTimer();
    // Generate OTP random 6 digit
    final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    final sent = await EmailJsOtp.sendOtpEmailJS(email: widget.email, otp: otp);
    
    if (!mounted) return;
    
    if (sent) {
      setState(() {
        _sentOtp = otp;
        _otpError = '';
      });
      print('OTP sent and saved: $otp');
    } else {
      setState(() {
        _otpError = 'Gagal mengirim OTP. Coba lagi nanti.';
      });
      print('Gagal mengirim OTP ke EmailJS');
    }
    
    if (mounted) {
      setState(() {
        _isSendingOtp = false;
      });
    }
  }

  bool isOTPFilled() {
    return pinController.text.length == 6;
  }

  void validateOTP() async {
    final isValid = pinController.text == _sentOtp;
    
    if (!mounted) return;
    
    setState(() {
      _otpError = isValid ? '' : 'Kode OTP salah atau tidak valid.';
    });
    
    if (isValid) {
      setState(() => _isLoading = true);
      
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => Lupapassword3(
                    email: widget.email,
                  )),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: CustomColors.primaryColor),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
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
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight),
                                child: IntrinsicHeight(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 50),
                                        Center(
                                          child: Text('Verifikasi Code',
                                              style: CustomText.TextArvoBold(
                                                  22, CustomColors.blackColor)),
                                        ),
                                        const SizedBox(height: 30),
                                        Center(
                                          child: Pinput(
                                            length: 6,
                                            controller: pinController,
                                            focusNode: focusNode,
                                            defaultPinTheme: defaultPinTheme,
                                            separatorBuilder: (index) =>
                                                const SizedBox(width: 8),
                                            validator: (value) {
                                              return value?.length == 6
                                                  ? null
                                                  : 'Pin tidak lengkap';
                                            },
                                            onCompleted: (pin) {
                                              setState(() => _otpError = '');
                                            },
                                          ),
                                        ),
                                        if (_otpError.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Center(
                                              child: Text(
                                                _otpError,
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 10),
                                        Center(
                                          child: Text(
                                            'Cek Email kamu',
                                            style: TextStyle(
                                              color: CustomColors.HintColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Center(
                                          child: Text(
                                            '00:${_timerSeconds.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              color: CustomColors.blackColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 4,
                                          children: [
                                            Text(
                                              'Tidak menerima kode?',
                                              style: TextStyle(
                                                color: CustomColors.HintColor,
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            TextButton(
                                              onPressed: _isTimerRunning
                                                  ? null
                                                  : resendOTP,
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size(50, 30),
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: Text(
                                                'Kirim ulang',
                                                style: TextStyle(
                                                  color: _isTimerRunning
                                                      ? Colors.grey
                                                      : CustomColors
                                                          .primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 80,
                                        ),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: CustomColors.primaryColor,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 15),
                                              elevation: 5,
                                            ),
                                            onPressed: _isLoading || !isOTPFilled()
                                                ? null
                                                : validateOTP,
                                            child: _isLoading
                                                ? SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : Text(
                                                    "Masuk",
                                                    style: CustomText.TextArvoBold(
                                                        18, CustomColors.whiteColor),
                                                  ),
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
                                              elevation: 0,
                                            ),
                                            child: Text(
                                              "Kembali",
                                              style: CustomText.TextArvoBold(
                                                  16, CustomColors.blackColor),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 4,
                                          children: [
                                            Text("Belum Punya Akun?",
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
                        ),
                      ),
                    ),
                  ],
                );
              },
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
