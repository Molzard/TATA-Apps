import 'dart:io';
import 'dart:typed_data';
import 'package:TATA/helper/user_preferences.dart';
import 'package:TATA/main.dart';
import 'package:TATA/menu/OrderChatPage.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:TATA/src/CustomColors.dart';

class BuktiPemesananPage extends StatefulWidget {
  final String id_jasa;
  final String uuidmetodePembayaran;
  final String metodePembayaran;
  final String harga;
  final String nomorPemesanan;
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

  const BuktiPemesananPage({
    super.key,
    required this.uuidmetodePembayaran,
    required this.metodePembayaran,
    required this.id_jasa,
    required this.harga,
    required this.nomorPemesanan,
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
  });

  @override
  State<BuktiPemesananPage> createState() => _BuktiPemesananPageState();
}

class _BuktiPemesananPageState extends State<BuktiPemesananPage> {
  late DateTime tanggalPemesanan;
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    tanggalPemesanan = DateTime.now();
  }

  // Future<void> _screenshotAndSave() async {
  //   final permission = await Permission.storage.request();
  //   if (!permission.isGranted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Izin penyimpanan diperlukan")),
  //     );
  //     return;
  //   }

  //   final Uint8List? imageBytes = await screenshotController.capture();
  //   if (imageBytes != null) {
  //     final result = await ImageGallerySaver.saveImage(
  //       imageBytes,
  //       quality: 100,
  //       name: "bukti_pemesanan_$widget.nomorPemesanan",
  //     );
  //     final success = result['isSuccess'] ?? false;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           success
  //               ? "Bukti berhasil disimpan ke galeri"
  //               : "Gagal menyimpan bukti",
  //         ),
  //       ),
  //     );
  //   }
  // }

  void _navigateToChat() {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => OrderChatPage(
          pesananUuid: widget.nomorPemesanan,
          jasaId: widget.id_jasa,
          jasaTitle: widget.jenisPesanan,
          packageType: widget.kelas_jasa,
          price: widget.harga,
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate =
        DateFormat('dd - MM - yyyy').format(tanggalPemesanan);

    return Scaffold(
      body: Screenshot(
        controller: screenshotController,
        child: Padding(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(height: 140, color: CustomColors.primaryColor),
                  Image.asset(Server.UrlGambar("atributhome.png")),
                  Positioned(
                    top: 60,
                    left: 20,
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
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 5),
                child: Text("Bukti Pemesanan",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RowInfo(
                          label: "Nomor Pemesanan",
                          value: widget.nomorPemesanan),
                      Divider(color: Colors.grey.shade300),
                      RowInfo(label: "Jasa", value: widget.jenisPesanan),
                      RowInfo(label: "Kelas", value: widget.kelas_jasa),
                      RowInfo(label: "Total Harga", value: widget.harga),
                      RowInfo(
                          label: "Metode Pembayaran",
                          value: widget.metodePembayaran),
                      if (widget.cetak == true) ...[
                        RowInfo(label: "Ukuran", value: widget.ukuran ?? "-"),
                        RowInfo(label: "Bahan", value: widget.bahan ?? "-"),
                        RowInfo(
                            label: "Jumlah Cetak",
                            value: "${widget.jumlahCetak ?? '-'} lembar"),
                      ],
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text("Tanggal Pemesanan : $formattedDate",
                              style: TextStyle(
                                  fontSize: 12, fontStyle: FontStyle.italic)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 5),
                child: Text("Tatacara Verifikasi Pembayaran",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(_tatacara.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Text("${index + 1}. ${_tatacara[index]}"),
                      );
                    }),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => MainPage(initialIndex: 0)),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black,
                        ),
                        child: Text("Kembali ke Beranda"),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _navigateToChat,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: CustomColors.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text("Chat Admin"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final List<String> _tatacara = [
    "Setelah melakukan pembayaran, tekan tombol Verifikasi di halaman pembayaran.",
    "Anda telah diarahkan ke halaman Bukti Pemesanan ini.",
    "Silahkan tekan tombol 'Chat Admin' di bawah untuk menghubungi admin dan konfirmasi pembayaran Anda.",
    "Kirimkan pesan di chat, contoh: \"Admin, saya sudah melakukan pembayaran dan transfer ke nomor rekening terkait.\" dan lampirkan bukti transfer berupa tangkapan layar.",
    "Tunggu admin melakukan pengecekan pembayaran Anda.",
    "Admin akan mengubah status pemesanan menjadi 'Diproses' jika pembayaran telah diverifikasi.",
    "Anda dapat memeriksa status pemesanan Anda di menu 'Pemesanan'.",
    "Jika ingin menyimpan bukti pemesanan secara pribadi, silahkan screenshot halaman ini.",
  ];
}

class RowInfo extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const RowInfo({
    super.key,
    required this.label,
    required this.value,
    this.isBold = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text("$label :")),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}
