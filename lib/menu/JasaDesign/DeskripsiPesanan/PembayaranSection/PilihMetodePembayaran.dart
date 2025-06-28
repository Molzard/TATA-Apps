import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:TATA/helper/user_preferences.dart';
import 'package:TATA/menu/JasaDesign/DeskripsiPesanan/PembayaranSection/BankBNI.dart';
import 'package:TATA/menu/JasaDesign/DeskripsiPesanan/PembayaranSection/BankMandiri.dart';
import 'package:TATA/menu/JasaDesign/DeskripsiPesanan/PembayaranSection/WalletOVO.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MetodePembayaranPage extends StatefulWidget {
  final String id_jasa;
  final String id_paket_jasa;
  final String harga;
  final String durasi;
  final String jenisPesanan;
  final String kelas_jasa;
  final String revisi;
  final String deskripsi;
  final File? imageFile;
  final Uint8List? webImageBytes;
  final bool? cetak;
  final String? ukuran;
  final String? bahan;
  final int? jumlahCetak;

  const MetodePembayaranPage({
    super.key,
    required this.id_jasa,
    required this.id_paket_jasa,
    required this.harga,
    required this.durasi,
    required this.jenisPesanan,
    required this.kelas_jasa,
    required this.revisi,
    required this.deskripsi,
    this.imageFile,
    this.webImageBytes,
    this.cetak,
    this.ukuran,
    this.bahan,
    this.jumlahCetak,
  });

  @override
  _MetodePembayaranPageState createState() => _MetodePembayaranPageState();
}

class _MetodePembayaranPageState extends State<MetodePembayaranPage> {
  int? selectedMethod;
  List<Map<String, dynamic>> metodePembayaran = [];
  bool isLoading = true;

  final List<Map<String, dynamic>> defaultMetodePembayaran = [
    {"nama": "Rekening Mandiri", "gambar": "assets/images/BankMandiri.png", "uuid": "0ce1048e-25d2-4fbd-a366-07b660231e2c", "nama_metode_pembayaran": "Mandiri"},
    {"nama": "Rekening BNI", "gambar": "assets/images/BankBNI.png", "uuid": "2c90c02c-ebb5-4b5b-8417-8bdd02ac34a0", "nama_metode_pembayaran": "BRI"},
    {"nama": "OVO", "gambar": "assets/images/OVO.png", "uuid": "6ada3c0a-8d4c-46f5-a651-48ef8d5cccf6", "nama_metode_pembayaran": "OVO"},
  ];

  @override
  void initState() {
    super.initState();
    _loadMetodePembayaran();
  }

