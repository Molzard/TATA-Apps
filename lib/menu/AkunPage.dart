import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:TATA/BeforeLogin/page_login.dart';
import 'package:TATA/helper/user_preferences.dart';
import 'package:TATA/sendApi/Server.dart';
import 'package:TATA/src/CustomColors.dart';
import 'package:TATA/src/pageTransition.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Akunpage extends StatefulWidget {
  const Akunpage({super.key});

  @override
  State<Akunpage> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<Akunpage> {
  File? selectedImageFile;
  Uint8List? selectedImageWeb;
  bool get hasSelectedImage => selectedImageFile != null || selectedImageWeb != null;
  
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        // Web platform
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          selectedImageWeb = bytes;
        });
      } else {
        // Mobile platform
        setState(() {
          selectedImageFile = File(pickedFile.path);
        });
      }
    }
  }

  bool isEditing = false;
  bool isLoading = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String imageProfil = "";
  String nameLama = "";
  String emailLama = "";
  String phoneLama = "";

  Future<void> fetchUserProfile() async {
    try {
      final userData = await UserPreferences.getUser();
      print("ALLDATAA : $userData");
      
      if (userData == null) {
        print("User data is null");
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Extract user data from various possible structures
      Map<String, dynamic>? userInfo;
      
      if (userData.containsKey('data') && 
          userData['data'] != null && 
          userData['data'].containsKey('user') && 
          userData['data']['user'] != null) {
        userInfo = userData['data']['user'];
        print("User data found in data.user structure");
      } else if (userData.containsKey('user') && userData['user'] != null) {
        userInfo = userData['user'];
        print("User data found in user structure");
      } else if (userData.containsKey('id') && 
                 userData.containsKey('name') && 
                 userData.containsKey('email')) {
        userInfo = userData;
        print("User data found directly in top level");
      }
      
      if (userInfo != null) {
        print("tlpn : ${userInfo['no_telpon'] ?? 'tidak ada'}");
        print("foto : ${userInfo['foto'] ?? 'tidak ada'}");
        
        setState(() {
          imageProfil = userInfo!['foto'] ?? '';
          nameController.text = userInfo!['name'] ?? '';
          emailController.text = userInfo!['email'] ?? '';
          phoneController.text = userInfo!['no_telpon'] ?? '';
          nameLama = userInfo!['name'] ?? '';
          emailLama = userInfo!['email'] ?? '';
          phoneLama = userInfo!['no_telpon'] ?? '';
          isLoading = false;
        });
      } else {
        print("Data user tidak lengkap atau null");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error saat mengambil data user: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateUserProfile() async {
    setState(() {
      isLoading = true;
    });
    
    final userData = await UserPreferences.getUser();
    if (userData == null) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat mengakses data user untuk update profil')),
      );
      return;
    }
    
    // Extract token from different possible structures
    String? token;
    if (userData.containsKey('access_token')) {
      token = userData['access_token'];
    } else if (userData.containsKey('data') && 
               userData['data'] != null && 
               userData['data'].containsKey('access_token')) {
      token = userData['data']['access_token'];
    }
    
    if (token == null) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token tidak ditemukan, silakan login kembali')),
      );
      return;
    }
    
    // Fix: Use the correct endpoint URL for profile update
    // Based on the backend routes, user/profile/update is the correct endpoint
    final url = Server.urlLaravel('user/profile/update');

    try {
      print('Memulai update profil...');
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['nama_user'] = nameController.text;
      request.fields['no_telpon'] = phoneController.text;
      request.fields['email'] = emailController.text;

      if (selectedImageFile != null || selectedImageWeb != null) {
        if (kIsWeb && selectedImageWeb != null) {
          // Web platform
          print('Uploading image from web platform');
          request.files.add(http.MultipartFile.fromBytes(
            'foto',
            selectedImageWeb!,
            filename: 'profile_image.jpg',
          ));
        } else if (!kIsWeb && selectedImageFile != null) {
          // Mobile platform
          print('Uploading image from mobile platform');
          final fileStream = http.ByteStream(selectedImageFile!.openRead());
          final length = await selectedImageFile!.length();
          final filename = selectedImageFile!.path.split('/').last;

          request.files.add(http.MultipartFile(
            'foto',
            fileStream,
            length,
            filename: filename,
          ));
        }
      }

      print('Sending update profile request to: ${url.toString()}');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final Jsondata = jsonDecode(response.body);
          if (Jsondata != null && Jsondata['data'] != null) {
            setState(() {
              isEditing = false;
              selectedImageFile = null;
              selectedImageWeb = null;
              
              // Verifikasi bahwa foto ada dalam respons
              if (Jsondata['data']['user'] != null && Jsondata['data']['user']['foto'] != null) {
                imageProfil = Jsondata['data']['user']['foto'];
                print('Updated profile image: $imageProfil');
              } else {
                print('No profile image in response');
              }
              
              isLoading = false;
            });
            
            await UserPreferences.saveUser(Jsondata['data']);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              elevation: 5,
              backgroundColor: CustomColors.fourtyColor,
              content: Text("Berhasil update profil"),
            ));
          } else {
            throw Exception('Invalid response format');
          }
        } catch (e) {
          setState(() {
            isLoading = false;
          });
          print('Error parsing response: $e');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal memproses respons server: $e'),
          ));
        }
      } else {
        setState(() {
          isLoading = false;
        });
        
        String errorMessage = 'Gagal update profil';
        try {
          final Jsondata = jsonDecode(response.body);
          if (Jsondata != null && Jsondata["errors"] != null) {
            if (Jsondata["errors"]["nama_user"] != null) {
              errorMessage = Jsondata["errors"]["nama_user"];
            } else if (Jsondata["errors"]['email'] != null) {
              errorMessage = Jsondata["errors"]['email'];
            } else if (Jsondata["message"] != null) {
              errorMessage = Jsondata["message"];
            }
          }
        } catch (e) {
          errorMessage = 'Gagal memproses respons server: $e';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage),
        ));
        print('Error saat update: ${response.body}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saat update: $e')),
      );
      print('Exception saat update: $e');
    }
  }

  Future<void> bataledit() async {
    setState(() {
      nameController.text = nameLama;
      emailController.text = emailLama;
      phoneController.text = phoneLama;
      isEditing = false;
    });
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      fetchUserProfile();
    });
    // loadUserData();
  }

  Widget buildInputField({
    required TextInputType kerboardType,
    required IconData icon,
    required TextEditingController controller,
    bool enabled = false,
    String? hintText,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: kerboardType,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: enabled ? Colors.black87 : Colors.grey.shade600,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.only(right: 12),
            child: Icon(
              icon,
              color: enabled ? CustomColors.primaryColor : Colors.grey.shade400,
              size: 22,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: CustomColors.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.primaryColor,
      body: Stack(
        children: [
          Image.asset(Server.UrlGambar("atributhome.png")),
          Positioned(
              right: 0,
              top: 0,
              child: Container(
                child: Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    Server.UrlGambar("atributprofilkananatas.png"),
                    scale: 1,
                  ),
                ),
              )),
          Positioned(
              left: 0,
              top: 80,
              bottom: 0,
              child: Container(
                child: Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    Server.UrlGambar("atributprofiltengahkanan.png"),
                    scale: 1,
                  ),
                ),
              )),
          Positioned(
              right: 0,
              top: 200,
              bottom: 0,
              child: Container(
                child: Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    Server.UrlGambar("atributprofiltengahkanan1.png"),
                    scale: 1,
                  ),
                ),
              )),
          SafeArea(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Memuat profil...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      children: [
                        // Header with action buttons
                        Container(
                          margin: EdgeInsets.only(top: 10, bottom: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Title
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Profil Saya',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: CustomColors.primaryColor,
                                  ),
                                ),
                              ),
                              // Action buttons
                              if (isEditing)
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: bataledit,
                                        icon: Icon(Icons.close, size: 18),
                                        label: Text('Batal'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade400,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: updateUserProfile,
                                        icon: Icon(Icons.check, size: 18),
                                        label: Text('Simpan'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade500,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () => setState(() => isEditing = true),
                                    icon: Icon(Icons.edit, size: 18),
                                    label: Text('Edit Profil'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: CustomColors.primaryColor,
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Profile picture section
                        Container(
                          margin: EdgeInsets.only(bottom: 24),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: hasSelectedImage
                                        ? kIsWeb && selectedImageWeb != null
                                            ? Image.memory(
                                                selectedImageWeb!,
                                                width: 140,
                                                height: 140,
                                                fit: BoxFit.cover,
                                              )
                                            : !kIsWeb && selectedImageFile != null
                                                ? Image.file(
                                                    selectedImageFile!,
                                                    width: 140,
                                                    height: 140,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Image.asset(
                                                    Server.UrlGambar('logotext.png'),
                                                    width: 140,
                                                    height: 140,
                                                  )
                                        : imageProfil.isNotEmpty
                                            ? Image.network(
                                                Server.UrlImageProfil(imageProfil),
                                                width: 140,
                                                height: 140,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  print('Error loading profile image: $error');
                                                  return Image.asset(
                                                    Server.UrlGambar('logotext.png'),
                                                    width: 140,
                                                    height: 140,
                                                  );
                                                },
                                              )
                                            : Image.asset(
                                                Server.UrlGambar('logotext.png'),
                                                width: 140,
                                                height: 140,
                                              ),
                                  ),
                                ),
                              ),
                              if (isEditing)
                                Positioned(
                                  bottom: 5,
                                  right: 5,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: CustomColors.primaryColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      onPressed: pickImage,
                                      icon: Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.all(8),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Input fields section
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Informasi Profil',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 20),
                              buildInputField(
                                kerboardType: TextInputType.name,
                                icon: Icons.person_outline,
                                controller: nameController,
                                enabled: isEditing,
                                hintText: 'Nama lengkap',
                              ),
                              buildInputField(
                                kerboardType: TextInputType.emailAddress,
                                icon: Icons.email_outlined,
                                controller: emailController,
                                enabled: isEditing,
                                hintText: 'Alamat email',
                              ),
                              buildInputField(
                                kerboardType: TextInputType.number,
                                icon: Icons.phone_outlined,
                                controller: phoneController,
                                enabled: isEditing,
                                hintText: 'Nomor telepon',
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 40),
                        
                        // Logout button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                // Hapus FCM token dari server
                                final userData = await UserPreferences.getUser();
                                if (userData != null) {
                                  final fcmToken = await UserPreferences.getFcmToken();
                                  if (fcmToken != null) {
                                    try {
                                      // Extract token from different possible structures
                                      String? authToken;
                                      if (userData.containsKey('access_token')) {
                                        authToken = userData['access_token'];
                                      } else if (userData.containsKey('data') && 
                                                userData['data'] != null && 
                                                userData['data'].containsKey('access_token')) {
                                        authToken = userData['data']['access_token'];
                                      }
                                      
                                      if (authToken != null) {
                                        // Kirim permintaan untuk menghapus token
                                        await http.post(
                                          Server.urlLaravel('api/users/logout'),
                                          headers: {
                                            'Content-Type': 'application/json',
                                            'Accept': 'application/json',
                                            'Authorization': 'Bearer $authToken',
                                          },
                                          body: jsonEncode({
                                            'fcm_token': fcmToken
                                          }),
                                        );
                                      }
                                    } catch (e) {
                                      print('Error menghapus FCM token dari server: $e');
                                    }
                                  }
                                }
                                
                                // Hapus data user dan FCM token dari SharedPreferences
                                await UserPreferences.removeUser();
                                await UserPreferences.removeFcmToken();
                                
                                // Logout dari Firebase Auth jika menggunakan Firebase Auth
                                if (FirebaseAuth.instance.currentUser != null) {
                                  await FirebaseAuth.instance.signOut();
                                }
                                
                                // Arahkan ke halaman login
                                Navigator.pushReplacement(
                                  context, 
                                  SmoothPageTransition(page: page_login())
                                );
                              } catch (e) {
                                print('Error during logout: $e');
                                // Tetap arahkan ke halaman login meskipun terjadi error
                                Navigator.pushReplacement(
                                  context, 
                                  SmoothPageTransition(page: page_login())
                                );
                              }
                            },
                            icon: Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            label: Text(
                              'Keluar dari Akun',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF09143C),
                              elevation: 0,
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
