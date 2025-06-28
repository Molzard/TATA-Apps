import 'dart:developer';

import 'package:TATA/helper/user_preferences.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class RatingPage extends StatefulWidget {
  final String uuid;
  const RatingPage({super.key, required this.uuid});

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  int rating = 0;
  final TextEditingController commentController = TextEditingController();
  bool _isSubmitting = false;

  void submitRating() async {
    final komentar = commentController.text.trim();
    
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Silakan beri rating terlebih dahulu!'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    
    if (komentar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Silakan isi komentar Anda!'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    
    if (widget.uuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ID pesanan tidak valid!'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    await _submitReviewWithRetry();
  }
  
  Future<void> _submitReviewWithRetry() async {
    try {
      // Coba pertama kali
      final result = await _sendReview();
      if (result) {
        // Berhasil
        _showSuccessDialog();
        return;
      }
      
      // Jika gagal, coba refresh token dan kirim lagi
      log('First attempt failed, trying to refresh token and retry...');
      final newToken = await UserPreferences.refreshToken();
      if (newToken != null) {
        log('Token refreshed, retrying submission...');
        final retryResult = await _sendReview(token: newToken);
        if (retryResult) {
          _showSuccessDialog();
          return;
        }
        } else {
        log('Token refresh failed, user may need to login again');
        // Tampilkan pesan untuk login ulang
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Sesi Anda telah berakhir. Silakan login kembali.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 5),
          ));
          
          // Tunggu sebentar agar pesan snackbar terlihat
          await Future.delayed(const Duration(seconds: 2));
          
          // Kembali ke halaman sebelumnya
          if (mounted) {
            Navigator.of(context).pop();
          }
          return;
        }
      }
      
      // Jika masih gagal, tampilkan pesan error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal mengirim review. Silakan coba lagi nanti.'),
          backgroundColor: Colors.redAccent,
        ));
      }
      
      } catch (e) {
      log('Error in _submitReviewWithRetry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  
  Future<bool> _sendReview({String? token}) async {
    try {
      final authToken = token ?? await UserPreferences.getToken();
      log('Token untuk review: ${authToken?.substring(0, 20)}...');
      
      if (authToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Silakan login terlebih dahulu!'),
            backgroundColor: Colors.redAccent,
          ));
        }
        return false;
      }
      
      final url = Server.urlLaravel('mobile/pesanan/review/add-by-uuid');
      log('Sending review to: $url');
      
      final payload = {
        'uuid': widget.uuid,
        'review': commentController.text.trim(),
        'rating': rating,
      };
      log('Review payload: $payload');
      
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': authToken
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );

      log('Review response status: ${response.statusCode}');
      log('Review response body: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          log('Review submitted successfully');
          return true;
        } else {
          log('Server returned success code but status is not success: ${responseData['message']}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(responseData['message'] ?? 'Terjadi kesalahan'),
              backgroundColor: Colors.redAccent,
            ));
          }
          return false;
        }
      } else if (response.statusCode == 403) {
        // Handle 403 Forbidden specifically
        final responseData = json.decode(response.body);
        log('403 Forbidden: ${responseData['message'] ?? 'No message'}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(responseData['message'] ?? 'Pesanan belum bisa direview'),
            backgroundColor: Colors.redAccent,
          ));
        }
        return false;
      } else if (response.statusCode == 401) {
        // Token tidak valid, perlu refresh
        log('Token tidak valid (401), perlu refresh');
        return false;
      } else if (response.statusCode == 422) {
        // Validation error
        final responseData = json.decode(response.body);
        log('Validation error: ${responseData['errors']}');
        String errorMessage = 'Validasi gagal';
        if (responseData['errors'] != null) {
          // Extract first error message
          final errors = responseData['errors'];
          if (errors is Map && errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMessage = firstError.first.toString();
            }
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ));
        }
        return false;
      } else if (response.statusCode == 409) {
        // Review sudah ada
        final responseData = json.decode(response.body);
        log('Review already exists: ${responseData['message']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(responseData['message'] ?? 'Review sudah pernah diberikan'),
            backgroundColor: Colors.orange,
          ));
        }
        return false;
      } else {
        // Other errors
        String message = 'Terjadi kesalahan';
        try {
          final responseData = json.decode(response.body);
          message = responseData['message'] ?? 'Terjadi kesalahan';
        } catch (e) {
          log('Error parsing response body: $e');
        }
        log('Error response: $message (${response.statusCode})');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$message (${response.statusCode})'),
            backgroundColor: Colors.redAccent,
          ));
        }
        return false;
      }
    } catch (e) {
      log('Error saat submit review: $e');
      return false;
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 70,
              ),
              const SizedBox(height: 20),
              const Text(
                'Terima Kasih!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Review Anda sangat berharga bagi kami untuk meningkatkan layanan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColors.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Kembali',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Gradien berdasarkan rating
  List<Color> getGradientColors() {
    switch (rating) {
      case 1:
        return [Colors.red.shade300, Colors.pink.shade100];
      case 2:
        return [Colors.deepOrange.shade400, Colors.pink.shade200];
      case 3:
        return [Colors.orange.shade300, Colors.yellow.shade200];
      case 4:
        return [Colors.lime.shade200, Colors.lightGreen.shade300];
      case 5:
        return [Colors.teal.shade300, Colors.cyan.shade200];
      default:
        return [Colors.grey.shade200, Colors.grey.shade100];
    }
  }

  Color getStarColor() {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.deepOrange;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.green;
      case 5:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Nilai Pekerjaan',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: AnimatedContainer(
        height: double.infinity,
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: getGradientColors(),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),

                // Bintang
                const Text(
                  'Beri Penilaian:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: IconButton(
                        iconSize: 48,
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color:
                              index < rating ? getStarColor() : Colors.black26,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // Komentar
                const Text(
                  'Tulis Komentar:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: TextField(
                    controller: commentController,
                    maxLines: 6,
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Tuliskan pengalaman kamu dengan layanan ini...',
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Tombol Kirim
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : submitRating,
                    label: _isSubmitting 
                      ? const Text(
                          'Mengirim...',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        )
                      : const Text(
                      'Kirim Penilaian',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    icon: _isSubmitting
                      ? Container(
                          width: 20,
                          height: 20,
                          padding: const EdgeInsets.all(2),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                    iconAlignment: IconAlignment.start,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: getStarColor(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      elevation: 6,
                      shadowColor: Colors.black45,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

