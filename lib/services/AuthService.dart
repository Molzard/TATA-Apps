import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:TATA/helper/user_preferences.dart';
import 'package:TATA/helper/fcm_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as Math;
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/sendApi/tokenJWT.dart';
import 'package:flutter/material.dart';
import 'package:TATA/main.dart'; // Import untuk navigatorKey

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '244660030535-lodn72p8i6c0e8ufni92k9lorfqsrffc.apps.googleusercontent.com' : null,
  );
  
  // Stream untuk status autentikasi
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Mendapatkan user saat ini
  User? get currentUser => _auth.currentUser;
  
  // Login dengan email dan password
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      // Login ke Firebase
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password
      );
      
      // Jika berhasil, login ke backend Laravel
      await _signInToLaravel(email, password);
      
      // Update FCM token
      await FCMHelper().updateFCMToken();
      
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      
      // Jika error invalid-credential, coba sinkronisasi
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        // Cek apakah user ada di Laravel dengan password ini
        try {
          final response = await http.post(
            Server.urlLaravel('mobile/users/verify-credentials'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          );
          
          if (response.statusCode == 200) {
            // Password benar di Laravel tapi salah di Firebase
            // Kirim reset email Firebase
            await _auth.sendPasswordResetEmail(email: email);
            throw FirebaseAuthException(
              code: 'password-mismatch',
              message: 'Password tidak sinkron. Email reset telah dikirim.'
            );
          }
        } catch (httpError) {
          debugPrint('Error verifying Laravel credentials: $httpError');
        }
      }
      
      rethrow;
    } catch (e) {
      debugPrint('Error signing in with email/password: $e');
      rethrow;
    }
  }
  
  // Registrasi dengan email dan password
  Future<UserCredential> registerWithEmailPassword(String name, String email, String password) async {
    try {
      // Registrasi ke Firebase
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password
      );
      
      // Update display name
      await credential.user?.updateDisplayName(name);
      
      // Registrasi ke backend Laravel
      await _registerToLaravel(name, email, password);
      
      // Update FCM token (tangani error jika ada)
      try {
        await FCMHelper().updateFCMToken();
      } catch (e) {
        debugPrint('Error updating FCM token during registration: $e');
        // Lanjutkan proses registrasi meskipun FCM gagal
      }
      
      return credential;
    } catch (e) {
      debugPrint('Error registering with email/password: $e');
      rethrow;
    }
  }
  
  // Login dengan Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign in aborted');
      }
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Login atau registrasi ke backend Laravel
      await _signInOrRegisterWithGoogleToLaravel(
        userCredential.user?.displayName ?? '',
        userCredential.user?.email ?? '',
        googleAuth.idToken ?? ''
      );
      
      // Update FCM token
      await FCMHelper().updateFCMToken();
      
      return userCredential;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }
  
  // Logout
  Future<void> signOut() async {
    try {
      // Logout dari backend Laravel
      await _signOutFromLaravel();
      
      // Logout dari Google jika digunakan
      await _googleSignIn.signOut();
      
      // Logout dari Firebase
      await _auth.signOut();
      
      // Hapus data user lokal
      await UserPreferences.clearUser();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }
  
  // Tambahkan di AuthService.dart
  Future<void> resetFirebasePassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Firebase reset email sent to $email');
    } catch (e) {
      debugPrint('Error sending reset email: $e');
      throw e;
    }
  }
  
  // Verifikasi email
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      debugPrint('Error sending email verification: $e');
      rethrow;
    }
  }
  
  // Login ke backend Laravel
  Future<void> _signInToLaravel(String email, String password) async {
    try {
      debugPrint('Login to Laravel: $email');
      final response = await http.post(
        Server.urlLaravel('mobile/users/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Login response: $data');
        
        // Reset token terlebih dahulu
        await UserPreferences.clearToken();
        await TokenJwt.clearToken();
        
        // Pastikan struktur data konsisten
        String token = '';
        
        // Cek struktur data yang benar
        if (data.containsKey('data') && data['data'].containsKey('access_token')) {
          token = data['data']['access_token'];
          debugPrint('Token from data.access_token: $token');
        } else if (data.containsKey('access_token')) {
          token = data['access_token'];
          debugPrint('Token from access_token: $token');
        }
        
        // Simpan token dengan format Bearer
        if (token.isNotEmpty) {
          if (!token.startsWith('Bearer ')) {
            token = 'Bearer $token';
          }
          debugPrint('Saving token: $token');
          await UserPreferences.saveToken(token);
          await TokenJwt.saveToken(token);
        } else {
          debugPrint('Warning: No token found in response');
        }
        
        // Simpan data user
        await UserPreferences.saveUser(data);
        
        // Update FCM token setelah login berhasil
        await FCMHelper().updateFCMToken();
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to login to server');
      }
    } catch (e) {
      debugPrint('Error signing in to Laravel: $e');
      rethrow;
    }
  }
  
  // Fungsi untuk refresh token
  Future<bool> refreshToken() async {
    try {
      debugPrint('Attempting to refresh token');
      final currentToken = await UserPreferences.getToken();
      
      if (currentToken == null || currentToken.isEmpty) {
        debugPrint('No token available for refresh');
        return false;
      }
      
      final response = await http.post(
        Server.urlLaravel('mobile/users/refresh-token'),
        headers: {
          'Authorization': currentToken,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      debugPrint('Refresh token response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Refresh token response: $data');
        
        String token = '';
        if (data.containsKey('access_token')) {
          token = data['access_token'];
        } else if (data.containsKey('data') && data['data'].containsKey('access_token')) {
          token = data['data']['access_token'];
        }
        
        if (token.isNotEmpty) {
          if (!token.startsWith('Bearer ')) {
            token = 'Bearer $token';
          }
          
          // Simpan token baru
          await UserPreferences.saveToken(token);
          await TokenJwt.saveToken(token);
          
          debugPrint('Token refreshed successfully');
          return true;
        }
      }
      
      debugPrint('Failed to refresh token');
      return false;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return false;
    }
  }
  
  // Fungsi untuk verifikasi token
  Future<bool> verifyToken() async {
    try {
      final token = await UserPreferences.getToken();
      
      if (token == null || token.isEmpty) {
        debugPrint('No token to verify');
        return false;
      }
      
      final response = await http.get(
        Server.urlLaravel('mobile/user/profile'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      debugPrint('Verify token response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        debugPrint('Token is valid');
        return true;
      } else if (response.statusCode == 401) {
        debugPrint('Token is invalid or expired, trying to refresh');
        return await refreshToken();
      } else {
        debugPrint('Unexpected response when verifying token: ${response.statusCode}');
        if (response.statusCode == 500) {
          debugPrint('User tidak terautentikasi, mengarahkan ke halaman login');
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/login', 
            (route) => false
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error verifying token: $e');
      return false;
    }
  }
  
  // Registrasi ke backend Laravel
  Future<void> _registerToLaravel(String name, String email, String password) async {
    try {
      debugPrint('Registering to Laravel: $email');
      final response = await http.post(
        Server.urlLaravel('mobile/users/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'nama_user': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
          'no_telpon': await UserPreferences.getPhoneNumber() ?? '', // Ambil nomor telepon dari preferences
        }),
      );
      
      debugPrint('Register response status: ${response.statusCode}');
      debugPrint('Register response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('Register response: $data');
        
        // Pastikan struktur data konsisten
        String token = '';
        if (data.containsKey('access_token')) {
          token = data['access_token'];
        } else if (data.containsKey('data') && data['data'].containsKey('access_token')) {
          token = data['data']['access_token'];
        }
        
        // Simpan token dengan format Bearer
        if (token.isNotEmpty) {
          if (!token.startsWith('Bearer ')) {
            token = 'Bearer $token';
          }
          await UserPreferences.saveToken(token);
        }
        
        // Simpan data user
        await UserPreferences.saveUser(data);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to register to server');
      }
    } catch (e) {
      debugPrint('Error registering to Laravel: $e');
      rethrow;
    }
  }
  
  // Login atau registrasi dengan Google ke backend Laravel
  Future<void> _signInOrRegisterWithGoogleToLaravel(String name, String email, String idToken) async {
    try {
      // Get current Firebase user to access photo URL
      final User? user = FirebaseAuth.instance.currentUser;
      final String? photoURL = user?.photoURL;
      
      debugPrint('Google login to Laravel: $email');
      final response = await http.post(
        Server.urlLaravel('mobile/users/login-google'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'id_token': idToken,
          'photo': photoURL ?? '', // Include user's photo URL from Google, use empty string if null
        }),
      );
      
      debugPrint('Google login response status: ${response.statusCode}');
      debugPrint('Google login response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Google login response: $data');
        
        // Pastikan struktur data konsisten
        String token = '';
        if (data.containsKey('access_token')) {
          token = data['access_token'];
          debugPrint('Token ditemukan di access_token');
        } else if (data.containsKey('data') && data['data'].containsKey('access_token')) {
          token = data['data']['access_token'];
          debugPrint('Token ditemukan di data.access_token');
        }
        
        // Simpan token dengan format Bearer
        if (token.isNotEmpty) {
          if (!token.startsWith('Bearer ')) {
            token = 'Bearer $token';
          }
          await UserPreferences.saveToken(token);
          await TokenJwt.saveToken(token);
          debugPrint('Stored token in TokenJWT: ${token.substring(0, Math.min(20, token.length))}...');
          debugPrint('Token saved successfully: ${token.substring(0, Math.min(20, token.length))}...');
        } else {
          debugPrint('PERINGATAN: Token tidak ditemukan dalam respons');
        }
        
        // Simpan data user
        try {
          await UserPreferences.saveUser(data);
          debugPrint('Data user berhasil disimpan');
          
          // Verifikasi data tersimpan
          final userData = await UserPreferences.getUser();
          if (userData != null) {
            debugPrint('Verified stored user data: Data tersedia');
            
            // Log struktur data untuk debug
            if (userData.containsKey('data') && userData['data'] != null) {
              debugPrint('Data struktur: data ada');
              if (userData['data'].containsKey('user') && userData['data']['user'] != null) {
                debugPrint('Data struktur: data.user ada');
                final userId = userData['data']['user']['id'];
                debugPrint('User ID: $userId');
              }
            } else if (userData.containsKey('user') && userData['user'] != null) {
              debugPrint('Data struktur: user ada');
              final userId = userData['user']['id'];
              debugPrint('User ID: $userId');
            } else {
              debugPrint('PERINGATAN: Format data tidak sesuai ekspektasi: ${userData.keys.join(', ')}');
            }
          } else {
            debugPrint('PERINGATAN: Data user tidak tersimpan');
          }
        } catch (e) {
          debugPrint('Error menyimpan data user: $e');
        }
        
        // Simpan email di TokenJWT
        if (email.isNotEmpty) {
          await TokenJwt.saveEmail(email);
          debugPrint('Email saved to TokenJWT: $email');
        }
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to authenticate with Google');
      }
    } catch (e) {
      debugPrint('Error signing in/registering with Google to Laravel: $e');
      rethrow;
    }
  }
  
  // Logout dari backend Laravel
  Future<void> _signOutFromLaravel() async {
    try {
      final token = await UserPreferences.getToken();
      
      if (token != null) {
        await http.post(
          Server.urlLaravel('user/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': token,
          },
        );
      }
    } catch (e) {
      debugPrint('Error signing out from Laravel: $e');
      // Tidak throw error karena logout dari Firebase tetap harus dilakukan
    }
  }

  // Check if email exists
  Future<bool> checkEmailExists(String email) async {
    try {
      // First, try to check with Firebase
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        debugPrint('Email ditemukan di Firebase');
        return true;
      }
      
      // If not found in Firebase, check with Laravel backend
      final response = await http.post(
        Server.urlLaravel('mobile/users/check-email'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );
      
      debugPrint('Respons cek email: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] ?? false;
      } else {
        // Handle specific error codes
        debugPrint('Error saat cek email: ${response.statusCode} - ${response.body}');
        
        // Cek apakah pesan error menunjukkan bahwa email sudah ada
        try {
          final data = jsonDecode(response.body);
          if (data['message'] == 'Email sudah digunakan') {
            // Jika pesan error menunjukkan email sudah digunakan, berarti email ada
            debugPrint('Email ditemukan berdasarkan pesan error');
            return true;
          }
        } catch (e) {
          debugPrint('Gagal parse respons JSON: $e');
        }
        
        // Untuk kasus lain, anggap email tidak ada
        return false;
      }
    } catch (e) {
      debugPrint('Terjadi kesalahan saat cek email: $e');
      // Jika terjadi error, anggap email tidak ada dan lanjutkan proses
      return false;
    }
  }

  // Tambahkan fungsi ini di AuthService.dart
  Future<bool> syncPasswordWithFirebase(String email, String newPassword) async {
    try {
      // Coba update password Firebase jika user sudah login
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.email == email) {
        await currentUser.updatePassword(newPassword);
        debugPrint('Firebase password updated successfully');
        return true;
      } else {
        // Jika user belum login, kirim reset email
        await _auth.sendPasswordResetEmail(email: email);
        debugPrint('Firebase reset email sent');
        return false; // Return false karena perlu manual reset
      }
    } catch (e) {
      debugPrint('Error syncing Firebase password: $e');
      // Kirim reset email sebagai fallback
      try {
        await _auth.sendPasswordResetEmail(email: email);
        debugPrint('Fallback: Firebase reset email sent');
      } catch (resetError) {
        debugPrint('Failed to send reset email: $resetError');
      }
      return false;
    }
  }

  // Hybrid login - coba Firebase dulu, kalau gagal coba Laravel
  Future<Map<String, dynamic>> signInWithEmailPasswordHybrid(String email, String password) async {
    debugPrint('Starting hybrid authentication for: $email');
    
    // Strategi 1: Coba Firebase dulu
    try {
      debugPrint('Attempting Firebase authentication...');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password
      );
      
      debugPrint('Firebase authentication successful');
      
      // Jika Firebase berhasil, coba login ke Laravel juga
      try {
        await _signInToLaravel(email, password);
        debugPrint('Laravel authentication also successful');
        
        // Update FCM token
        await FCMHelper().updateFCMToken();
        
        return {
          'status': 'success',
          'method': 'firebase_laravel',
          'message': 'Login berhasil dengan Firebase dan Laravel',
          'credential': credential
        };
      } catch (laravelError) {
        debugPrint('Laravel authentication failed, but Firebase succeeded: $laravelError');
        
        // Firebase berhasil tapi Laravel gagal - tetap lanjutkan dengan Firebase
        return {
          'status': 'success',
          'method': 'firebase_only',
          'message': 'Login berhasil dengan Firebase (Laravel tidak tersinkron)',
          'credential': credential,
          'warning': 'Laravel authentication failed'
        };
      }
    } catch (firebaseError) {
      debugPrint('Firebase authentication failed: $firebaseError');
      
      // Strategi 2: Jika Firebase gagal, coba Laravel
      try {
        debugPrint('Attempting Laravel authentication...');
        final laravelResult = await _signInToLaravelOnly(email, password);
        
        if (laravelResult['status'] == 'success') {
          debugPrint('Laravel authentication successful');
          
          // Laravel berhasil, coba update Firebase password untuk sinkronisasi masa depan
          _attemptFirebasePasswordSync(email, password);
          
          return {
            'status': 'success',
            'method': 'laravel_only',
            'message': 'Login berhasil dengan Laravel (Firebase tidak tersinkron)',
            'data': laravelResult['data'],
            'warning': 'Firebase authentication failed'
          };
        } else {
          throw Exception(laravelResult['message']);
        }
      } catch (laravelError) {
        debugPrint('Both Firebase and Laravel authentication failed');
        
        // Kedua metode gagal
        return {
          'status': 'error',
          'method': 'both_failed',
          'message': 'Email atau password salah',
          'firebase_error': firebaseError.toString(),
          'laravel_error': laravelError.toString()
        };
      }
    }
  }
  
  // Login ke Laravel saja (tanpa Firebase)
  Future<Map<String, dynamic>> _signInToLaravelOnly(String email, String password) async {
    try {
      debugPrint('Laravel-only login for: $email');
      final response = await http.post(
        Server.urlLaravel('mobile/users/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      debugPrint('Laravel response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Simpan token
        String token = '';
        if (data.containsKey('data') && data['data'].containsKey('access_token')) {
          token = data['data']['access_token'];
        } else if (data.containsKey('access_token')) {
          token = data['access_token'];
        }
        
        if (token.isNotEmpty) {
          if (!token.startsWith('Bearer ')) {
            token = 'Bearer $token';
          }
          await UserPreferences.saveToken(token);
          await TokenJwt.saveToken(token);
        }
        
        // Simpan data user
        await UserPreferences.saveUser(data);
        
        // Update FCM token
        try {
          await FCMHelper().updateFCMToken();
        } catch (e) {
          debugPrint('Error updating FCM token: $e');
        }
        
        return {'status': 'success', 'data': data};
      } else {
        final data = jsonDecode(response.body);
        return {'status': 'error', 'message': data['message'] ?? 'Laravel login failed'};
      }
    } catch (e) {
      debugPrint('Error in Laravel-only login: $e');
      return {'status': 'error', 'message': 'Laravel connection error: $e'};
    }
  }
  
  // Coba sinkronisasi password Firebase di background
  Future<void> _attemptFirebasePasswordSync(String email, String password) async {
    try {
      debugPrint('Attempting Firebase password sync for: $email');
      
      // Coba kirim reset password email untuk sinkronisasi
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Firebase password reset email sent for future sync');
    } catch (e) {
      debugPrint('Failed to send Firebase password reset email: $e');
    }
  }
  
  // Registrasi hybrid
  Future<Map<String, dynamic>> registerWithEmailPasswordHybrid(String name, String email, String password) async {
    try {
      debugPrint('Starting hybrid registration for: $email');
      
      // Strategi: Registrasi di Laravel dulu, kemudian Firebase
      try {
        // 1. Registrasi di Laravel
        debugPrint('Attempting Laravel registration...');
        final laravelResult = await _registerToLaravelOnly(name, email, password);
        
        if (laravelResult['status'] != 'success') {
          return laravelResult;
        }
        
        // 2. Jika Laravel berhasil, coba registrasi di Firebase
        try {
          debugPrint('Attempting Firebase registration...');
          final credential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password
          );
          
          // Update display name
          await credential.user?.updateDisplayName(name);
          
          debugPrint('Both Laravel and Firebase registration successful');
          
          return {
            'status': 'success',
            'method': 'laravel_firebase',
            'message': 'Registrasi berhasil di Laravel dan Firebase',
            'credential': credential,
            'data': laravelResult['data']
          };
        } catch (firebaseError) {
          debugPrint('Firebase registration failed, but Laravel succeeded: $firebaseError');
          
          // Laravel berhasil, Firebase gagal - tetap sukses
          return {
            'status': 'success',
            'method': 'laravel_only',
            'message': 'Registrasi berhasil di Laravel (Firebase gagal)',
            'data': laravelResult['data'],
            'warning': 'Firebase registration failed: $firebaseError'
          };
        }
      } catch (laravelError) {
        debugPrint('Laravel registration failed: $laravelError');
        return {
          'status': 'error',
          'message': 'Registrasi gagal: $laravelError'
        };
      }
    } catch (e) {
      debugPrint('Error in hybrid registration: $e');
      return {
        'status': 'error',
        'message': 'Registrasi gagal: $e'
      };
    }
  }
  
  // Registrasi Laravel saja
  Future<Map<String, dynamic>> _registerToLaravelOnly(String name, String email, String password) async {
    try {
      debugPrint('Laravel-only registration for: $email');
      final response = await http.post(
        Server.urlLaravel('mobile/users/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'nama_user': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
          'no_telpon': await UserPreferences.getPhoneNumber() ?? '',
        }),
      );
      
      debugPrint('Laravel registration response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Simpan token jika ada
        String token = '';
        if (data.containsKey('access_token')) {
          token = data['access_token'];
        } else if (data.containsKey('data') && data['data'].containsKey('access_token')) {
          token = data['data']['access_token'];
        }
        
        if (token.isNotEmpty) {
          if (!token.startsWith('Bearer ')) {
            token = 'Bearer $token';
          }
          await UserPreferences.saveToken(token);
          await TokenJwt.saveToken(token);
        }
        
        // Simpan data user
        await UserPreferences.saveUser(data);
        
        return {'status': 'success', 'data': data};
      } else {
        final data = jsonDecode(response.body);
        return {'status': 'error', 'message': data['message'] ?? 'Laravel registration failed'};
      }
    } catch (e) {
      debugPrint('Error in Laravel-only registration: $e');
      return {'status': 'error', 'message': 'Laravel registration error: $e'};
    }
  }
  
  // Google Sign-In hybrid
  Future<Map<String, dynamic>> signInWithGoogleHybrid() async {
    try {
      debugPrint('Starting hybrid Google authentication...');
      
      // 1. Dapatkan kredensial Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return {'status': 'error', 'message': 'Google sign in cancelled'};
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // 2. Coba login ke Firebase dengan Google
      try {
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        final userCredential = await _auth.signInWithCredential(credential);
        debugPrint('Firebase Google authentication successful');
        
        // 3. Coba login/register ke Laravel
        try {
          await _signInOrRegisterWithGoogleToLaravel(
            userCredential.user?.displayName ?? '',
            userCredential.user?.email ?? '',
            googleAuth.idToken ?? ''
          );
          
          return {
            'status': 'success',
            'method': 'firebase_laravel_google',
            'message': 'Google login berhasil di Firebase dan Laravel',
            'credential': userCredential
          };
        } catch (laravelError) {
          debugPrint('Laravel Google authentication failed: $laravelError');
          
          return {
            'status': 'success',
            'method': 'firebase_only_google',
            'message': 'Google login berhasil di Firebase (Laravel gagal)',
            'credential': userCredential,
            'warning': 'Laravel authentication failed'
          };
        }
      } catch (firebaseError) {
        debugPrint('Firebase Google authentication failed: $firebaseError');
        
        // 4. Jika Firebase gagal, coba Laravel saja
        try {
          await _signInOrRegisterWithGoogleToLaravelOnly(
            googleUser.displayName ?? '',
            googleUser.email,
            googleAuth.idToken ?? '',
            googleUser.photoUrl ?? ''
          );
          
          return {
            'status': 'success',
            'method': 'laravel_only_google',
            'message': 'Google login berhasil di Laravel (Firebase gagal)',
            'warning': 'Firebase authentication failed'
          };
        } catch (laravelError) {
          return {
            'status': 'error',
            'message': 'Google login gagal di Firebase dan Laravel',
            'firebase_error': firebaseError.toString(),
            'laravel_error': laravelError.toString()
          };
        }
      }
    } catch (e) {
      debugPrint('Error in hybrid Google authentication: $e');
      return {
        'status': 'error',
        'message': 'Google authentication error: $e'
      };
    }
  }
  
  // Google login ke Laravel saja
  Future<void> _signInOrRegisterWithGoogleToLaravelOnly(String name, String email, String idToken, String photoURL) async {
    try {
      debugPrint('Google login to Laravel only: $email');
      final response = await http.post(
        Server.urlLaravel('mobile/users/login-google'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'id_token': idToken,
          'photo': photoURL,
        }),
      );
      
      debugPrint('Laravel Google response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Simpan token
        String token = '';
        if (data.containsKey('access_token')) {
          token = data['access_token'];
        } else if (data.containsKey('data') && data['data'].containsKey('access_token')) {
          token = data['data']['access_token'];
        }
        
        if (token.isNotEmpty) {
          if (!token.startsWith('Bearer ')) {
            token = 'Bearer $token';
          }
          await UserPreferences.saveToken(token);
          await TokenJwt.saveToken(token);
        }
        
        // Simpan data user
        await UserPreferences.saveUser(data);
        
        // Simpan email
        if (email.isNotEmpty) {
          await TokenJwt.saveEmail(email);
        }
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to authenticate with Google');
      }
    } catch (e) {
      debugPrint('Error in Laravel Google authentication: $e');
      rethrow;
    }
  }
  
  // Reset password hybrid
  Future<Map<String, dynamic>> resetPasswordHybrid(String email, String newPassword) async {
    try {
      debugPrint('Starting hybrid password reset for: $email');
      
      // 1. Update password di Laravel
      try {
        final response = await http.post(
          Server.urlLaravel('mobile/users/change-password'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'password': newPassword,
          }),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'success') {
            debugPrint('Laravel password reset successful');
            
            // 2. Coba kirim reset email Firebase untuk sinkronisasi
            try {
              await _auth.sendPasswordResetEmail(email: email);
              debugPrint('Firebase reset email sent');
              
              return {
                'status': 'success',
                'message': 'Password berhasil diubah. Email reset Firebase telah dikirim untuk sinkronisasi.',
                'method': 'laravel_firebase_reset'
              };
            } catch (firebaseError) {
              debugPrint('Firebase reset email failed: $firebaseError');
              
              return {
                'status': 'success',
                'message': 'Password berhasil diubah di Laravel. Silakan reset password Firebase secara manual jika diperlukan.',
                'method': 'laravel_only_reset',
                'warning': 'Firebase reset email failed'
              };
            }
          } else {
            return data;
          }
        } else {
          final data = jsonDecode(response.body);
          return data;
        }
      } catch (e) {
        debugPrint('Laravel password reset failed: $e');
        return {
          'status': 'error',
          'message': 'Gagal mengubah password: $e'
        };
      }
    } catch (e) {
      debugPrint('Error in hybrid password reset: $e');
      return {
        'status': 'error',
        'message': 'Error reset password: $e'
      };
    }
  }
} 