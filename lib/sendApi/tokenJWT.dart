import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as Math;

class TokenJwt {
  static const String _tokenKey = 'token_key';
  static const String _emailKey = 'email_key';

  // Simpan token
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Simpan token lengkap termasuk Bearer prefix
      String formattedToken = token;
      if (!token.startsWith('Bearer ') && token.isNotEmpty) {
        formattedToken = 'Bearer $token';
      }
      
      await prefs.setString(_tokenKey, formattedToken);
      debugPrint("Stored token in TokenJWT: ${formattedToken.substring(0, Math.min(20, formattedToken.length))}...");
    } catch (e) {
      debugPrint("Error saving token: $e");
    }
  }

  // Ambil token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      
      // Jika token tidak ada/kosong
      if (token == null || token.isEmpty) {
        debugPrint("No token found in TokenJWT");
        return null;
      }
      
      // Pastikan token memiliki format Bearer
      String formattedToken = token;
      if (!token.startsWith('Bearer ')) {
        formattedToken = 'Bearer $token';
      } else {
        // Jika token sudah memiliki Bearer, pastikan formatnya benar
        // Kadang-kadang token bisa memiliki format "Bearer Bearer token"
        if (token.startsWith('Bearer Bearer')) {
          formattedToken = 'Bearer ' + token.substring('Bearer Bearer '.length);
          // Simpan token yang sudah diperbaiki
          await saveToken(formattedToken);
        }
      }
      
      debugPrint("Retrieved token from TokenJWT: ${formattedToken.substring(0, Math.min(20, formattedToken.length))}...");
      return formattedToken;
    } catch (e) {
      debugPrint("Error getting token: $e");
      return null;
    }
  }

  // Cek apakah token ada
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Hapus token
  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      debugPrint("Token cleared from TokenJWT");
    } catch (e) {
      debugPrint("Error clearing token: $e");
    }
  }

  static Future<void> saveEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_emailKey, email);
      debugPrint("Email saved: $email");
    } catch (e) {
      debugPrint("Error saving email: $e");
    }
  }

  // Ambil email
  static Future<String?> getEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_emailKey);
      if (email == null || email.isEmpty) {
        debugPrint("No email found in TokenJWT");
      } else {
        debugPrint("Retrieved email: $email");
      }
      return email;
    } catch (e) {
      debugPrint("Error getting email: $e");
      return null;
    }
  }

  // Hapus email
  static Future<void> clearEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emailKey);
      debugPrint("Email cleared");
    } catch (e) {
      debugPrint("Error clearing email: $e");
    }
  }
}
