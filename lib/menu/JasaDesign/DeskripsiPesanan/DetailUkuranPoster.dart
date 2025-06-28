import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:flutter/material.dart';

class DetailukuranPoster extends StatelessWidget {
  final List<String> ukuran = ['0.3 x 0.4', '0.4 x 0.6', '0.6 x 0.9'];
  final Map<String, List<String>> harga = {
    'HVS 100gsm': ['Rp 10.000', 'Rp 15.000', 'Rp 25.000'],
    'Art Paper': ['Rp 12.000', 'Rp 18.000', 'Rp 30.000'],
    'Art Carton 230gsm': ['Rp 15.000', 'Rp 25.000', 'Rp 45.000'],
  };

  DetailukuranPoster({super.key});

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
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                ),
              ),
              Image.asset(Server.UrlGambar("atributhome.png")),
              // Tombol back dan judul
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
                  'Detail Cetak Poster',
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Center(
                  child: Text(
                    'Dimensi (m)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ukuran
                      .map((u) => Expanded(
                            child: Center(
                              child: Text(
                                u,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: harga.length,
              itemBuilder: (context, index) {
                String jenisKertas = harga.keys.elementAt(index);
                List<String> hargaList = harga[jenisKertas]!;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          jenisKertas,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...hargaList.map((h) => Expanded(
                            child: Text(
                              h,
                              textAlign: TextAlign.center,
                            ),
                          )),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
