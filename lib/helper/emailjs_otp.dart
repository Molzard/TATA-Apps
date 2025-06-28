import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailJsOtp {
  static const String serviceId = 'service_pa3nk91';
  static const String templateId = 'template_amn3fm3';
  static const String publicKey = 'H54XgmXddnw018hto';

  static Future<bool> sendOtpEmailJS({
    required String email,
    required String otp,
    String companyName = 'TATA Printing',
    String websiteLink = 'https://your-website.com',
    String? time,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
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

    return response.statusCode == 200;
  }
} 