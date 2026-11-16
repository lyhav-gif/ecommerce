import 'package:api/models/cart.dart';
import 'package:mongo_dart/mongo_dart.dart';

class Order {
  Order({
    this.id,
    required this.orderNumber,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.items,
    required this.subtotal,
    this.shippingFee = 0.0,
    this.discount = 0.0,
    required this.totalAmount,
    this.currency = 'USD',
    this.paymentMethod = 'digital_payment', // 'digital_payment' or 'cash_on_delivery'
    this.paymentStatus = 'PENDING', // 'PENDING', 'PAID', 'COD_PENDING'
    this.orderStatus = 'PLACED',
    this.deliveryAddress = 'Street 2004, Phnom Penh, Cambodia',
    this.khqr,
    this.md5,
    this.qrImageUrl,
    this.qrImageUrlFallback,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Order.fromMap(Map<String, dynamic> map) {
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

    final khqrStr = map['khqr'] as String?;
    final defaultQrUrl = khqrStr != null && khqrStr.isNotEmpty
        ? 'https://api.qrserver.com/v1/create-qr-code/?size=500x500&margin=2&ecc=M&data=${Uri.encodeComponent(khqrStr)}'
        : null;
    final defaultFallback = khqrStr != null && khqrStr.isNotEmpty
        ? 'https://quickchart.io/qr?size=500&margin=2&ecLevel=M&text=${Uri.encodeComponent(khqrStr)}'
        : null;

    return Order(
      id: idStr,
      orderNumber: map['orderNumber'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerEmail: map['customerEmail'] as String? ?? '',
      items: itemsList,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (map['shippingFee'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      currency: (map['currency'] as String? ?? 'USD').toUpperCase(),
      paymentMethod: map['paymentMethod'] as String? ?? 'digital_payment',
      paymentStatus: map['paymentStatus'] as String? ?? 'PENDING',
      orderStatus: map['orderStatus'] as String? ?? 'PLACED',
      deliveryAddress: map['deliveryAddress'] as String? ?? '',
      khqr: khqrStr,
      md5: map['md5'] as String?,
      qrImageUrl: map['qrImageUrl'] as String? ?? defaultQrUrl,
      qrImageUrlFallback: map['qrImageUrlFallback'] as String? ?? defaultFallback,
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
              DateTime.now(),
      updatedAt: map['updatedAt'] is DateTime
          ? map['updatedAt'] as DateTime
          : DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  final String? id;
  final String orderNumber;
  final String userId;
  final String customerName;
  final String customerEmail;
  final List<CartItem> items;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double totalAmount;
  final String currency;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String deliveryAddress;
  final String? khqr;
  final String? md5;
  final String? qrImageUrl;
  final String? qrImageUrlFallback;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap({bool includeId = true}) {
    final map = <String, dynamic>{
      'orderNumber': orderNumber,
      'userId': userId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'discount': discount,
      'totalAmount': totalAmount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'deliveryAddress': deliveryAddress,
      'khqr': khqr,
      'md5': md5,
      'qrImageUrl': qrImageUrl,
      'qrImageUrlFallback': qrImageUrlFallback,
      'createdAt': createdAt.toIso8601String(),
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
      'orderNumber': orderNumber,
      'userId': userId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'itemCount': items.length,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'discount': discount,
      'totalAmount': totalAmount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'deliveryAddress': deliveryAddress,
      if (khqr != null) 'khqr': khqr,
      if (md5 != null) 'md5': md5,
      if (qrImageUrl != null) 'qrImageUrl': qrImageUrl,
      if (qrImageUrlFallback != null) 'qrImageUrlFallback': qrImageUrlFallback,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

