class SellerSummary {
  SellerSummary({
    required this.sellerId,
    required this.userId,
    required this.kitchenName,
    required this.description,
    required this.university,
  });

  final int sellerId;
  final int userId;
  final String kitchenName;
  final String? description;
  final String university;

  factory SellerSummary.fromJson(Map<String, dynamic> j) {
    return SellerSummary(
      sellerId: j['seller_id'] as int,
      userId: j['user_id'] as int,
      kitchenName: j['kitchen_name'] as String,
      description: j['description'] as String?,
      university: j['university'] as String,
    );
  }
}
