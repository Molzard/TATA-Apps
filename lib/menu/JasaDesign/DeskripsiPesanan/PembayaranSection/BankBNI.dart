// File: lib/pages/pembayaran/BNIPaymentPage.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:TATA/helper/user_preferences.dart';
import 'package:TATA/menu/JasaDesign/DeskripsiPesanan/PembayaranSection/BuktiPemesanan/BuktiPemesanan.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:TATA/src/pageTransition.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:TATA/helper/auth_helper.dart';

class BNIPaymentPage extends StatefulWidget {
  final String id_jasa;
  final String harga;
  final String jenisPesanan;
  final String kelas_jasa;
  final String revisi;
  final String deskripsi;
  final String id_paket_jasa;
  final File? imageFile;
  final Uint8List? webImageBytes;
  final bool? cetak;
  final String? ukuran;
  final String? bahan;
  final int? jumlahCetak;
  final String? paymentMethodUuid;

  const BNIPaymentPage({
    super.key,
    required this.id_jasa,
    required this.harga,
    required this.jenisPesanan,
    required this.kelas_jasa,
    required this.revisi,
    required this.deskripsi,
    required this.id_paket_jasa,
    this.imageFile,
    this.webImageBytes,
    this.cetak,
    this.ukuran,
    this.bahan,
    this.jumlahCetak,
    this.paymentMethodUuid,
  });

  @override
  State<BNIPaymentPage> createState() => _BNIPaymentPageState();
}

class _BNIPaymentPageState extends State<BNIPaymentPage> {
  late String nomorPemesanan;
  late AuthHelper authHelper;

  @override
  void initState() {
    super.initState();
    nomorPemesanan = _generateKodePemesanan();
    authHelper = AuthHelper();
  }

