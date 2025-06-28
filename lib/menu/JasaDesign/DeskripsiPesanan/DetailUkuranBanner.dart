import 'package:flutter/material.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/src/CustomColors.dart';

class DetailukuranBanner extends StatelessWidget {
  final List<String> ukuran = ['0.6 x 1.2 ', '1 x 2 ', '1.5 x 3 '];

  final Map<String, List<String>> harga = {
    'Flexi China': ['Rp 30.000', 'Rp 55.000', 'Rp 85.000'],
    'Flexi Korea': ['Rp 35.000', 'Rp 65.000', 'Rp 100.000'],
    'Flexi Jerman': ['Rp 45.000', 'Rp 80.000', 'Rp 120.000'],
  };

  DetailukuranBanner({super.key});

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
                  'Detail Cetak Banner',
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
                String jenisBahan = harga.keys.elementAt(index);
                List<String> hargaList = harga[jenisBahan]!;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          jenisBahan,
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
