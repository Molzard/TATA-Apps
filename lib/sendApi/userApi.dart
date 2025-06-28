import 'dart:convert';
import 'package:TATA/SendApi/Server.dart';
import 'package:TATA/SendApi/tokenJWT.dart';
import 'package:TATA/helper/user_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class UserApi {
  static Future<Map<String, dynamic>?> GantiPasswordProfil(
      String passwordOld, String password, String passwordConfirm) async {
    String? token = await TokenJwt.getToken();
    String? email = await TokenJwt.getEmail();
    final response = await http.put(
      Server.urlLaravel("users/profile/profile/password"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": token.toString()
      },
      body: json.encode({
        "password_old": passwordOld,
        "password": password,
        "password_confirm": passwordConfirm,
        "email": email.toString(),
      }),
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      return result;
    } else if (response.statusCode == 400) {
      final result = json.decode(response.body);
      return result;
    } else {
      print(response.body);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getProfil(String email) async {
    String? token = await TokenJwt.getToken();
    final response = await http.post(
      Server.urlLaravel("users/profile"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": token.toString()
      },
      body: json.encode({
        "email": email,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 400) {
      final result = json.decode(response.body);
      return result;
    } else {
      return null;
    }
  }

  static Future<String?> checkEmailAvailability(String email) async {
    try {
      final response = await http.post(
        Server.urlLaravel("mobile/users/check-email"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['status'];
        } else {
          return data['message'];
        }
      } else {
        final data = jsonDecode(response.body);
        return data['message'];
      }
    } catch (e) {
      print('Error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> ForgotPassword(
      String email, String password) async {
    try {
      // 1. Update password di Laravel terlebih dahulu
      final response = await http.post(
        Server.urlLaravel("mobile/users/change-password"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          
          // 2. Setelah Laravel berhasil, update Firebase juga
          try {
            // Coba login dengan password baru untuk memastikan Firebase terupdate
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email, 
              password: password
            );
            
            // Jika berhasil login, berarti password sudah sinkron
            await FirebaseAuth.instance.signOut(); // Logout setelah verifikasi
            
            return {
              'status': 'success',
              'message': 'Password berhasil diubah dan tersinkronisasi.'
            };
          } catch (firebaseError) {
            print('Firebase masih belum sinkron, kirim reset email: $firebaseError');
            
            // Jika Firebase belum sinkron, kirim email reset
            try {
              await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
              return {
                'status': 'success',
                'message': 'Password Laravel berhasil diubah. Email reset Firebase telah dikirim untuk sinkronisasi.'
              };
            } catch (resetError) {
              return {
                'status': 'success',
                'message': 'Password Laravel berhasil diubah. Silakan reset password Firebase secara manual.'
              };
            }
          }
        }
      }
      
      final data = jsonDecode(response.body);
      return data;
      
    } catch (e) {
      print('Error: $e');
      return {'status': 'error', 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>?> ForgotPasswordFirebase(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return {
        'status': 'success', 
        'message': 'Email reset password telah dikirim'
      };
    } catch (e) {
      return {
        'status': 'error', 
        'message': 'Gagal mengirim email reset: $e'
      };
    }
  }

  static Future<Map<String, dynamic>?> register(
    String email,
    String noTelpon,
    String nama,
    String password,
    String passwordConfirm,
  ) async {
    try {
      print('Registering user: $email');
    final response = await http.post(
        Server.urlLaravel("mobile/users/register"),
      headers: {
        "Content-Type": "application/json",
      },
      body: json.encode({
        "email": email,
        "no_telpon": noTelpon,
        "nama_user": nama,
        "password": password,
        "password_confirmation": passwordConfirm,
      }),
    );

      print('Register status code: ${response.statusCode}');
      print('Register response: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 400) {
      final result = json.decode(response.body);
      return result;
    } else if (response.statusCode == 500) {
      final result = json.decode(response.body);
      return result;
    } else {
      print("Error Kode ${response.statusCode}");
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      print('Exception during registration: $e');
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    try {
      print('Login attempt for: $email');
    final response = await http.post(
        Server.urlLaravel("mobile/users/login"),
      headers: {
        "Content-Type": "application/json",
      },
      body: json.encode({
        "email": email,
        "password": password,
      }),
    );
      
      print('Login status code: ${response.statusCode}');
      print('Login response: ${response.body}');

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
        print('Login success, saving user data: ${result['data']}');
        
        // Simpan data user lengkap (termasuk token) di UserPreferences
        await UserPreferences.saveUser(result['data']);
        
        // Pastikan email juga disimpan di TokenJWT
        String email = result['data']['user']['email'];
        await TokenJwt.saveEmail(email);
        
        print('User data saved to preferences');
        return result['data'];
    } else if (response.statusCode == 400) {
      final result = json.decode(response.body);
      return result;
    } else {
        print('Login failed with status: ${response.statusCode}');
        return {'status': 'error', 'message': 'Login failed with status: ${response.statusCode}'};
      }
    } catch (e) {
      print('Exception during login: $e');
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> CekEmail(String email) async {
    try {
      print('URL request: ${Server.urlLaravel("mobile/users/check-email")}');
      
    final response = await http.post(
        Server.urlLaravel("mobile/users/check-email"),
      headers: {
        "Content-Type": "application/json",
      },
      body: json.encode({"email": email}),
    );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return result;
    } else if (response.statusCode == 400) {
      final result = json.decode(response.body);
      return result;
    } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      print('Exception during CekEmail: $e');
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> loginGoogle(String email) async {
    try {
      print('Login with Google for: $email');
    final response = await http.post(
        Server.urlLaravel("mobile/users/login-google"),
      headers: {
        "Content-Type": "application/json",
      },
      body: json.encode({
        "email": email,
      }),
    );

      print('Google login status code: ${response.statusCode}');
      print('Google login response: ${response.body}');

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      final jwtToken = result['data'];
      await TokenJwt.saveToken(jwtToken);

      final decodedPayload = _parseJwt(jwtToken);
      return decodedPayload;
    } else if (response.statusCode == 400) {
      final result = json.decode(response.body);
      return result;
    } else {
        return {'status': 'error', 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      print('Exception during Google login: $e');
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  // Fungsi untuk mendekode JWT
  static Map<String, dynamic> _parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Token tidak valid');
    }

    final payload = _decodeBase64(parts[1]);
    return json.decode(payload);
  }

  static String _decodeBase64(String str) {
    String normalized = base64Url.normalize(str);
    return utf8.decode(base64Url.decode(normalized));
  }

  // Tambahkan fungsi ini di userApi.dart untuk testing
  static Future<void> testLogin(String email, String password) async {
    try {
      final response = await http.post(
        Server.urlLaravel("mobile/users/login"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      print('Laravel login test - Status: ${response.statusCode}');
      print('Laravel login test - Response: ${response.body}');
      
    } catch (e) {
      print('Laravel login test error: $e');
    }
  }
}
