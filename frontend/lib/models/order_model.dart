import 'shoe_model.dart';

class Order {
  int id;
  DateTime orderDate;
  String status;
  double totalAmount;
  List<OrderItem> items;

  Order({
    required this.id,
    required this.orderDate,
    required this.status,
    required this.totalAmount,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int? ?? 0,
      orderDate: DateTime.tryParse((json['orderDate'] ?? '') as String) ?? DateTime.now(),
      status: (json['status'] ?? '') as String,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      items: (json['items'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OrderItem {
  int id;
  ShoeModel shoe;
  ProductVariant variant;
  int quantity;
  double price;

  OrderItem({
    required this.id,
    required this.shoe,
    required this.variant,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int? ?? 0,
      shoe: ShoeModel.fromJson((json['shoe'] as Map<String, dynamic>? ?? <String, dynamic>{})),
      variant: ProductVariant.fromJson((json['variant'] as Map<String, dynamic>? ?? <String, dynamic>{})),
      quantity: json['quantity'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CartItem {
  int id;
  ShoeModel shoe;
  ProductVariant variant;
  int quantity;

  CartItem({
    required this.id,
    required this.shoe,
    required this.variant,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int? ?? 0,
      shoe: ShoeModel.fromJson((json['shoe'] as Map<String, dynamic>? ?? <String, dynamic>{})),
      variant: ProductVariant.fromJson((json['variant'] as Map<String, dynamic>? ?? <String, dynamic>{})),
      quantity: json['quantity'] as int? ?? 0,
    );
  }
}
