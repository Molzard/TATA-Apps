import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailJsOtp {
  // static const String serviceId = 'service_pa3nk91';
  static const String serviceId = 'service_so8zovk';
  // static const String templateId = 'template_amn3fm3';
  static const String templateId = 'template_u3s7loj';
  // static const String publicKey = 'H54XgmXddnw018hto';
  static const String publicKey = 't0mM0eAqFNJ27rTN-';

  static Future<bool> sendOtpEmailJS({
    required String email,
    required String otp,
    String companyName = 'TATA Printing',
    String websiteLink = 'https://tata-apps.mazkama.web.id/',
    String? time,
  }) async {
    // final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final url = Uri.parse('https://tata-apps.mazkama.web.id/api/mail/send-otp');
    final now = DateTime.now();
    final expireTime = time ?? now.add(Duration(minutes: 15)).toString();

    final payload = {
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': publicKey,
      'template_params': {
        'email': email,
        'otp': otp,
        'company_name': companyName,
        'website_link': websiteLink,
        'time': expireTime,
      },
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      print('OTP berhasil dikirim ke EmailJS');
      return true;
    } else {
      print('Gagal mengirim OTP ke EmailJS');
      print('Status code: \\${response.statusCode}');
      print('Response body: \\${response.body}');
      return false;
    }
  }
}