  Future<void> _loadMetodePembayaran() async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        print('No token available, using default payment methods');
        setState(() {
          metodePembayaran = defaultMetodePembayaran;
          isLoading = false;
        });
        return;
      }

      print('Fetching payment methods from API...');
      final response = await http.get(
        Server.urlLaravel('mobile/metode-pembayaran'),
        headers: {
          'Accept': 'application/json',
          'Authorization': token,
        },
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final apiData = List<Map<String, dynamic>>.from(data['data']);
          print('Payment methods received: ${apiData.length}');
          
          final uiData = apiData.map((item) {
            // Check if gambar is already provided by the API
            String imagePath = item['gambar'] ?? "assets/images/BankMandiri.png";
            String displayName = item['nama_metode_pembayaran'] ?? 'Unknown';
            
            print('Processing payment method: $displayName (${item['uuid']})');
            
            return {
              "nama": "Rekening $displayName",
              "gambar": imagePath,
              "uuid": item['uuid'],
              "nama_metode_pembayaran": displayName
            };
          }).toList();
          
          setState(() {
            metodePembayaran = uiData;
            isLoading = false;
          });
          print('Payment methods loaded successfully: ${uiData.length}');
          return;
        } else {
          print('API returned error: ${data['message']}');
        }
      } else {
        print('API request failed with status: ${response.statusCode}');
      }
      
      print('Falling back to default payment methods');
      setState(() {
        metodePembayaran = defaultMetodePembayaran;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading payment methods: $e');
      setState(() {
        metodePembayaran = defaultMetodePembayaran;
        isLoading = false;
      });
    }
  }

  void _prosesPembayaran() {
    if (selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Silakan pilih metode pembayaran terlebih dahulu."),
        ),
      );
      return;
    }

    final selectedPaymentMethod = metodePembayaran[selectedMethod!];
    final paymentUuid = selectedPaymentMethod['uuid'];
    final paymentName = selectedPaymentMethod['nama_metode_pembayaran'];
    final displayName = selectedPaymentMethod['nama'];

    Widget targetPage;
    if (paymentName.toLowerCase().contains('mandiri')) {
      targetPage = MandiriPaymentPage(
        id_jasa: widget.id_jasa,
        id_paket_jasa: widget.id_paket_jasa,
        jenisPesanan: widget.jenisPesanan,
        kelas_jasa: widget.kelas_jasa,
        harga: widget.harga,
        revisi: widget.revisi,
        deskripsi: widget.deskripsi,
        imageFile: widget.imageFile,
        webImageBytes: widget.webImageBytes,
        cetak: widget.cetak,
        ukuran: widget.ukuran,
        bahan: widget.bahan,
        jumlahCetak: widget.jumlahCetak,
        paymentMethodUuid: paymentUuid,
      );
    } else if (paymentName.toLowerCase().contains('ovo')) {
      targetPage = OVOPaymentPage(
        id_jasa: widget.id_jasa,
        id_paket_jasa: widget.id_paket_jasa,
        jenisPesanan: widget.jenisPesanan,
        kelas_jasa: widget.kelas_jasa,
        harga: widget.harga,
        revisi: widget.revisi,
        deskripsi: widget.deskripsi,
        imageFile: widget.imageFile,
        webImageBytes: widget.webImageBytes,
        cetak: widget.cetak,
        ukuran: widget.ukuran,
        bahan: widget.bahan,
        jumlahCetak: widget.jumlahCetak,
        paymentMethodUuid: paymentUuid,
      );
    } else {
      targetPage = BNIPaymentPage(
        id_jasa: widget.id_jasa,
        id_paket_jasa: widget.id_paket_jasa,
        jenisPesanan: widget.jenisPesanan,
        kelas_jasa: widget.kelas_jasa,
        harga: widget.harga,
        revisi: widget.revisi,
        deskripsi: widget.deskripsi,
        imageFile: widget.imageFile,
        webImageBytes: widget.webImageBytes,
        cetak: widget.cetak,
        ukuran: widget.ukuran,
        bahan: widget.bahan,
        jumlahCetak: widget.jumlahCetak,
        paymentMethodUuid: paymentUuid,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.whiteColor,
      body: isLoading 
      ? Center(child: CircularProgressIndicator(color: CustomColors.primaryColor))
      : ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              Container(height: 140, color: CustomColors.primaryColor),
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
                  'Pembayaran',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text(
              "Metode Pembayaran untuk ${widget.jenisPesanan.toUpperCase()}",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CustomColors.blackColor,
              ),
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Transfer Bank",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: CustomColors.blackColor,
              ),
            ),
          ),
          SizedBox(height: 8),
          ...List.generate(metodePembayaran.length, (index) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Image.asset(
                        metodePembayaran[index]['gambar']!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  title: Text(
                    metodePembayaran[index]['nama']!,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text('UUID: ${metodePembayaran[index]['uuid']}', style: TextStyle(fontSize: 10)),
                  trailing: selectedMethod == index
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () {
                    setState(() {
                      selectedMethod = index;
                    });
                  },
                ),
              ),
            );
          }),
          SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : _prosesPembayaran,
          icon: Icon(Icons.arrow_forward),
          label: Text("Lanjut"),
          style: ElevatedButton.styleFrom(
            backgroundColor: CustomColors.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50),
          ),
        ),
      ),
    );
  }
}
