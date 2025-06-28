import 'dart:io';
import 'dart:typed_data';
import 'package:TATA/menu/JasaDesign/DeskripsiPesanan/PembayaranSection/PilihMetodePembayaran.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:TATA/src/pageTransition.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DeskripsiLogo extends StatefulWidget {
  final Map<String, dynamic> paket;

  const DeskripsiLogo({super.key, required this.paket});

  @override
  _DeskripsiLogoState createState() => _DeskripsiLogoState();
}

class _DeskripsiLogoState extends State<DeskripsiLogo> {
  File? _imageFile;
  Uint8List? _webImage;
  final TextEditingController _descController = TextEditingController();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        // Untuk web platform
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImage = bytes;
        });
      } else {
        // Untuk mobile platforms
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    }
  }

  void _lanjutkan() {
    if ((kIsWeb && _webImage == null) || (!kIsWeb && _imageFile == null) || _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Harap lengkapi deskripsi dan unggah foto terlebih dahulu."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Konfirmasi"),
          content:
              Text("Apakah kamu yakin ingin melanjutkan ke metode pembayaran?"),
          actions: [
            TextButton(
              child: Text("Batal"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text("Lanjut"),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog

                final harga = widget.paket['price'] as String;
                final cleanedHarga =
                    harga.replaceAll('Rp', '').replaceAll(',', '').trim();

                Navigator.push(
                  context,
                  SmoothPageTransition(
                    page: MetodePembayaranPage(
                      id_paket_jasa: widget.paket['id_paket_jasa'],
                      id_jasa: widget.paket['id_jasa'],
                      durasi: widget.paket['duration'],
                      harga: cleanedHarga,
                      jenisPesanan: widget.paket['jenis_pesanan'],
                      kelas_jasa: widget.paket['title'],
                      revisi: widget.paket['revision'],
                      deskripsi: _descController.text,
                      imageFile: kIsWeb ? null : _imageFile!,
                      webImageBytes: _webImage,
                    ),
                  ),
                );
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
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: CustomColors.primaryColor,
                ),
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
                  'Deskripsi Pesanan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          Server.UrlGambar('designlogo.png'),
                          width: 60,
                          height: 60,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Desain Logo",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text("Logo, ${widget.paket['title']}"),
                              SizedBox(height: 5),
                              Text("${widget.paket['price']}",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child:
                              Text("Ubah", style: TextStyle(color: Colors.red)),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text("Deskripsi:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _descController,
                      maxLines: 5,
                      decoration: InputDecoration.collapsed(
                          hintText: "Tulis Deskripsi"),
                    ),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.camera_alt),
                    label: Text("Upload Foto"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CustomColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  if (_imageFile != null || _webImage != null) ...[
                    SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: kIsWeb && _webImage != null
                        ? Image.memory(
                            _webImage!,
                            height: 180,
                            fit: BoxFit.cover,
                          )
                        : _imageFile != null 
                          ? Image.file(
                              _imageFile!,
                              height: 180,
                              fit: BoxFit.cover,
                            )
                          : Container(),
                    )
                  ],
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _lanjutkan,
          icon: Icon(Icons.arrow_forward),
          label: Text("Lanjut"),
          style: ElevatedButton.styleFrom(
            backgroundColor: CustomColors.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }
}
