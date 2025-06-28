import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:TATA/menu/JasaDesign/DeskripsiPesanan/PembayaranSection/PilihMetodePembayaran.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:TATA/src/pageTransition.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:TATA/menu/JasaDesign/DeskripsiPesanan/DetailUkuranBanner.dart';

class DeskripsiBanner extends StatefulWidget {
  final Map<String, dynamic> paket;

  const DeskripsiBanner({super.key, required this.paket});

  @override
  _DeskripsiBannerState createState() => _DeskripsiBannerState();
}

class _DeskripsiBannerState extends State<DeskripsiBanner> {
  bool cetak = true;
  int quantity = 1;
  File? _imageFile;
  Uint8List? _webImage;
  String? selectedUkuran;
  String? selectedBahan;
  final deskripsiController = TextEditingController();

  final ukuranOptions = ['0.6 x 1.2 m', '1 x 2', '1.5 x 3'];
  final bahanOptions = ['HVS 100gsm', 'Art Paper 150gsm', 'Art Carton 230gsm'];

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

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

  Future<String> _convertImageToBase64(File image) async {
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  void _lanjutkan() {
    if ((kIsWeb && _webImage == null) || (!kIsWeb && _imageFile == null) || deskripsiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Harap lengkapi deskripsi dan unggah foto terlebih dahulu."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (cetak) {
      if (selectedUkuran == null) {
        _showError("Silakan pilih ukuran banner.");
        return;
      }
      if (selectedBahan == null) {
        _showError("Silakan pilih bahan banner.");
        return;
      }
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

                final cleanedHarga = widget.paket['price']
                    .replaceAll('Rp', '')
                    .replaceAll(',', '')
                    .trim();

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
                      deskripsi: deskripsiController.text,
                      imageFile: kIsWeb ? null : _imageFile,
                      webImageBytes: _webImage,
                      cetak: cetak,
                      ukuran: selectedUkuran,
                      bahan: selectedBahan,
                      jumlahCetak: quantity,
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
              child: Padding(
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
                            Server.UrlGambar('designbanner.png'),
                            width: 60,
                            height: 60,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Desain Banner",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text("Banner, ${widget.paket['title']}"),
                                SizedBox(height: 5),
                                Text("${widget.paket['price']}",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text("Ubah",
                                style: TextStyle(color: Colors.red)),
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
                        controller: deskripsiController,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text("Cetak",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(width: 10),
                            Checkbox(
                              value: cetak,
                              onChanged: (val) {
                                setState(() {
                                  cetak = val!;
                                  if (!cetak) {
                                    selectedUkuran = null;
                                    selectedBahan = null;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        Card(
                          margin: EdgeInsets.only(right: 20),
                          color: CustomColors.whiteColor,
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                SmoothPageTransition(
                                    page: DetailukuranBanner()),
                              );
                            },
                            icon: Icon(Icons.content_paste_search_rounded,
                                size: 30),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text("Ukuran:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 10,
                      children: ukuranOptions.map((ukuran) {
                        return ChoiceChip(
                          label: Text(ukuran),
                          selected: selectedUkuran == ukuran,
                          onSelected: cetak
                              ? (val) => setState(
                                  () => selectedUkuran = val ? ukuran : null)
                              : null,
                          selectedColor: CustomColors.primaryColor,
                          labelStyle: TextStyle(
                            color: selectedUkuran == ukuran
                                ? Colors.white
                                : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    Text("Bahan Banner:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 10,
                      children: bahanOptions.map((bahan) {
                        return ChoiceChip(
                          label: Text(bahan),
                          selected: selectedBahan == bahan,
                          onSelected: cetak
                              ? (val) => setState(
                                  () => selectedBahan = val ? bahan : null)
                              : null,
                          selectedColor: CustomColors.primaryColor,
                          labelStyle: TextStyle(
                            color: selectedBahan == bahan
                                ? Colors.white
                                : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: quantity > 1
                              ? () => setState(() => quantity--)
                              : null,
                          icon: Icon(Icons.remove),
                        ),
                        Text(quantity.toString(),
                            style: TextStyle(fontSize: 16)),
                        IconButton(
                          onPressed: () => setState(() => quantity++),
                          icon: Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
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
