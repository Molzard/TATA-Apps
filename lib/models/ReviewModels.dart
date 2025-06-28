class Review {
  final String id;
  final String name;
  final int rating;
  final String feedback;
  final String? avatarUrl;
  final String? service;
  final String? orderUuid;
  final String? completionDate;
  final String? reviewDate;

  Review({
    required this.id,
    required this.name,
    required this.rating,
    required this.feedback,
    this.avatarUrl,
    this.service,
    this.orderUuid,
    this.completionDate,
    this.reviewDate,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    print('Parsing review JSON: $json');
    
    final avatarUrl = json['avatar_url']?.toString();
    print('Avatar URL from JSON: $avatarUrl');
    
    return Review(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Pengguna',
      rating: int.tryParse(json['rating']?.toString() ?? '5') ?? 5,
      feedback: json['feedback']?.toString() ?? '',
      avatarUrl: avatarUrl,
      service: json['service']?.toString(),
      orderUuid: json['order_uuid']?.toString(),
      completionDate: json['completion_date']?.toString(),
      reviewDate: json['review_date']?.toString(),
    );
  }
}
