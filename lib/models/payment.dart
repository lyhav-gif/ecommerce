import 'package:mongo_dart/mongo_dart.dart';

typedef Payment = PaymentRecord;

class PaymentRecord {
  static String buildQrImageUrl(String qr) {
    return 'https://api.qrserver.com/v1/create-qr-code/?size=500x500&margin=2&ecc=M&data=${Uri.encodeComponent(qr)}';
  }

  static String buildQrImageFallbackUrl(String qr) {
    return 'https://quickchart.io/qr?size=500&margin=2&ecLevel=M&text=${Uri.encodeComponent(qr)}';
  }

  PaymentRecord({
    this.id,
    required this.md5,
    required this.qr,
    String? qrImageUrl,
    String? qrImageUrlFallback,
    required this.amount,
    required this.currency,
    required this.bakongAccountId,
    required this.merchantName,
    this.billNumber = '',
    this.status = 'PENDING',
    this.productId,
    this.orderId,
    this.transactionHash,
    this.paidAt,
    this.metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : qrImageUrl = qrImageUrl ?? buildQrImageUrl(qr),
        qrImageUrlFallback = qrImageUrlFallback ?? buildQrImageFallbackUrl(qr),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    String? idStr;
    if (map['_id'] != null) {
      if (map['_id'] is ObjectId) {
        idStr = (map['_id'] as ObjectId).toHexString();
      } else {
        idStr = map['_id'].toString();
      }
    }

    final qrStr = map['qr'] as String? ?? '';
    final defaultUrl = buildQrImageUrl(qrStr);
    final fallbackUrl = buildQrImageFallbackUrl(qrStr);

    return PaymentRecord(
      id: idStr,
      md5: map['md5'] as String? ?? '',
      qr: qrStr,
      qrImageUrl: map['qrImageUrl'] as String? ?? defaultUrl,
      qrImageUrlFallback: map['qrImageUrlFallback'] as String? ?? fallbackUrl,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'USD',
      bakongAccountId: map['bakongAccountId'] as String? ?? '',
      merchantName: map['merchantName'] as String? ?? '',
      billNumber: map['billNumber'] as String? ?? '',
      status: map['status'] as String? ?? 'PENDING',
      productId: map['productId'] as String?,
      orderId: map['orderId'] as String?,
      transactionHash: map['transactionHash'] as String?,
      paidAt: map['paidAt'] != null
          ? (map['paidAt'] is DateTime
              ? map['paidAt'] as DateTime
              : DateTime.tryParse(map['paidAt'].toString()))
          : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] is DateTime
          ? map['updatedAt'] as DateTime
          : DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String? id;
  final String md5;
  final String qr;
  final String qrImageUrl;
  final String qrImageUrlFallback;
  final double amount;
  final String currency;
  final String bakongAccountId;
  final String merchantName;
  final String billNumber;
  final String status; // PENDING, PAID, FAILED, EXPIRED
  final String? productId;
  final String? orderId;
  final String? transactionHash;
  final DateTime? paidAt;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap({bool includeId = true}) {
    final map = <String, dynamic>{
      'md5': md5,
      'qr': qr,
      'qrImageUrl': qrImageUrl,
      'qrImageUrlFallback': qrImageUrlFallback,
      'amount': amount,
      'currency': currency,
      'bakongAccountId': bakongAccountId,
      'merchantName': merchantName,
      'billNumber': billNumber,
      'status': status,
      if (productId != null) 'productId': productId,
      if (orderId != null) 'orderId': orderId,
      if (transactionHash != null) 'transactionHash': transactionHash,
      if (paidAt != null) 'paidAt': paidAt!.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
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
      'md5': md5,
      'qr': qr,
      'qrImageUrl': qrImageUrl,
      'qrImageUrlFallback': qrImageUrlFallback,
      'amount': amount,
      'currency': currency,
      'bakongAccountId': bakongAccountId,
      'merchantName': merchantName,
      'billNumber': billNumber,
      'status': status,
      if (productId != null) 'productId': productId,
      if (orderId != null) 'orderId': orderId,
      if (transactionHash != null) 'transactionHash': transactionHash,
      if (paidAt != null) 'paidAt': paidAt!.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
