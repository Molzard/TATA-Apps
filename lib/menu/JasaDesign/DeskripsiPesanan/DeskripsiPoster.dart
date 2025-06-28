import 'dart:io';
import 'dart:typed_data';
import 'package:TATA/menu/JasaDesign/DeskripsiPesanan/PembayaranSection/PilihMetodePembayaran.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:TATA/src/pageTransition.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:TATA/menu/JasaDesign/DeskripsiPesanan/DetailUkuranPoster.dart';

class DeskripsiPoster extends StatefulWidget {
  final Map<String, dynamic> paket;

  const DeskripsiPoster({super.key, required this.paket});

  @override
  _DeskripsiPosterState createState() => _DeskripsiPosterState();
}

class _DeskripsiPosterState extends State<DeskripsiPoster> {
  bool cetak = true;
  int quantity = 1;
  File? _imageFile;
  Uint8List? _webImage;
  String? selectedUkuran;
  String? selectedBahan;
  final TextEditingController deskripsiController = TextEditingController();

  final ukuranOptions = ['0.3 x 0.4 m', '0.4 x 0.6', '0.6 x 0.9'];
  final bahanOptions = ['HVS 100gsm', 'Art Paper 150gsm', 'Art Carton 230gsm'];

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
    String desk = deskripsiController.text.trim();

    if (desk.isEmpty) {
      _showSnackbar("Deskripsi tidak boleh kosong");
      return;
    }

    if ((kIsWeb && _webImage == null) || (!kIsWeb && _imageFile == null)) {
      _showSnackbar("Silakan upload gambar terlebih dahulu");
      return;
    }

    if (cetak) {
      if (selectedUkuran == null) {
        _showSnackbar("Pilih ukuran poster");
        return;
      }

      if (selectedBahan == null) {
        _showSnackbar("Pilih bahan banner");
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
                      deskripsi: desk,
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

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.redAccent,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              Container(height: 140, color: CustomColors.primaryColor),
              Image.asset(Server.UrlGambar("atributhome.png")),
              Positioned(
                top: 60,
                left: 20,
                child: BackButton(color: Colors.white),
              ),
              Positioned(
                top: 70,
                left: 70,
                child: Text(
                  'Deskripsi Pesanan',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
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
                          Image.asset(Server.UrlGambar('designposter.png'),
                              width: 60, height: 60),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Desain Poster",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text("Poster, ${widget.paket['title']}"),
                                SizedBox(height: 5),
                                Text(widget.paket['price'],
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
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
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  SmoothPageTransition(
                                      page: DetailukuranPoster()));
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
