class PembayaranModel {
  final String namaUser;
  final String status;
  final String bookingBy;
  final String waktu;
  final String imageUrl;

  PembayaranModel({
    required this.namaUser,
    required this.status,
    required this.bookingBy,
    required this.waktu,
    required this.imageUrl,
  });

  factory PembayaranModel.fromJson(Map<String, dynamic> json) {
    return PembayaranModel(
      namaUser: json['nama_user'],
      status: json['status'],
      bookingBy: json['booking_by'],
      waktu: json['waktu'],
      imageUrl: json['image_url'],
    );
  }
}
