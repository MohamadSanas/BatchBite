class DeliveryLocation {
  DeliveryLocation({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.isApproved,
  });

  final int id;
  final int sellerId;
  final String name;
  final double? latitude;
  final double? longitude;
  final bool isApproved;

  factory DeliveryLocation.fromJson(Map<String, dynamic> j) {
    return DeliveryLocation(
      id: j['id'] as int,
      sellerId: j['seller_id'] as int,
      name: j['name'] as String,
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      isApproved: j['is_approved'] as bool,
    );
  }
}
