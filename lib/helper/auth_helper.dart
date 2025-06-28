import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:TATA/helper/user_preferences.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/sendApi/tokenJWT.dart';
import 'package:TATA/services/AuthService.dart';

class AuthHelper {
  static final AuthHelper _instance = AuthHelper._internal();
  factory AuthHelper() => _instance;
  
  AuthHelper._internal();
  
  final AuthService _authService = AuthService();
  
  // Fungsi untuk memeriksa apakah token valid
  Future<bool> isAuthenticated() async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('No token found, user is not authenticated');
        return false;
      }
      
      return await _authService.verifyToken();
    } catch (e) {
      debugPrint('Error checking authentication: $e');
      return false;
    }
  }
  
  // Fungsi untuk melakukan permintaan HTTP dengan token
  Future<http.Response> authenticatedRequest(
    String url,
    {
      String method = 'GET',
      Map<String, String>? headers,
      Object? body,
      bool autoRefresh = true,
    }
  ) async {
    try {
      // Dapatkan token
      String? token = await UserPreferences.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }
      
      // Debug: Print token untuk memastikan format
      debugPrint('Using token for request: ${token.substring(0, min(20, token.length))}...');
      
      // Buat headers dengan token
      final Map<String, String> requestHeaders = {
        'Authorization': token, // Token sudah dalam format "Bearer xxx"
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      // Tambahkan headers tambahan jika ada
      if (headers != null) {
        requestHeaders.addAll(headers);
      }
      
      // Debug: Print headers
      debugPrint('Request headers: $requestHeaders');
      
      // Lakukan permintaan HTTP
      http.Response response;
      final Uri uri = Server.urlLaravel(url);
      
      debugPrint('Making request to: $uri');
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(uri, headers: requestHeaders, body: body);
          break;
        case 'PUT':
          response = await http.put(uri, headers: requestHeaders, body: body);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: requestHeaders);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      // Jika respons adalah 401 Unauthorized, coba refresh token dan coba lagi
      if (response.statusCode == 401 && autoRefresh) {
        debugPrint('Got 401, attempting to refresh token');
        final refreshed = await _authService.refreshToken();
        
        if (refreshed) {
          // Dapatkan token baru
          token = await UserPreferences.getToken();
          requestHeaders['Authorization'] = token!;
          
          // Coba lagi dengan token baru
          switch (method.toUpperCase()) {
            case 'GET':
              response = await http.get(uri, headers: requestHeaders);
              break;
            case 'POST':
              response = await http.post(uri, headers: requestHeaders, body: body);
              break;
            case 'PUT':
              response = await http.put(uri, headers: requestHeaders, body: body);
              break;
            case 'DELETE':
              response = await http.delete(uri, headers: requestHeaders);
              break;
          }
        }
      }
      
      return response;
    } catch (e) {
      debugPrint('Error in authenticated request: $e');
      rethrow;
    }
  }
  
  // Fungsi untuk logout
  Future<void> logout() async {
    try {
      // Hapus token dari penyimpanan
      await UserPreferences.clearToken();
      await TokenJwt.clearToken();
      
      // Logout dari Firebase jika perlu
      await _authService.signOut();
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }
} 