import 'dart:convert';

import 'package:TATA/helper/user_preferences.dart';
import 'package:TATA/helper/auth_helper.dart';
import 'package:TATA/models/ReviewModels.dart';
import 'package:TATA/menu/DetailReview/DetailReview.dart' as dr;
import 'package:TATA/menu/JasaDesign/JasaDesignLogo.dart';
import 'package:TATA/menu/JasaDesign/JasaDesignBanner.dart';
import 'package:TATA/menu/JasaDesign/JasaDesignPoster.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:TATA/src/CustomText.dart';
import 'package:TATA/src/pageTransition.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String namaUser = "...";
  String imageProfil = "";
  final AuthHelper _authHelper = AuthHelper();

  void loadUserData() async {
    try {
    final userData = await UserPreferences.getUser();
    if (userData != null) {
        print("ALLDATAA : $userData");
        
        // Perbaiki akses data dengan null safety yang lebih baik
        String? userName;
        String? userPhoto;
        
        // Cek struktur data yang berbeda
        if (userData.containsKey('data') && 
            userData['data'] != null && 
            userData['data'].containsKey('user') && 
            userData['data']['user'] != null) {
          // Struktur: data.user.name
          userName = userData['data']['user']['name']?.toString();
          userPhoto = userData['data']['user']['foto']?.toString();
          print("User dari SharedPreferences (data.user): $userName");
          print("foto dari SharedPreferences (data.user): $userPhoto");
        } else if (userData.containsKey('user') && userData['user'] != null) {
          // Struktur: user.name
          userName = userData['user']['name']?.toString();
          userPhoto = userData['user']['foto']?.toString();
          print("User dari SharedPreferences (user): $userName");
          print("foto dari SharedPreferences (user): $userPhoto");
        } else {
          // Fallback - cari di level root
          userName = userData['name']?.toString() ?? userData['nama_user']?.toString();
          userPhoto = userData['foto']?.toString();
          print("User dari SharedPreferences (root): $userName");
          print("foto dari SharedPreferences (root): $userPhoto");
        }
        
        setState(() {
          namaUser = userName ?? "Pengguna";
          imageProfil = userPhoto ?? '';
        });
      } else {
        print("User data is null");
        setState(() {
          namaUser = "Pengguna";
          imageProfil = '';
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
      setState(() {
        namaUser = "Pengguna";
        imageProfil = '';
      });
    }
  }

  @override
  void initState() {
    super.initState();
      loadUserData();
      fetchReviews();
  }

  Future<List<Review>> fetchReviews() async {
    try {
      final url = Server.urlLaravel('mobile/public/reviews');
      print('FETCHING PUBLIC REVIEWS FROM: $url');
      
      final response = await Server.httpClient.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('TIMEOUT: Review request timed out');
          return http.Response('{"message":"timeout"}', 408);
        },
      );
      
      print('RESPONSE STATUS: ${response.statusCode}');
      print('RESPONSE BODY: ${response.body}');
      
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        
        // Cek source data
        final source = decodedData['source'] ?? 'unknown';
        print('DATA SOURCE: $source');
        
        List<dynamic> reviewsData = [];
        if (decodedData is Map<String, dynamic>) {
          if (decodedData.containsKey('data')) {
            reviewsData = decodedData['data'] as List<dynamic>;
            print('Found ${reviewsData.length} reviews from $source');
          }
        }
        
        if (reviewsData.isEmpty) {
          print('No real reviews available yet');
          return []; // Return empty list instead of fallback
        }
        
        final reviews = reviewsData.map((json) {
          try {
            print('Processing review JSON: $json');
            final review = Review.fromJson(json);
            print('Created review: ${review.name} with avatar: ${review.avatarUrl}');
            return review;
          } catch (e) {
            print('Error parsing review: $e for data: $json');
            return null;
          }
        }).where((review) => review != null).cast<Review>().toList();
        
        print('Final reviews count: ${reviews.length}');
        return reviews;
      } else {
        print('Failed to fetch reviews. Status: ${response.statusCode}');
        return [];
      }
      
    } catch (e) {
      print('ERROR fetchReviews: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Stack(
              children: [
                Positioned(
                    child: Container(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Image.asset(
                      Server.UrlGambar("atributhomecircle.png"),
                      scale: 1,
                    ),
                  ),
                )),
                Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Image.asset(
                          Server.UrlGambar("atributhomebigcircle.png"),
                          scale: 1,
                        ),
                      ),
                    )),
                Column(
                  children: [
                    SizedBox(
                      height: 20,
                    ),
                    _buildSectionTitle("Jasa Desain"),
                    const SizedBox(height: 5),
                    _buildJasaDesainSection(context),
                    const SizedBox(height: 20),
                    _buildSectionTitle("Inspirasi Desain"),
                    const SizedBox(height: 5),
                    _buildInspirasiDesain(context),
                    const SizedBox(height: 20),
                    _buildSectionTitle("Review"),
                    const SizedBox(height: 5),
                    _buildReviewSection(context),
                    const SizedBox(height: 20),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      decoration: BoxDecoration(
        color: CustomColors.threertyColor,
      ),
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: screenWidth * 0.15, // responsive padding
              left: screenWidth * 0.05,
              right: screenWidth * 0.05,
              bottom: 15
            ),
            child: Row(
              children: [
                Card.outlined(
                  elevation: 5,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(35),
                        bottomRight: Radius.circular(35),
                        topLeft: Radius.circular(35),
                        topRight: Radius.circular(35)),
                  ),
                  child: Container(
                    margin: EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: screenWidth < 360 ? 25 : 30, // smaller for small screens
                      backgroundImage: imageProfil.isNotEmpty
                          ? NetworkImage(
                              Server.UrlImageProfil(imageProfil),
                            )
                          : AssetImage(
                              Server.UrlGambar('logoapk.png'),
                            ) as ImageProvider,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03), // responsive spacing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaUser,
                        style: CustomText.TextArvoBold(
                          screenWidth < 360 ? 16 : 18, // smaller font for small screens
                          CustomColors.whiteColor
                        ),
                        overflow: TextOverflow.ellipsis, // prevent text overflow
                      ),
                      Text(
                        "👋 Selamat Datang!",
                        style: TextStyle(color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          Image.asset(Server.UrlGambar("atributhome.png")),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )),
      ),
    );
  }

  Widget _buildJasaDesainSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 60) / 3; // 60 = padding (20*2) + spacing (10*2)
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildServiceCard(context, "LOGO", "homeimagelogo.png", JasaDesignLogo()),
              _buildServiceCard(context, "BANNER", "homeimagebanner.png", JasaDesignBanner()),
              _buildServiceCard(context, "POSTER", "homeimageposter.png", JasaDesignPoster()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceCard(BuildContext context, String title, String imageUrl, Widget nextPage) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Expanded(
      child: TextButton(
        onPressed: () {
          print("pressed");
          Navigator.push(context, SmoothPageTransition(page: nextPage));
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 5),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            color: CustomColors.greendark,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.0, // Square aspect ratio
                    child: Image.asset(
                      Server.UrlGambar(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 3 : 5),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: CustomColors.whiteColor,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInspirasiDesain(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.6;
    
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: screenWidth * 0.05),
        children: [
          _buildInspirasiCard("assets/images/inspirasi_desain/design_inspiration1.jpg", width: cardWidth),
          _buildInspirasiCard("assets/images/inspirasi_desain/design_inspiration2.jpg", width: cardWidth),
          _buildInspirasiCard("assets/images/inspirasi_desain/design_inspiration3.jpg", width: cardWidth),
        ],
      ),
    );
  }

  Widget _buildInspirasiCard(String imagePath, {double? width}) {
    return Container(
      margin: const EdgeInsets.only(right: 15),
      width: width ?? 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback jika gambar tidak ditemukan
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported, size: 50, color: Colors.grey[600]),
                    SizedBox(height: 8),
                    Text("Gambar tidak tersedia", style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReviewSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return FutureBuilder<List<Review>>(
      future: fetchReviews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 170,
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          print('ERROR IN FUTURE BUILDER: ${snapshot.error}');
          return SizedBox(
            height: 170,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 40),
                  SizedBox(height: 8),
                  Text('Gagal memuat ulasan', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Jika tidak ada review, tampilkan pesan kosong
          return SizedBox(
            height: 170,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rate_review_outlined, color: Colors.grey, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada ulasan tersedia',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Jadilah yang pertama memberikan ulasan!',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }
        
        final reviews = snapshot.data!;
        return _buildReviewList(context, reviews);
      },
    );
  }

  Widget _buildReviewList(BuildContext context, List<Review> reviews) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: reviews.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final review = reviews[index];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildAvatarImage(review.avatarUrl, isSmallScreen),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < review.rating ? Icons.star : Icons.star_border,
                                    color: i < review.rating ? Colors.amber : Colors.grey,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      review.feedback,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarImage(String? avatarUrl, bool isSmallScreen) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Image.network(
        Server.UrlImageProfil(avatarUrl),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading avatar: $error');
          return _buildDefaultAvatar(isSmallScreen);
        },
      );
    }
    return _buildDefaultAvatar(isSmallScreen);
  }

  Widget _buildDefaultAvatar(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            CustomColors.threertyColor.withOpacity(0.8),
            CustomColors.threertyColor.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.person,
        size: isSmallScreen ? 16 : 20,
        color: Colors.white,
      ),
    );
  }
}
