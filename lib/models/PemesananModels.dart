class Pemesanan {
  final String id;
  final String desk;
  final String judul;
  final String kategori;
  final String estimasi;
  final String gambarReferensi;
  final String tanggal;
  final String tanggalselesai;
  final int total;
  final int revisi;
  final String status;

  Pemesanan({
    required this.id,
    required this.desk,
    required this.judul,
    required this.estimasi,
    required this.gambarReferensi,
    required this.kategori,
    required this.tanggal,
    required this.tanggalselesai,
    required this.total,
    required this.revisi,
    required this.status,
  });

  factory Pemesanan.fromJson(Map<String, dynamic> json) {
    return Pemesanan(
      revisi: int.parse(json['maksimal_revisi'].toString()) ?? 0,
      estimasi: "${json['estimasi_waktu'] ?? ''}",
      gambarReferensi: "${json['gambar_referensi'] ?? ''}",
      desk: "${json['deskripsi'] ?? ''}",
      id: "${json['uuid'] ?? ''}",
      judul: "Desain ${capitalize(json['kategori'])}", // e.g. "Desain Logo"
      kategori:
          "${capitalize(json['kategori'])}, ${capitalize(json['kelas_jasa'])}",
      tanggal: formatTanggal(json['created_at']),
      total: int.tryParse(json['harga_paket_jasa'].toString()) ?? 0,
      status: json['status_pengerjaan'] != null ? 
              konversiStatus(json['status_pengerjaan']) : 
              konversiStatus(json['status_pesanan']),
      tanggalselesai: json['updated_at'] != null ? 
                      (json['updated_at'].toString().contains('-') ? formatTanggal(json['updated_at']) : '') : 
                      "",
    );
  }

  static String capitalize(String? value) {
    if (value == null || value.isEmpty) return '';
    return value[0].toUpperCase() + value.substring(1);
  }

  static String formatTanggal(String tanggal) {
    try {
      final date = DateTime.tryParse(tanggal);
      if (date == null) return '';
      return "${date.day} ${_namaBulan(date.month)}";
    } catch (e) {
      print("Error formatting date: $e");
      return '';
    }
  }

  static String _namaBulan(int bulan) {
    const bulanIndo = [
      '', // indeks 0 tidak dipakai
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return bulanIndo[bulan];
  }

  static String konversiStatus(String statusApi) {
    switch (statusApi) {
      case 'pending':
        return 'Menunggu';
      case 'diproses':
        return 'Diproses';
      case 'dikerjakan':
        return 'Dikerjakan';
      case 'selesai':
        return 'Selesai';
      default:
        return capitalize(statusApi);
    }
  }
}
