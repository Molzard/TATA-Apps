import 'package:TATA/helper/user_preferences.dart';
import 'package:TATA/main.dart';
import 'package:TATA/menu/StatusPesanan/DetailPesanan.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:flutter/material.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:TATA/models/PemesananModels.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PemesananPage extends StatefulWidget {
  const PemesananPage({super.key});

  @override
  _PemesananPageState createState() => _PemesananPageState();
}

class _PemesananPageState extends State<PemesananPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Pemesanan> dataPemesanan = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final token = await UserPreferences.getToken();
      if (token == null) {
        print('Token tidak ditemukan');
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      final uri = Server.urlLaravel('pesanan');
      
      print('Using token for request: $token');
      print('Request headers: ${{'Authorization': token, 'Content-Type': 'application/json', 'Accept': 'application/json'}}');
      print('Making request to: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List list = body['data'];

        setState(() {
          dataPemesanan = list.map((e) => Pemesanan.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        print('Gagal ambil data: ${response.body}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Pemesanan> filterByStatus(String status) {
    return dataPemesanan.where((item) => item.status == status).toList();
  }

  Widget getImageByKategori(String kategori) {
    kategori = kategori.toLowerCase();
    if (kategori.contains("logo")) {
      return Image.asset(
        "assets/images/designlogo.png",
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      );
    } else if (kategori.contains("banner")) {
      return Image.asset(
        "assets/images/designbanner.png",
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      );
    } else if (kategori.contains("poster")) {
      return Image.asset(
        "assets/images/designposter.png",
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      );
    } else {
      return Icon(Icons.insert_drive_file, color: Colors.grey, size: 40);
    }
  }

  Widget buildCard(Pemesanan item) {
    return GestureDetector(
      onTap: () async {
        final shouldRefresh = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailPage(
              orderId: item.id,
              productTitle: item.judul,
              productSubtitle: item.kategori,
              status: item.status,
              price: item.total,
              createdAt: item.tanggal,
              imageUrl: item.gambarReferensi,
              description: item.desk,
              remainingRevisions: item.revisi,
              tanggalselesai: item.tanggalselesai.isNotEmpty && 
                              (item.tanggalselesai.contains('-') || item.tanggalselesai.contains('T')) ? 
                              item.tanggalselesai : null,
            ),
          ),
        );

        // ✅ Cek hasil kembalian
        if (shouldRefresh == true) {
          fetchData(); // 🔁 refresh data dari server
        }
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: CustomColors.primaryColor,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child:
                  const Text('Active', style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              leading: getImageByKategori(item.kategori),
              title: Text(item.judul,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item.kategori),
              trailing: SizedBox(
                width: 85,
                child: Text(
                  item.id,
                  style: const TextStyle(color: Colors.green, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text("Dibuat : ${item.tanggal}"),
                  ),
                  const Spacer(),
                  Text(
                    "Total : Rp ${item.total.toString().replaceAllMapped(RegExp(r'(\\d)(?=(\\d{3})+(?!\\d))'), (m) => '${m[1]}.')}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabList = ['Menunggu', 'Diproses', 'Dikerjakan', 'Selesai'];

    return WillPopScope(
      onWillPop: () async {
        // Kembali ke halaman utama
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
        return false; // Jangan gunakan back system karena kita sudah handle navigasi
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Pemesanan",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: CustomColors.primaryColor,
            labelColor: CustomColors.primaryColor,
            unselectedLabelColor: CustomColors.HintColor,
            tabs: tabList.map((label) => Tab(text: label)).toList(),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: tabList.map((status) {
                  final filtered = filterByStatus(status);
                  return filtered.isEmpty
                      ? const Center(child: Text("Tidak ada data"))
                      : RefreshIndicator(
                          onRefresh: fetchData,
                          child: ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) =>
                                buildCard(filtered[index]),
                          ),
                        );
                }).toList(),
              ),
      ),
    );
  }
}
