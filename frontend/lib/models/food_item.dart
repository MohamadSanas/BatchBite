class FoodItem {
  FoodItem({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.price,
    required this.available,
  });

  final int id;
  final int sellerId;
  final String name;
  final double price;
  final bool available;

  factory FoodItem.fromJson(Map<String, dynamic> j) {
    return FoodItem(
      id: j['id'] as int,
      sellerId: j['seller_id'] as int,
      name: j['name'] as String,
      price: (j['price'] as num).toDouble(),
      available: j['available'] as bool,
    );
  }
}
