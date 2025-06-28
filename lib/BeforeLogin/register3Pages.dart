import 'package:TATA/BeforeLogin/page_login.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:TATA/src/pageTransition.dart';
import 'package:flutter/material.dart';

class Register3pages extends StatelessWidget {
  const Register3pages({super.key});

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
              height: 460,
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Image.asset(
                            'assets/images/checklist.png',
                            width: 150,
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            textAlign: TextAlign.center,
                            'Akun Berhasil Dibuat',
                            style: TextStyle(
                                fontSize: 22,
                                color: Colors.black,
                                fontFamily: 'Arvo',
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 60),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  SmoothPageTransition(page: page_login()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CustomColors.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15.0),
                              ),
                              child: const Text(
                                'Kembali ke Menu Login',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'NotoSanSemiBold',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                              height: 30), // Mengurangi jarak di bawah button
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
