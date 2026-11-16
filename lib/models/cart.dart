import 'package:mongo_dart/mongo_dart.dart';

class CartItem {
  CartItem({
    required this.productId,
    required this.name,
    this.category = 'Beauty',
    required this.price,
    this.currency = 'USD',
    this.quantity = 1,
    this.imageUrl = '',
  });

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'Beauty',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      currency: (map['currency'] as String? ?? 'USD').toUpperCase(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      imageUrl: map['imageUrl'] as String? ?? '',
    );
  }

  final String productId;
  final String name;
  final String category;
  final double price;
  final String currency;
  final int quantity;
  final String imageUrl;

  double get subtotal => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'category': category,
      'price': price,
      'currency': currency,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'subtotal': subtotal,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'category': category,
      'price': price,
      'currency': currency,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'subtotal': subtotal,
    };
  }

  CartItem copyWith({
    String? productId,
    String? name,
    String? category,
    double? price,
    String? currency,
    int? quantity,
    String? imageUrl,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class Cart {
  Cart({
    this.id,
    required this.userId,
    List<CartItem>? items,
    this.promoCode,
    this.discount = 0.0,
    this.shippingFee = 0.0,
    DateTime? updatedAt,
  })  : items = items ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  factory Cart.fromMap(Map<String, dynamic> map) {
    String? idStr;
    if (map['_id'] != null) {
      if (map['_id'] is ObjectId) {
        idStr = (map['_id'] as ObjectId).toHexString();
      } else {
        idStr = map['_id'].toString();
      }
    }

    final rawItems = map['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((item) => CartItem.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();

    return Cart(
      id: idStr,
      userId: map['userId'] as String? ?? '',
      items: itemsList,
      promoCode: map['promoCode'] as String?,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (map['shippingFee'] as num?)?.toDouble() ?? 0.0,
      updatedAt: map['updatedAt'] is DateTime
          ? map['updatedAt'] as DateTime
          : DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  final String? id;
  final String userId;
  final List<CartItem> items;
  final String? promoCode;
  final double discount;
  final double shippingFee;
  final DateTime updatedAt;

  int get totalItemCount =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      items.fold<double>(0.0, (sum, item) => sum + item.subtotal);

  double get total {
    final t = subtotal - discount + shippingFee;
    return t > 0 ? t : 0.0;
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    final map = <String, dynamic>{
      'userId': userId,
      'items': items.map((i) => i.toMap()).toList(),
      'promoCode': promoCode,
      'discount': discount,
      'shippingFee': shippingFee,
      'subtotal': subtotal,
      'total': total,
      'updatedAt': updatedAt.toIso8601String(),
    };

    if (includeId && id != null) {
      map['_id'] = ObjectId.fromHexString(id!);
    }
    return map;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'itemCount': totalItemCount,
      'items': items.map((i) => i.toJson()).toList(),
      'promoCode': promoCode,
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'discount': discount,
      'total': total,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

