import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:TATA/main.dart';
import 'package:TATA/menu/StatusPesanan/RatingPage.dart';
import 'package:TATA/src/pageTransition.dart';
import 'package:http/http.dart' as http;

import 'package:TATA/helper/user_preferences.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:TATA/menu/ChatPage.dart';
import 'package:TATA/menu/ChatDetailScreen.dart';
import 'package:TATA/services/ChatService.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  final String productTitle;
  final String productSubtitle;
  final String status;
  final int price;
  final String description;
  final String imageUrl;
  final String createdAt;
  final String? imageHasil;
  final String? estimateDate;
  final String? tanggalselesai;
  final int? remainingRevisions;

  const OrderDetailPage({
    super.key,
    required this.orderId,
    required this.productTitle,
    required this.productSubtitle,
    required this.status,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.createdAt,
    this.tanggalselesai,
    this.imageHasil,
    this.estimateDate,
    this.remainingRevisions,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, dynamic>? orderDetail;
  final ChatService _chatService = ChatService();
  bool _isCreatingChat = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Buat data lokal berdasarkan parameter widget
    orderDetail = {
      'image_hasil': widget.imageHasil,
      'status': widget.status,
      'total_harga': widget.price,
      'tanggal_selesai': widget.tanggalselesai,
      'estimate_date': widget.estimateDate,
    };
    
    checkIfMoreThan24Hours();
    fetchOrderDetail(); // Ambil data terbaru dari server
  }

  final bool visibility = true;
  void checkIfMoreThan24Hours() {
    if (widget.tanggalselesai != null && widget.tanggalselesai.toString().isNotEmpty) {
      try {
        // Coba parse tanggal dengan format yang benar
        DateTime? selesai;
        
        // Cek apakah format tanggal sudah sesuai format ISO
        if (widget.tanggalselesai.toString().contains('T') || 
            widget.tanggalselesai.toString().contains('-')) {
          selesai = DateTime.parse(widget.tanggalselesai.toString()).toLocal();
        } else {
          // Jika format tanggal tidak sesuai, abaikan pengecekan
          print("Format tanggal tidak valid: ${widget.tanggalselesai}");
          return;
        }

      final DateTime batasWaktu = selesai.add(Duration(hours: 24));
      final DateTime sekarang = DateTime.now();

      if (sekarang.isAfter(batasWaktu)) {
        print("sudah habis batas waktu.");
      } else {
        print("Masih dalam batas waktu.");
        }
      } catch (e) {
        // Tangani error parsing tanggal
        print("Error parsing tanggal: $e");
      }
    }
  }

  Future<void> downloadImage(BuildContext context, String imageUrl) async {
    try {
      // Minta izin akses penyimpanan
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin penyimpanan ditolak')),
        );
        return;
      }

      // Dapatkan direktori untuk menyimpan file
      Directory directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Pictures');
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // Nama file dari URL
      String fileName = imageUrl.split('/').last;

      String savePath = '${directory.path}/$fileName';

      // Unduh file
      Dio dio = Dio();
      await dio.download(imageUrl, savePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gambar berhasil disimpan',
          ),
          backgroundColor: CustomColors.primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunduh gambar: $e')),
      );
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return Colors.green;
      case 'diproses':
        return Colors.orange;
      case 'dikerjakan':
        return Colors.blue;
      case 'selesai':
        return Colors.teal;
      case 'batal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget getImageByKategori(String kategori) {
    kategori = kategori.toLowerCase();
    if (kategori.contains("logo")) {
      return Image.asset(
        "assets/images/designlogo.png",
        width: 70,
        height: 70,
        fit: BoxFit.cover,
      );
    } else if (kategori.contains("banner")) {
      return Image.asset(
        "assets/images/designbanner.png",
        width: 70,
        height: 70,
        fit: BoxFit.cover,
      );
    } else if (kategori.contains("poster")) {
      return Image.asset(
        "assets/images/designposter.png",
        width: 70,
        height: 70,
        fit: BoxFit.cover,
      );
    } else {
      return Icon(Icons.insert_drive_file, color: Colors.grey, size: 40);
    }
  }

  Future<void> batalkanPesanan(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Pembatalan'),
        content: Text('Apakah kamu yakin ingin membatalkan pesanan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:
                Text('Batal', style: TextStyle(color: CustomColors.blackColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CustomColors.redsoft,
            ),
            child: Text(
              'Ya, Batalkan',
              style: TextStyle(color: CustomColors.redColor),
            ),
          ),
        ],
      ),
    );

    // Jika user membatalkan konfirmasi, hentikan proses
    if (confirm != true) return;

    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Token tidak ditemukan, silahkan login kembali')),
        );
        return;
      }
      
      final orderidclean = widget.orderId.replaceAll("#", "");

      final response = await http.post(
        Server.urlLaravel('mobile/pesanan/cancel'),
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_pesanan': orderidclean,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pesanan berhasil dibatalkan')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membatalkan pesanan')),
        );
      }
    } catch (e) {
      print('Error saat membatalkan pesanan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  // Fungsi untuk membuka chat dengan admin
  Future<void> _openChatWithAdmin() async {
    if (_isCreatingChat) return;
    
    try {
      setState(() {
        _isCreatingChat = true;
      });
      
      final userData = await UserPreferences.getUser();
      
      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anda perlu login untuk menggunakan fitur chat')),
        );
        setState(() {
          _isCreatingChat = false;
        });
        return;
      }
      
      // ✅ PERBAIKAN: Handle berbagai struktur data user
      String? userId;
      
      // Debug: Print struktur userData
      print('User data structure: $userData');
      
      // Cek berbagai kemungkinan struktur data
      if (userData.containsKey('data') && userData['data'] != null) {
        // Struktur: {data: {user: {id: ...}}}
        final data = userData['data'];
        if (data is Map && data.containsKey('user') && data['user'] != null) {
          final user = data['user'];
          if (user is Map && user.containsKey('id')) {
            userId = user['id'].toString();
          }
        }
      } else if (userData.containsKey('user') && userData['user'] != null) {
        // Struktur: {user: {id: ...}}
        final user = userData['user'];
        if (user is Map && user.containsKey('id')) {
          userId = user['id'].toString();
        }
      } else if (userData.containsKey('id')) {
        // Struktur langsung: {id: ...}
        userId = userData['id'].toString();
      }
      
      if (userId == null || userId.isEmpty) {
        print('Error: Could not extract user ID from userData: $userData');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data user tidak valid, silakan login ulang')),
        );
        setState(() {
          _isCreatingChat = false;
        });
        return;
      }
      
      final String orderId = widget.orderId.replaceAll("#", "");
      
      print('Opening chat for order: $orderId');
      print('User ID: $userId');
      
      try {
        // Dapatkan atau buat chat untuk pesanan ini
        final chatId = await _chatService.getOrCreateChatForOrder(orderId);
        
        print('Chat ID received: $chatId');
        
        setState(() {
          _isCreatingChat = false;
        });
        
        if (chatId == null || chatId.isEmpty) {
          throw Exception('Received empty chat ID');
        }
        
        // Navigasi ke halaman chat detail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(chatId: chatId),
          ),
        );
      } catch (e) {
        print('Error getting or creating chat for order: $e');
        String errorMessage = e.toString();
        
        // Tampilkan pesan error yang lebih user-friendly
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat chat: $errorMessage'),
            duration: Duration(seconds: 3),
          ),
        );
        
        setState(() {
          _isCreatingChat = false;
        });
      }
    } catch (e) {
      print('Error in _openChatWithAdmin: $e');
      setState(() {
        _isCreatingChat = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka chat: $e')),
      );
    }
  }

  // Fungsi untuk mengambil data terbaru dari server
  Future<void> fetchOrderDetail() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final token = await UserPreferences.getToken();
      if (token == null) {
        print('Token tidak ditemukan');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final orderIdClean = widget.orderId.replaceAll("#", "");
      final uri = Server.urlLaravel('mobile/pesanan/detail/$orderIdClean');
      
      print('Fetching order detail from: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          print('Request timed out');
          return http.Response('{"status":"error","message":"Request timed out"}', 408);
        }
      );
      
      print('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          final body = json.decode(response.body);
          final data = body['data'];
          
          print('Order detail data: $data');
          
          // Format estimasi tanggal
          String? estimasiSelesai;
          if (data['estimasi_selesai'] != null) {
            try {
              final date = DateTime.parse(data['estimasi_selesai']);
              final day = date.day.toString().padLeft(2, '0');
              final month = _getMonthName(date.month);
              final year = date.year.toString();
              estimasiSelesai = "$day $month $year";
            } catch (e) {
              print('Format estimasi tanggal tidak valid: ${data['estimasi_selesai']}');
              estimasiSelesai = null;
            }
          }
          
          // Format tanggal selesai
          String? tanggalSelesai;
          if (data['updated_at'] != null) {
            try {
              final date = DateTime.parse(data['updated_at']);
              final day = date.day.toString().padLeft(2, '0');
              final month = _getMonthName(date.month);
              final year = date.year.toString();
              tanggalSelesai = "$day $month $year";
            } catch (e) {
              print('Format tanggal tidak valid: ${data['updated_at']}');
              tanggalSelesai = null;
            }
          }
          
          // Hitung sisa revisi
          int? remainingRevisions;
          if (data['maksimal_revisi'] != null) {
            try {
              int maxRevisi = int.parse(data['maksimal_revisi'].toString());
              int usedRevisi = data['revisi_used'] != null ? int.parse(data['revisi_used'].toString()) : 0;
              remainingRevisions = maxRevisi - usedRevisi;
              if (remainingRevisions < 0) remainingRevisions = 0;
            } catch (e) {
              print('Error menghitung sisa revisi: $e');
              remainingRevisions = null;
            }
          }
          
          setState(() {
            orderDetail = {
              'image_hasil': data['file_hasil_desain'] ?? widget.imageHasil,
              'status': data['status_pengerjaan'] ?? widget.status,
              'total_harga': widget.price,
              'tanggal_selesai': tanggalSelesai,
              'estimate_date': estimasiSelesai ?? data['estimasi_selesai'] ?? widget.estimateDate,
              'remaining_revisions': remainingRevisions ?? widget.remainingRevisions,
            };
            _isLoading = false;
          });
        } catch (e) {
          print('Error parsing response: $e');
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        print('Gagal ambil detail pesanan: ${response.body}');
        setState(() {
          _isLoading = false;
        });
        
        // Tampilkan pesan error jika perlu
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memperbarui data pesanan'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error fetching order detail: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Tampilkan pesan error jika perlu
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan saat memuat data'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Fungsi untuk memformat tanggal estimasi
  String _formatEstimateDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    
    try {
      // Cek apakah format sudah dalam bentuk "dd MMM yyyy"
      final parts = dateStr.split(' ');
      if (parts.length == 3) {
        // Kemungkinan sudah dalam format yang diinginkan
        return dateStr;
      }
      
      // Coba parse tanggal
      final date = DateTime.parse(dateStr);
      // Format tanggal menjadi "dd MMM yyyy"
      final day = date.day.toString().padLeft(2, '0');
      final month = _getMonthName(date.month);
      final year = date.year.toString();
      
      return "$day $month $year";
    } catch (e) {
      print("Error formatting date: $e");
      return dateStr; // Kembalikan string asli jika gagal
    }
  }
  
  // Fungsi untuk mendapatkan nama bulan
  String _getMonthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 
      'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[month];
  }

  // Fungsi untuk konfirmasi pesanan selesai
  Future<void> _confirmPesananSelesai() async {
    // Tampilkan dialog konfirmasi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Selesai'),
        content: Text('Apakah Anda yakin bahwa pesanan ini sudah selesai dan tidak memerlukan revisi lagi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Batal', style: TextStyle(color: CustomColors.blackColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text(
              'Ya, Selesai',
              style: TextStyle(color: CustomColors.whiteColor),
            ),
          ),
        ],
      ),
    );

    // Jika user membatalkan konfirmasi, hentikan proses
    if (confirm != true) return;

    try {
      setState(() {
        _isLoading = true;
      });
      
      final token = await UserPreferences.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Token tidak ditemukan, silahkan login kembali')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      print('Retrieved token from preferences: $token');
      final orderIdClean = widget.orderId.replaceAll("#", "");
      print('Order ID for confirmation: $orderIdClean');

      final response = await http.post(
        Server.urlLaravel('mobile/pesanan/confirm-complete'),
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_pesanan': orderIdClean,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Pesanan berhasil dikonfirmasi selesai')),
        );
        
        // Navigasi ke halaman rating
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RatingPage(uuid: orderIdClean),
          ),
        ).then((_) {
          // Refresh halaman setelah kembali dari rating
          fetchOrderDetail();
        });
      } else {
        String errorMessage = 'Gagal mengkonfirmasi pesanan';
        
        try {
          final data = json.decode(response.body);
          errorMessage = data['message'] ?? errorMessage;
        } catch (e) {
          print('Error parsing response: $e');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error saat konfirmasi pesanan selesai: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String imageName = widget.imageHasil ?? "";
    final String imageUrl = imageName.isNotEmpty
        ? Server.UrlImageReferensi(widget.orderId, imageName)
        : "";

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: CustomColors.whiteColor,
        body: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(color: CustomColors.primaryColor),
                ),
                Image.asset(Server.UrlGambar("atributhome.png")),
                Positioned(
                  top: 60,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                Positioned(
                  top: 60,
                  left: 70,
                  child: Text(
                    'Detail Pesanan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  top: 60,
                  right: 20,
                  child: IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    onPressed: _isLoading ? null : fetchOrderDetail,
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                color: Colors.amber[50],
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[800]!),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Memperbarui status pesanan...',
                      style: TextStyle(color: Colors.amber[800], fontSize: 14),
                    ),
                  ],
                ),
            ),
            Expanded(
              child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: CustomColors.whiteColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 70,
                                      height: 70,
                                      child: getImageByKategori(widget.productTitle),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.productTitle,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          widget.productSubtitle,
                                          style: TextStyle(
                                              color: Colors.grey[600]),
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                        Text(
                                          'Rp ${widget.price.toString()}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: getStatusColor(orderDetail?['status'] ?? widget.status).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                orderDetail?['status'] ?? widget.status,
                                    style: TextStyle(
                                                  color: getStatusColor(orderDetail?['status'] ?? widget.status),
                                      fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Deskripsi :',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.description,
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              if (widget.imageUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    Server.UrlImageReferensi(
                                        widget.orderId, widget.imageUrl),
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print("Error loading image: $error");
                                      return Container(
                                        height: 140,
                                        width: double.infinity,
                                        color: Colors.grey[300],
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image, size: 40),
                                            SizedBox(height: 8),
                                            Text('Gambar tidak tersedia', 
                                              style: TextStyle(color: Colors.grey[700]),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 140,
                                        width: double.infinity,
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                            color: CustomColors.primaryColor,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              
                              // Tampilkan hasil desain jika tersedia dan status selesai
                              if (orderDetail != null && 
                                  orderDetail!['image_hasil'] != null && 
                                  orderDetail!['image_hasil'].toString().isNotEmpty &&
                                  (orderDetail!['status'].toString().toLowerCase() == 'selesai'))
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 16),
                                    Text(
                                      'Hasil Desain:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        Server.UrlImageReferensi(
                                            widget.orderId, orderDetail!['image_hasil']),
                                        height: 140,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          print("Error loading hasil desain: $error");
                                          return Container(
                                            height: 140,
                                            width: double.infinity,
                                            color: Colors.grey[300],
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.broken_image, size: 40),
                                                SizedBox(height: 8),
                                                Text('Hasil desain tidak tersedia', 
                                                  style: TextStyle(color: Colors.grey[700]),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            height: 140,
                                            width: double.infinity,
                                            color: Colors.grey[200],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                                color: CustomColors.primaryColor,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Builder(
                          builder: (_) {
                            final status = (orderDetail?['status'] ?? widget.status).toLowerCase();
                            switch (status) {
                              case 'menunggu':
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            CustomColors.blacksoft,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text('Menunggu Konfirmasi',
                                          style: TextStyle(
                                              color:
                                                  CustomColors.whiteColor)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          batalkanPesanan(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            CustomColors.redsoft,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'Batalkan Pesanan',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: CustomColors.redColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              case 'diproses':
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[100],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Menunggu Tim Pengerjaan',
                                          style: TextStyle(
                                              color: Colors.orange[900]),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Tampilkan sisa revisi
                                    if (orderDetail?['remaining_revisions'] != null || widget.remainingRevisions != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Sisa Revisi: ${orderDetail?['remaining_revisions'] ?? widget.remainingRevisions}',
                                            style: TextStyle(
                                              color: Colors.red[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              case 'dikerjakan':
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                          child: Text(
                                            'Dalam Proses Pengerjaan',
                                            style: TextStyle(
                                                color: Colors.green[900]),
                                      ),
                                    ),
                                        if (orderDetail?['estimate_date'] != null)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.red[100],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                              'Estimasi : ${_formatEstimateDate(orderDetail?['estimate_date'])}',
                                          style: TextStyle(
                                              color: Colors.red[800]),
                                            ),
                                          ),
                                      ],
                                    ),
                                    // Tampilkan sisa revisi
                                    if (orderDetail?['remaining_revisions'] != null || widget.remainingRevisions != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Sisa Revisi: ${orderDetail?['remaining_revisions'] ?? widget.remainingRevisions}',
                                            style: TextStyle(
                                              color: Colors.red[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              case 'selesai':
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Pesanan Selesai',
                                            style: TextStyle(
                                                color: Colors.green[900]),
                                          ),
                                        ),
                                        if (orderDetail?['tanggal_selesai'] != null)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[100],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Selesai: ${_formatEstimateDate(orderDetail?['tanggal_selesai'])}',
                                              style: TextStyle(
                                                  color: Colors.blue[800]),
                                            ),
                                          ),
                                      ],
                                    ),
                                    // Tampilkan sisa revisi
                                    if (orderDetail?['remaining_revisions'] != null || widget.remainingRevisions != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Sisa Revisi: ${orderDetail?['remaining_revisions'] ?? widget.remainingRevisions}',
                                            style: TextStyle(
                                              color: Colors.red[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              default:
                                return SizedBox();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isCreatingChat ? null : _openChatWithAdmin,
                      icon: _isCreatingChat 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: CustomColors.whiteColor,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            Icons.chat,
                            color: CustomColors.whiteColor,
                          ),
                      label: Text(_isCreatingChat ? 'Memuat...' : 'Chat Dengan Admin',
                          style: TextStyle(color: CustomColors.whiteColor)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CustomColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                  ),
                  if (orderDetail?['status'] == 'selesai')
                    SizedBox(width: 10),
                  if (orderDetail?['status'] == 'selesai')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmPesananSelesai(),
                        icon: Icon(
                          Icons.check_circle,
                          color: CustomColors.whiteColor,
                        ),
                        label: Text('Selesai',
                            style: TextStyle(color: CustomColors.whiteColor)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
