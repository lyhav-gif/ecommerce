import 'package:mongo_dart/mongo_dart.dart';

class Product {
  Product({
    required this.name,
    required this.price,
    this.id,
    this.description = '',
    this.currency = 'USD',
    this.imageUrl = '',
    this.category = 'Beauty',
    this.brand = '',
    this.rating = 4.9,
    this.reviewCount = 128,
    this.stock = 100,
    this.tag = '',
    this.isFlash = false,
    this.khqr,
    this.md5,
    String? qrImageUrl,
    String? qrImageUrlFallback,
    this.bakongAccountId,
    this.merchantName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : qrImageUrl =
           qrImageUrl ??
           (khqr != null && khqr.isNotEmpty ? buildQrImageUrl(khqr) : null),
       qrImageUrlFallback =
           qrImageUrlFallback ??
           (khqr != null && khqr.isNotEmpty
               ? buildQrImageFallbackUrl(khqr)
               : null),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Product.fromMap(Map<String, dynamic> map) {
    String? idStr;
    if (map['_id'] != null) {
      if (map['_id'] is ObjectId) {
        idStr = (map['_id'] as ObjectId).oid;
      } else {
        idStr = map['_id'].toString();
      }
    }

    final rawQr = map['khqr'] as String?;
    final rawUrl = map['qrImageUrl'] as String?;
    final rawFallback = map['qrImageUrlFallback'] as String?;

    return Product(
      id: idStr,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      currency: (map['currency'] as String? ?? 'USD').toUpperCase(),
      imageUrl: map['imageUrl'] as String? ?? '',
      category: map['category'] as String? ?? 'Beauty',
      brand: map['brand'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.9,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 128,
      stock: (map['stock'] as num?)?.toInt() ?? 100,
      tag: map['tag'] as String? ?? '',
      isFlash: map['isFlash'] as bool? ?? false,
      khqr: rawQr,
      md5: map['md5'] as String?,
      qrImageUrl:
          rawUrl ??
          (rawQr != null && rawQr.isNotEmpty ? buildQrImageUrl(rawQr) : null),
      qrImageUrlFallback:
          rawFallback ??
          (rawQr != null && rawQr.isNotEmpty
              ? buildQrImageFallbackUrl(rawQr)
              : null),
      bakongAccountId: map['bakongAccountId'] as String?,
      merchantName: map['merchantName'] as String?,
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
  static String buildQrImageUrl(String qr) {
    return 'https://api.qrserver.com/v1/create-qr-code/?size=500x500&margin=2&ecc=M&data=${Uri.encodeComponent(qr)}';
  }

  static String buildQrImageFallbackUrl(String qr) {
    return 'https://quickchart.io/qr?size=500&margin=2&ecLevel=M&text=${Uri.encodeComponent(qr)}';
  }

  final String? id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String imageUrl;
  final String category;
  final String brand;
  final double rating;
  final int reviewCount;
  final int stock;
  final String tag;
  final bool isFlash;
  final String? khqr;
  final String? md5;
  final String? qrImageUrl;
  final String? qrImageUrlFallback;
  final String? bakongAccountId;
  final String? merchantName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? currency,
    String? imageUrl,
    String? category,
    String? brand,
    double? rating,
    int? reviewCount,
    int? stock,
    String? tag,
    bool? isFlash,
    String? khqr,
    String? md5,
    String? qrImageUrl,
    String? qrImageUrlFallback,
    String? bakongAccountId,
    String? merchantName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      stock: stock ?? this.stock,
      tag: tag ?? this.tag,
      isFlash: isFlash ?? this.isFlash,
      khqr: khqr ?? this.khqr,
      md5: md5 ?? this.md5,
      qrImageUrl: qrImageUrl ?? this.qrImageUrl,
      qrImageUrlFallback: qrImageUrlFallback ?? this.qrImageUrlFallback,
      bakongAccountId: bakongAccountId ?? this.bakongAccountId,
      merchantName: merchantName ?? this.merchantName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'imageUrl': imageUrl,
      'category': category,
      'brand': brand,
      'rating': rating,
      'reviewCount': reviewCount,
      'stock': stock,
      'tag': tag,
      'isFlash': isFlash,
      if (khqr != null) 'khqr': khqr,
      if (md5 != null) 'md5': md5,
      if (qrImageUrl != null) 'qrImageUrl': qrImageUrl,
      if (qrImageUrlFallback != null) 'qrImageUrlFallback': qrImageUrlFallback,
      if (bakongAccountId != null) 'bakongAccountId': bakongAccountId,
      if (merchantName != null) 'merchantName': merchantName,
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
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'imageUrl': imageUrl,
      'category': category,
      'brand': brand,
      'rating': rating,
      'reviewCount': reviewCount,
      'stock': stock,
      'tag': tag,
      'isFlash': isFlash,
      if (khqr != null) 'khqr': khqr,
      if (md5 != null) 'md5': md5,
      if (qrImageUrl != null) 'qrImageUrl': qrImageUrl,
      if (qrImageUrlFallback != null) 'qrImageUrlFallback': qrImageUrlFallback,
      if (bakongAccountId != null) 'bakongAccountId': bakongAccountId,
      if (merchantName != null) 'merchantName': merchantName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
