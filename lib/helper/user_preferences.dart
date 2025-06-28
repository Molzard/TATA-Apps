import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:TATA/sendApi/tokenJWT.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as Math;
import 'package:http/http.dart' as http;
import 'package:TATA/sendApi/Server.dart';

class UserPreferences {
  static const String _userKey = 'user_data';
  static const String _fcmTokenKey = 'fcm_token';
  static const String _tokenKey = 'auth_token';
  static const String _phoneNumberKey = 'phone_number';
  
  // SharedPreferences instance
  static SharedPreferences? _preferences;
  
  // Init method to initialize SharedPreferences
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // Fungsi untuk menyimpan nomor telepon
  static Future<void> savePhoneNumber(String phoneNumber) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    await prefs.setString(_phoneNumberKey, phoneNumber);
  }
  
  // Fungsi untuk mendapatkan nomor telepon
  static Future<String?> getPhoneNumber() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    return prefs.getString(_phoneNumberKey);
  }

  static Future<void> saveUser(Map<String, dynamic> userData) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    
    try {
      // Normalisasi struktur data sebelum menyimpan
      Map<String, dynamic> normalizedData = {};
      
      // Log untuk debug
      debugPrint('Saving user data with keys: ${userData.keys.join(', ')}');
      
      // Cek struktur data
      if (userData.containsKey('data') && userData['data'] != null) {
        // Format: { data: { ... } }
        normalizedData = {'data': userData['data']};
        debugPrint('Using data structure format');
      } else {
        // Format lainnya, simpan apa adanya
        normalizedData = userData;
        debugPrint('Using direct data format');
      }
      
      // Encode dan simpan
      final userJson = jsonEncode(normalizedData);
      await prefs.setString(_userKey, userJson);
      debugPrint('User data saved successfully');
      
      // Extract and save token
      String? token = _extractTokenFromUserData(userData);
      if (token != null) {
        await saveToken(token);
        debugPrint('Token extracted and saved');
      } else {
        debugPrint('No token found in user data');
      }
    } catch (e) {
      debugPrint('Error saving user data: $e');
      // Fallback: coba simpan data asli
      try {
        final userJson = jsonEncode(userData);
        await prefs.setString(_userKey, userJson);
        debugPrint('User data saved using fallback method');
      } catch (e) {
        debugPrint('Failed to save user data even with fallback: $e');
      }
    }
  }

  // Ekstrak token dari berbagai format data user
  static String? _extractTokenFromUserData(Map<String, dynamic> userData) {
    String? token;
    
    // Cek berbagai kemungkinan struktur data
    if (userData.containsKey('access_token') && userData['access_token'] != null) {
      token = userData['access_token'];
    } else if (userData.containsKey('data')) {
      if (userData['data'] is Map) {
        final data = userData['data'];
        if (data.containsKey('access_token') && data['access_token'] != null) {
          token = data['access_token'];
        }
      }
    } else if (userData.containsKey('token')) {
      token = userData['token'];
    }
    
    return token;
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        final decoded = jsonDecode(userJson);
        debugPrint('UserPreferences.getUser() returning data with keys: ${(decoded as Map<String, dynamic>).keys.join(', ')}');
        
        // Cek apakah struktur data valid
        if (decoded is Map<String, dynamic>) {
          // Cek apakah ada data user
          bool hasUserData = false;
          
          if (decoded.containsKey('data') && decoded['data'] != null) {
            if (decoded['data'] is Map && decoded['data'].containsKey('user')) {
              hasUserData = true;
            }
          } else if (decoded.containsKey('user') && decoded['user'] != null) {
            hasUserData = true;
          }
          
          if (!hasUserData) {
            debugPrint('PERINGATAN: Data user tidak ditemukan dalam format yang diharapkan');
          }
        }
        
        return decoded;
      } catch (e) {
        debugPrint('Error decoding user data: $e');
        return null;
      }
    }
    debugPrint('UserPreferences.getUser() returning null');
    return null;
  }
  
  // Fungsi untuk menyimpan token
  static Future<void> saveToken(String token) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    
    // Pastikan format token konsisten
    String formattedToken = token;
    if (!token.startsWith('Bearer ')) {
      formattedToken = 'Bearer $token';
    } else if (token.startsWith('Bearer Bearer')) {
      // Fix double Bearer issue
      formattedToken = 'Bearer ' + token.substring('Bearer Bearer '.length);
    }
    
    await prefs.setString(_tokenKey, formattedToken);
    
    // Update juga di TokenJWT untuk kompatibilitas
    await TokenJwt.saveToken(formattedToken);
    
    debugPrint('Token saved successfully: ${formattedToken.substring(0, Math.min(20, formattedToken.length))}...');
  }
  
  // Mendapatkan token dari data user
  static Future<String?> getToken() async {
    try {
      // Pertama coba ambil dari _tokenKey langsung
      final prefs = _preferences ?? await SharedPreferences.getInstance();
      final directToken = prefs.getString(_tokenKey);
      
      if (directToken != null && directToken.isNotEmpty) {
        debugPrint('Retrieved token from preferences: ${directToken.substring(0, Math.min(20, directToken.length))}...');
        // Format token sesuai kebutuhan Laravel Sanctum
        String formattedToken = directToken;
        if (!directToken.startsWith('Bearer ')) {
          formattedToken = 'Bearer $directToken';
        } else if (directToken.startsWith('Bearer Bearer')) {
          // Fix double Bearer issue
          formattedToken = 'Bearer ' + directToken.substring('Bearer Bearer '.length);
          // Save the corrected token
          await saveToken(formattedToken);
        }
        return formattedToken;
      }
      
      // Jika tidak ada, coba ambil dari data user
      final userData = await getUser();
      if (userData != null) {
        String? token = _extractTokenFromUserData(userData);
        
        if (token != null && token.isNotEmpty) {
          // Simpan token untuk penggunaan berikutnya
          await saveToken(token);
          
          // Format token sesuai kebutuhan Laravel Sanctum
          if (!token.startsWith('Bearer ')) {
            token = 'Bearer $token';
          } else if (token.startsWith('Bearer Bearer')) {
            // Fix double Bearer issue
            token = 'Bearer ' + token.substring('Bearer Bearer '.length);
          }
          debugPrint('Retrieved token from user data: ${token.substring(0, Math.min(20, token.length))}...');
          return token;
        }
      }
      
      // Jika masih tidak ada, coba ambil dari TokenJWT
      final tokenJwt = await TokenJwt.getToken();
      if (tokenJwt != null && tokenJwt.isNotEmpty) {
        debugPrint('Retrieved token from TokenJWT: ${tokenJwt.substring(0, Math.min(20, tokenJwt.length))}...');
      } else {
        debugPrint('No token found in any storage');
      }
      return tokenJwt;
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }
  
  // Fungsi untuk refresh token
  static Future<String?> refreshToken() async {
    try {
      final currentToken = await getToken();
      if (currentToken == null) {
        debugPrint('No token to refresh');
        return null;
      }
      
      debugPrint('Attempting to refresh token: ${currentToken.substring(0, Math.min(20, currentToken.length))}...');
      
      // Panggil endpoint refresh token
      final response = await http.post(
        Server.urlLaravel('mobile/users/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': currentToken
        }
      );
      
      debugPrint('Refresh token response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success' && responseData['data'] != null && 
            responseData['data']['access_token'] != null) {
          final newToken = responseData['data']['access_token'];
          await saveToken(newToken);
          debugPrint('Token refreshed successfully: ${newToken.substring(0, Math.min(20, newToken.length as int))}...');
          return 'Bearer $newToken';
        } else {
          debugPrint('Invalid refresh token response: ${response.body}');
        }
      } else if (response.statusCode == 401) {
        // Token tidak valid, mungkin perlu login ulang
        debugPrint('Token invalid (401), user may need to login again');
        // Hapus token yang tidak valid
        await clearToken();
      } else {
        debugPrint('Failed to refresh token: ${response.statusCode}, ${response.body}');
      }
      
      return null; // Return null jika refresh gagal
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return null;
    }
  }

  static Future<void> removeUser() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    // Juga hapus token
    await clearToken();
  }

  static Future<void> updateUser(Map<String, dynamic> updatedUserData) async {
    await saveUser(updatedUserData);
  }

  static Future<void> saveFcmToken(String token) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
  }

  static Future<String?> getFcmToken() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }

  static Future<void> removeFcmToken() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    await prefs.remove(_fcmTokenKey);
  }

  // Methods for FCM token (alias untuk kompatibilitas)
  static Future<void> setFCMToken(String token) async {
    await saveFcmToken(token);
  }

  static Future<String?> getFCMToken() async {
    return getFcmToken();
  }
  
  // Fungsi untuk menghapus token
  static Future<void> clearToken() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    
    // Hapus juga token dari TokenJWT
    await TokenJwt.clearToken();
    
    debugPrint('Token cleared successfully');
  }
  
  // Fungsi untuk menghapus data user
  static Future<void> clearUser() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await clearToken();
    
    debugPrint('User data cleared successfully');
  }
}

// CARA UBAH PROFIL
// Future<void> updateProfile(Map<String, dynamic> newProfileData) async {
//   final response = await http.post(
//     Uri.parse('https://example.com/api/update-profile'),
//     body: newProfileData,
//   );

//   final result = jsonDecode(response.body);
//   if (result['status'] == 'success') {
//     // Update shared preferences dengan data terbaru dari server
//     await UserPreferences.updateUser(result['data']);
//     print('Profil diperbarui dan disimpan ulang di SharedPreferences');
//   } else {
//     print('Gagal update: ${result['message']}');
//   }
// }
