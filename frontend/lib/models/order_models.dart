class OrderItemLine {
  OrderItemLine({
    required this.id,
    required this.foodItemId,
    required this.quantity,
    this.foodName,
    this.unitPrice,
  });

  final int id;
  final int foodItemId;
  final int quantity;
  final String? foodName;
  final double? unitPrice;

  factory OrderItemLine.fromJson(Map<String, dynamic> j) {
    return OrderItemLine(
      id: j['id'] as int,
      foodItemId: j['food_item_id'] as int,
      quantity: j['quantity'] as int,
      foodName: j['food_name'] as String?,
      unitPrice: (j['unit_price'] as num?)?.toDouble(),
    );
  }
}

class OrderModel {
  OrderModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.status,
    required this.deliveryLocationId,
    this.deliveryLocationName,
    required this.deadlineTime,
    required this.createdAt,
    this.cancellationReason,
    required this.items,
    this.kitchenName,
  });

  final int id;
  final int buyerId;
  final int sellerId;
  final String status;
  final int deliveryLocationId;
  final String? deliveryLocationName;
  final DateTime deadlineTime;
  final DateTime createdAt;
  final String? cancellationReason;
  final List<OrderItemLine> items;
  final String? kitchenName;

  bool get isReady => status == 'ready';

  factory OrderModel.fromJson(Map<String, dynamic> j) {
    final rawItems = j['items'] as List<dynamic>? ?? [];
    return OrderModel(
      id: j['id'] as int,
      buyerId: j['buyer_id'] as int,
      sellerId: j['seller_id'] as int,
      status: j['status'] as String,
      deliveryLocationId: j['delivery_location_id'] as int,
      deliveryLocationName: j['delivery_location_name'] as String?,
      deadlineTime: DateTime.parse(j['deadline_time'] as String),
      createdAt: DateTime.parse(j['created_at'] as String),
      cancellationReason: j['cancellation_reason'] as String?,
      items: rawItems.map((e) => OrderItemLine.fromJson(e as Map<String, dynamic>)).toList(),
      kitchenName: j['kitchen_name'] as String?,
    );
  }
}
