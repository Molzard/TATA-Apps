import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class Server {
  // Singleton HTTP Client dengan konfigurasi optimal
  static http.Client? _httpClient;
  static final Map<String, dynamic> _cache = {};
  
  static http.Client get httpClient {
    if (_httpClient == null) {
      _httpClient = http.Client();
    }
    return _httpClient!;
  }
  
  static void closeHttpClient() {
    _httpClient?.close();
    _httpClient = null;
  }

  // URL yang berbeda berdasarkan platform
  static const String ROUTE = kIsWeb
      ? "https://tata-apps.mazkama.web.id/api/"
      : "https://tata-apps.mazkama.web.id/api/";
  static const bool isDevelopment = true;

  static Uri urlLaravel(String url) {
    // Handle chat routes specially
    if (url.startsWith("chat/")) {
      return Uri.parse("${ROUTE}mobile/$url");
    }
    
    // Handle other routes
    if (!url.startsWith("mobile/") && !url.contains("auth/")) {
      if (url == "users/register" || url == "users/login" || url == "users/check-email" || 
          url == "users/forgot-password" || url.startsWith("users/")) {
        return Uri.parse("${ROUTE}mobile/$url");
      }
      if (url == "user/profile") {
        return Uri.parse("${ROUTE}mobile/$url");
      }
      return Uri.parse("${ROUTE}mobile/$url");
    }
    return Uri.parse("${ROUTE}$url");
  }

  // Method optimized GET dengan cache dan fallback
  static Future<Map<String, dynamic>> getJasaData(String jasaId) async {
    final cacheKey = 'jasa_$jasaId';
    
    // Return cache immediately if available
    if (_cache.containsKey(cacheKey)) {
      print('Returning cached data for $jasaId');
      return _cache[cacheKey];
    }

    // Return dummy data immediately, then try to fetch real data in background
    final dummyData = _getDummyJasaData(jasaId);
    _cache[cacheKey] = dummyData;

    // Try to fetch real data in background (don't await)
    _fetchRealDataInBackground(jasaId, cacheKey);

    return dummyData;
  }

  static void _fetchRealDataInBackground(String jasaId, String cacheKey) async {
    try {
      print('Fetching real data for $jasaId in background...');
      
      final response = await httpClient.get(
        urlLaravel('jasa/$jasaId'),
        headers: {
          'Accept': 'application/json',
          'Connection': 'keep-alive',
        },
      ).timeout(
        const Duration(seconds: 5), // Timeout sangat pendek
        onTimeout: () {
          print('Background fetch timeout for $jasaId');
          return http.Response('{"message":"timeout"}', 408);
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          print('Successfully fetched real data for $jasaId');
          _cache[cacheKey] = jsonData['data'];
          // Notify listeners if needed (implement with streams/notifiers)
        }
      }
    } catch (e) {
      print('Background fetch failed for $jasaId: $e');
      // Keep using dummy data
    }
  }

  static Map<String, dynamic> _getDummyJasaData(String jasaId) {
    switch (jasaId) {
      case '1': // Logo
        return {
          'jasa': {'kategori': 'Logo', 'id_jasa': '1'},
          'paket_jasa': [
            {
              'id_paket_jasa': '1',
              'id_jasa': '1',
              'kelas_jasa': 'basic',
              'harga_paket_jasa': '100000',
              'waktu_pengerjaan': '3 hari',
              'maksimal_revisi': '2',
            },
            {
              'id_paket_jasa': '2',
              'id_jasa': '1',
              'kelas_jasa': 'standard',
              'harga_paket_jasa': '250000',
              'waktu_pengerjaan': '5 hari',
              'maksimal_revisi': '5',
            },
            {
              'id_paket_jasa': '3',
              'id_jasa': '1',
              'kelas_jasa': 'premium',
              'harga_paket_jasa': '500000',
              'waktu_pengerjaan': '7 hari',
              'maksimal_revisi': '10',
            }
          ]
        };
      case '2': // Banner
        return {
          'jasa': {'kategori': 'Banner', 'id_jasa': '2'},
          'paket_jasa': [
            {
              'id_paket_jasa': '4',
              'id_jasa': '2',
              'kelas_jasa': 'basic',
              'harga_paket_jasa': '150000',
              'waktu_pengerjaan': '3 hari',
              'maksimal_revisi': '2',
            },
            {
              'id_paket_jasa': '5',
              'id_jasa': '2',
              'kelas_jasa': 'standard',
              'harga_paket_jasa': '300000',
              'waktu_pengerjaan': '5 hari',
              'maksimal_revisi': '5',
            },
            {
              'id_paket_jasa': '6',
              'id_jasa': '2',
              'kelas_jasa': 'premium',
              'harga_paket_jasa': '450000',
              'waktu_pengerjaan': '7 hari',
              'maksimal_revisi': '10',
            }
          ]
        };
      case '3': // Poster
        return {
          'jasa': {'kategori': 'Poster', 'id_jasa': '3'},
          'paket_jasa': [
            {
              'id_paket_jasa': '7',
              'id_jasa': '3',
              'kelas_jasa': 'basic',
              'harga_paket_jasa': '100000',
              'waktu_pengerjaan': '3 hari',
              'maksimal_revisi': '2',
            },
            {
              'id_paket_jasa': '8',
              'id_jasa': '3',
              'kelas_jasa': 'standard',
              'harga_paket_jasa': '200000',
              'waktu_pengerjaan': '5 hari',
              'maksimal_revisi': '5',
            },
            {
              'id_paket_jasa': '9',
              'id_jasa': '3',
              'kelas_jasa': 'premium',
              'harga_paket_jasa': '350000',
              'waktu_pengerjaan': '7 hari',
              'maksimal_revisi': '10',
            }
          ]
        };
      default:
        return {
          'jasa': {'kategori': 'Unknown', 'id_jasa': jasaId},
          'paket_jasa': []
        };
    }
  }

  // Fix untuk image profil dengan fallback yang lebih baik
  static String UrlImageProfil(String? url) {
    // Jika URL kosong atau null, return default
    if (url == null || url.isEmpty) {
      return "assets/images/logotext.png";
    }
    
    // Jika URL sudah berupa Google profile URL langsung
    if (url.startsWith('https://lh3.googleusercontent.com/')) {
      if (kIsWeb) {
        // Untuk web, gunakan image proxy khusus untuk Google image
        return "http://localhost:8000/image-proxy.php?type=external&url=${Uri.encodeComponent(url)}";
      } else {
        // Untuk mobile, gunakan langsung URL Google
        return url;
      }
    }
    
    // Untuk URL eksternal lainnya
    if (url.startsWith('http://') || url.startsWith('https://')) {
      if (kIsWeb) {
        // Untuk web, gunakan image proxy untuk URL eksternal
        return "http://localhost:8000/image-proxy.php?type=external&url=${Uri.encodeComponent(url)}";
      } else {
        return url; // Gunakan langsung di mobile
      }
    }
    
    // Untuk file lokal
    if (isDevelopment) {
      if (kIsWeb) {
        return "http://localhost:8000/image-proxy.php?type=user&file=${Uri.encodeComponent(url)}";
      } else {
        return "http://localhost:8000/assets3/img/user/$url";
      }
    } else {
      return "https://tata-test.my.id/assets3/img/user/$url";
    }
  }

  // Rest of your existing methods...
  static String UrlImageReferensi(String uuid, String url) {
    if (url == null || url.isEmpty) {
      return "";
    }
    
    final cleanUuid = uuid.replaceAll("#", "");
    
    if (isDevelopment) {
      if (kIsWeb) {
        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final isHasilDesain = url.contains("jpg") || url.contains("jpeg") || url.contains("png") || url.contains("_");
          final folderPath = isHasilDesain ? "hasil_desain" : "catatan_pesanan";
          
          return "http://localhost:8000/image-proxy.php?type=pesanan&uuid=$cleanUuid&file=$url&folder=$folderPath&t=$timestamp";
        } catch (e) {
          print("Error generating image URL: $e");
          return "";
        }
      }
      
      final isHasilDesain = url.contains("jpg") || url.contains("jpeg") || url.contains("png") || url.contains("_");
      final folderPath = isHasilDesain ? "hasil_desain" : "catatan_pesanan";
      
      return "http://localhost:8000/assets3/img/pesanan/$cleanUuid/$folderPath/$url";
    } else {
      final isHasilDesain = url.contains("jpg") || url.contains("jpeg") || url.contains("png") || url.contains("_");
      final folderPath = isHasilDesain ? "hasil_desain" : "catatan_pesanan";
      
      return "https://tata-test.my.id/assets3/img/pesanan/$cleanUuid/$folderPath/$url";
    }
  }

  static String UrlGambar(String url) {
    // Pastikan tidak ada duplikasi path "assets/"
    if (url.startsWith("assets/")) {
      return url;
    }
    return "assets/images/$url";
  }
}
