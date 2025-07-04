import 'package:TATA/helper/user_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:TATA/src/pageTransition.dart';
import 'package:TATA/menu/JasaDesign/DeskripsiPesanan/DeskripsiBanner.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/sendApi/ChatService.dart';
import 'package:TATA/menu/ChatDetailScreen.dart';

class JasaDesignBanner extends StatefulWidget {
  const JasaDesignBanner({super.key});

  @override
  _BannerPackagePageState createState() => _BannerPackagePageState();
}

class _BannerPackagePageState extends State<JasaDesignBanner>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> packages = [];
  bool isLoading = false; // Set ke false karena kita langsung load dummy data

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchPackagesInstant(); // Load instant
  }

  int _convertToDays(String duration) {
    // Jika format durasi misalnya "3 hari", kita ambil angkanya
    final match = RegExp(r'(\d+)').firstMatch(duration);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 0;
  }

  // Method baru untuk instant loading
  Future<void> fetchPackagesInstant() async {
    try {
      print('Loading banner packages instantly...');
      
      // Get data (will return dummy immediately)
      final data = await Server.getJasaData('2');
      
      final jasa = data['jasa'];
      List<dynamic> paketJasaList = data['paket_jasa'];

      setState(() {
        packages = paketJasaList.map<Map<String, dynamic>>((item) {
          final kelas = item["kelas_jasa"] ?? "-";
          final waktu = item["waktu_pengerjaan"] ?? "0";
          return {
            "id_paket_jasa": item["id_paket_jasa"].toString(),
            "id_jasa": item["id_jasa"].toString(),
            "jenis_pesanan": jasa["kategori"] ?? "-",
            "title": kelas,
            "price": "Rp ${item["harga_paket_jasa"] ?? "0"}",
            "duration": "${_convertToDays(waktu)} hari",
            "revision": "${item["maksimal_revisi"]}x",
            "konsep": "2 Konsep",
            "logo_transparan": true,
            "konsep_simple": kelas == "basic",
            "konsep_premium": kelas == "standard" || kelas == "premium",
            "konsep_3d": kelas == "premium",
          };
        }).toList();

        isLoading = false;
      });
      
      print('Banner packages loaded successfully');
    } catch (e) {
      print("Error loading packages: $e");
      // Fallback ke dummy data jika ada error
      _useDummyData();
    }
  }

  void _useDummyData() {
    setState(() {
      packages = [
        {
          "id_paket_jasa": "4",
          "id_jasa": "2",
          "jenis_pesanan": "Banner",
          "title": "basic",
          "price": "Rp 150000",
          "duration": "3 hari",
          "revision": "2x",
          "konsep": "2 Konsep",
          "logo_transparan": true,
          "konsep_simple": true,
          "konsep_premium": false,
          "konsep_3d": false,
        },
        {
          "id_paket_jasa": "5",
          "id_jasa": "2",
          "jenis_pesanan": "Banner",
          "title": "standard",
          "price": "Rp 300000",
          "duration": "5 hari",
          "revision": "5x",
          "konsep": "2 Konsep", 
          "logo_transparan": true,
          "konsep_simple": false,
          "konsep_premium": true,
          "konsep_3d": false,
        },
        {
          "id_paket_jasa": "6",
          "id_jasa": "2",
          "jenis_pesanan": "Banner",
          "title": "premium",
          "price": "Rp 450000",
          "duration": "7 hari",
          "revision": "10x",
          "konsep": "2 Konsep",
          "logo_transparan": true,
          "konsep_simple": false,
          "konsep_premium": true,
          "konsep_3d": true,
        }
      ];
      isLoading = false;
    });
  }

  void _pesanSekarang() {
    final selectedPackage = packages[_tabController.index];

    Navigator.push(
      context,
      SmoothPageTransition(
        page: DeskripsiBanner(paket: selectedPackage),
      ),
    );
    print(selectedPackage);
  }

  Future<void> _openChatWithContext() async {
    try {
      final selectedPackage = packages[_tabController.index];
      setState(() {
        isLoading = true;
      });
      
      print('=== [CHAT-DEBUG] Creating direct chat with context ===');
      print('Selected Package: $selectedPackage');
      
      // **TAMBAHAN: Debug context data yang akan dikirim**
      print('=== [CONTEXT-DEBUG] JasaDesignPoster ===');
      print('Package ID: ${selectedPackage['id_paket_jasa']}');
      print('Jasa ID: ${selectedPackage['id_jasa']}');
      print('Jenis Pesanan: ${selectedPackage['jenis_pesanan']}');
      print('Title: ${selectedPackage['title']}');
      print('Price: ${selectedPackage['price']}');
      print('Full context data: ${jsonEncode(selectedPackage)}');
      
      // Debug URL
      final token = await UserPreferences.getToken();
      final url = Server.urlLaravel('mobile/chat/create-direct').toString();
      print('API URL: $url');
      print('Token available: ${token != null}');
      print('Token: ${token?.substring(0, 20)}...');
      
      final result = await ChatService.createDirectChatWithContext(selectedPackage);
      
      print('=== [CHAT-DEBUG] API Response ===');
      print('Full result: $result');
      print('Status: ${result['status']}');
      print('Message: ${result['message']}');
      print('Data: ${result['data']}');
      print('Is existing chat: ${result['data']?['is_existing']}');
      
      setState(() {
        isLoading = false;
      });
      
      if (result['status'] == 'success') {
        final chatId = result['data']['chat_id'];
        final isExisting = result['data']['is_existing'] ?? false;
        
        print('=== [CHAT-DEBUG] Navigation Info ===');
        print('Chat ID: $chatId');
        print('Is existing chat: $isExisting');
        
        if (isExisting) {
          print('Using existing chat room');
        } else {
          print('Created new chat room');
        }
        
        // Navigate to chat detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(chatId: chatId),
          ),
        );
      } else {
        print('Failed to create chat: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat chat: ${result['message']}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Coba Lagi',
              onPressed: () => _openChatWithContext(),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error in _openChatWithContext: $e');
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCheck(bool isIncluded) {
    return isIncluded
        ? Icon(Icons.check, color: Colors.black, size: 25)
        : Icon(Icons.close, color: Colors.grey, size: 25);
  }

  @override
  Widget build(BuildContext context) {
    // Hapus loading check karena kita langsung load data
    if (packages.isEmpty) {
      // Show minimal loading hanya jika benar-benar kosong
      return Scaffold(
        backgroundColor: CustomColors.whiteColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading packages...'),
            ],
          ),
        ),
      );
    }

    final selected = packages[_tabController.index];

    return Scaffold(
      backgroundColor: CustomColors.whiteColor,
      body: Column(
        children: [
          Container(
            color: CustomColors.primaryColor,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  child: Image.asset(Server.UrlGambar("atributhome.png")),
                ),
                Container(
                  padding: EdgeInsets.only(top: 30),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          BackButton(color: CustomColors.whiteColor),
                          Spacer(),
                          // Debug button
                          IconButton(
                            icon: Icon(Icons.bug_report, color: Colors.white),
                            onPressed: () async {
                              try {
                                final result = await ChatService.testChatApi();
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('API Test Results'),
                                    content: SingleChildScrollView(
                                      child: Text(
                                        'Status: ${result['status']}\n\n'
                                        'Direct Chat Test:\n'
                                        'Status Code: ${result['direct_chat_test']['status_code']}\n'
                                        'Body: ${result['direct_chat_test']['body']}\n\n'
                                        'Routes Test:\n'
                                        'Status Code: ${result['routes_test']['status_code']}\n'
                                        'Body: ${result['routes_test']['body']}'
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        child: Text('Close'),
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                    ],
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Center(
                          child: Image.asset(
                            Server.UrlGambar('designbanner.png'),
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Image.asset(
                    Server.UrlGambar("atributhomebigcircle.png"),
                    scale: 1,
                  ),
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: 100),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 5),
                          child: Text(
                            "Desain Banner",
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      TabBar(
                        controller: _tabController,
                        labelColor: CustomColors.primaryColor,
                        unselectedLabelColor: CustomColors.HintColor,
                        indicatorColor: CustomColors.greensoft,
                        tabs: [
                          Tab(text: 'Basic'),
                          Tab(text: 'Standard'),
                          Tab(text: 'Premium'),
                        ],
                        onTap: (_) {
                          setState(() {});
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected['price'],
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "${selected['konsep']} konsep & PNG Transparan",
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            ...[
                              ["Waktu Pengerjaan", selected["duration"]],
                              ["Revisi", selected["revision"]],
                              ["Konsep", selected["konsep"]],
                            ].map((e) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(e[0]),
                                      Text(e[1]),
                                    ],
                                  ),
                                )),
                            ...[
                              [
                                "Banner Transparan",
                                selected["logo_transparan"]
                              ],
                              ["Konsep Simple", selected["konsep_simple"]],
                              ["Konsep Premium", selected["konsep_premium"]],
                              ["3D Konsep", selected["konsep_3d"]],
                            ].map((e) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 1),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(e[0]),
                                      _buildCheck(e[1]),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Card(
                            color: CustomColors.whiteColor,
                            elevation: 5,
                            child: IconButton(
                                onPressed: _openChatWithContext,
                                icon: Image.asset(
                                    Server.UrlGambar("chaticon.png")))),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _pesanSekarang,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CustomColors.primaryColor,
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text("Pesan Sekarang",
                              style: TextStyle(color: CustomColors.whiteColor)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