  String _generateKodePemesanan() {
    final rand = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> kirimPesanan() async {
    final uri = Server.urlLaravel('mobile/pesanan/create-with-transaction');
    final request = http.MultipartRequest('POST', uri);
    
    final token = await UserPreferences.getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    request.headers['Authorization'] = token;
    request.headers['Accept'] = 'application/json';

    String jasaId = widget.id_jasa;
    String paketId = widget.id_paket_jasa;
    String revisiClean = widget.revisi.replaceAll('x', '');

    request.fields['id_jasa'] = jasaId;
    request.fields['id_paket_jasa'] = paketId;
    request.fields['catatan_user'] = widget.deskripsi;
    request.fields['maksimal_revisi'] = int.parse(revisiClean).toString();
    request.fields['id_metode_pembayaran'] = widget.paymentMethodUuid ?? "2c90c02c-ebb5-4b5b-8417-8bdd02ac34a0";

    if (kIsWeb && widget.webImageBytes != null) {
      final image = http.MultipartFile.fromBytes(
        'gambar_referensi',
        widget.webImageBytes!,
        filename: 'web_image.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(image);
    } else if (widget.imageFile != null) {
      final image = await http.MultipartFile.fromPath(
        'gambar_referensi',
        widget.imageFile!.path,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(image);
    }

    try {
      final response = await request.send();
      final resString = await response.stream.bytesToString();
      final resJson = jsonDecode(resString);

      print("Response status: ${response.statusCode}");
      print("Response body: $resString");

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("Pesanan berhasil: ${resJson['data']['id_pesanan']}");
        
        final String pesananId = resJson['data']['id_pesanan'];
        
        try {
          final chatResponse = await authHelper.authenticatedRequest(
            'mobile/chat/create-for-order',
            method: 'POST',
            body: jsonEncode({
              'order_id': pesananId,
              'pesanan_uuid': pesananId,
            }),
          );
          
          if (chatResponse.statusCode == 200 || chatResponse.statusCode == 201) {
            final chatData = jsonDecode(chatResponse.body);
            print("Chat room berhasil dibuat: ${chatData['message']}");
          } else {
            print("Gagal membuat chat room: ${chatResponse.statusCode} - ${chatResponse.body}");
          }
        } catch (chatError) {
          print("Error creating chat for order: $chatError");
        }

        Navigator.push(
          context,
          SmoothPageTransition(
            page: BuktiPemesananPage(
              nomorPemesanan: pesananId,
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
              uuidmetodePembayaran: widget.paymentMethodUuid ?? "2c90c02c-ebb5-4b5b-8417-8bdd02ac34a0",
              metodePembayaran: "BNI",
            ),
          ),
        );
      } else if (response.statusCode == 401) {
        print("Token tidak valid, mencoba refresh token...");
        final refreshed = await authHelper.isAuthenticated();
        
        if (refreshed) {
          print("Token berhasil di-refresh, mencoba kirim pesanan lagi...");
          await kirimPesanan();
        } else {
          print("Gagal refresh token, mengarahkan ke halaman login...");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Anda perlu login kembali')),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      } else {
        print("Gagal membuat pesanan: ${resJson['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat pesanan: ${resJson['message']}')),
        );
      }
    } catch (e) {
      print("Exception saat kirim pesanan: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  void _lanjutkan() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("KONFIRMASI"),
          content: Text("Apakah kamu sudah melakukan pembayaran?"),
          actions: [
            TextButton(
              child: Text("Belum"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text("Sudah"),
              onPressed: () async {
                Navigator.of(context).pop();
                await kirimPesanan();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
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
            padding: const EdgeInsets.all(10),
            child: Text(
              'Rekening Bank BNI',
              style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: _buildRekeningInfo(),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: _buildInstructionSection(
              "Tatacara Pembayaran dari BNI Mobile",
              [
                'Buka aplikasi BNI Mobile Banking dan login.',
                'Pilih menu "Transfer" → "Antar Rekening BNI".',
                'Masukkan Nomor Rekening Tujuan yang diberikan. \n→ Contoh: 0843894839843 (atau nomor rekening yang ditampilkan di aplikasi).',
                'Masukkan jumlah pembayaran sesuai tagihan.',
                'Periksa kembali detail penerima (nama rekening) dan nominal, pastikan sudah benar.',
                'Konfirmasi transaksi dan masukkan MPIN untuk menyelesaikan pembayaran.',
                'Simpan bukti transfer sebagai referensi.',
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: _buildInstructionSection(
              "Tatacara Pembayaran dari Bank Lain",
              [
                'Masuk ke Mobile Banking / Internet Banking / ATM bank lain yang kamu gunakan.',
                'Pilih menu "Transfer ke Bank Lain" (tewat jaringan ATM Bersama, PRIMA, atau ALTO).',
                'Masukkan Kode Bank BNI: 009.',
                'Masukkan Nomor Rekening Tujuan yang diberikan. \n→ Contoh: 0843894839843 (atau nomor rekening yang ditampilkan di aplikasi).',
                'Masukkan jumlah pembayaran sesuai tagihan.',
                'Periksa kembali data penerima (nama) dan jumlah pembayaran, pastikan sudah benar.',
                'Selesaikan transaksi sesuai instruksi.',
                'Simpan bukti transfer untuk konfirmasi pembayaran (jika diperlukan).',
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: _buildDeskripsiPembayaran(),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(15),
            child: _buildLanjutButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildRekeningInfo() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/BankBNI.png',
              width: 36),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nomor Rekening',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              SizedBox(height: 4),
              Text('0843894839843',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInstructionSection(String title, List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(thickness: 1),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        SizedBox(height: 8),
        ...List.generate(steps.length, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text("${index + 1}. ${steps[index]}",
                style: TextStyle(fontSize: 13)),
          );
        }),
      ],
    );
  }

  Widget _buildDeskripsiPembayaran() {
    return Column(
      children: [
        Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text("Deskripsi Pembayaran",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Table(
            columnWidths: {
              2: IntrinsicColumnWidth(),
              3: FlexColumnWidth(),
            },
            children: [
              TableRow(children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text("Jasa",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(": Design ${widget.jenisPesanan}"),
                ),
              ]),
              TableRow(children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text("Paket",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(": ${widget.kelas_jasa}"),
                ),
              ]),
              TableRow(children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text("Total Harga",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(": Rp. ${widget.harga}"),
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanjutButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _lanjutkan,
      icon: Icon(Icons.arrow_forward),
      label: Text("Lanjut"),
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomColors.primaryColor,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
