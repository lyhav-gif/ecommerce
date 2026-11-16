import 'package:api/database/mongo_db.dart';
import 'package:api/models/payment.dart';
import 'package:api/services/bakong_service.dart';
import 'package:mongo_dart/mongo_dart.dart';

class PaymentService {
  PaymentService({
    required MongoDatabase database,
    required BakongService bakongService,
  }) : _database = database,
       _bakongService = bakongService;

  final MongoDatabase _database;
  final BakongService _bakongService;

  Future<PaymentRecord> createPayment({
    required double amount,
    String? currency,
    String? productId,
    String? orderId,
    String? billNumber,
    Map<String, dynamic>? metadata,
  }) async {
    await _database.connect();

    final curString = (currency != null && currency.isNotEmpty)
        ? currency.toUpperCase()
        : 'USD';

    final generatedBillNumber = billNumber != null && billNumber.isNotEmpty
        ? billNumber
        : (amount > 0 ? 'ORD-${DateTime.now().millisecondsSinceEpoch}' : '');

    final generated = _bakongService.generateIndividualKhqr(
      amount: amount,
      currency: curString,
      billNumber: generatedBillNumber.isNotEmpty ? generatedBillNumber : null,
    );

    final payment = PaymentRecord(
      md5: generated.md5,
      qr: generated.qr,
      amount: amount,
      currency: generated.currency,
      bakongAccountId: generated.bakongAccountId,
      merchantName: generated.merchantName,
      billNumber: generatedBillNumber,
      status: 'PENDING',
      productId: productId,
      orderId: orderId,
      metadata: metadata,
    );

    final map = payment.toMap(includeId: false);
    final res = await _database.payments.insertOne(map);
    final insertedId = res.id is ObjectId
        ? (res.id as ObjectId).toHexString()
        : res.id?.toString();

    return PaymentRecord.fromMap({
      ...map,
      '_id': insertedId != null ? ObjectId.fromHexString(insertedId) : null,
    });
  }

  Future<Map<String, dynamic>> verifyPayment(String md5) async {
    await _database.connect();

    final doc = await _database.payments.findOne(where.eq('md5', md5.trim()));
    PaymentRecord? payment = doc != null ? PaymentRecord.fromMap(doc) : null;

    final bakongRes = await _bakongService.checkTransactionByMd5(md5);

    if (bakongRes.isSuccess) {
      final txData = bakongRes.data;
      final txHash =
          txData?['hash']?.toString() ?? txData?['tranId']?.toString();
      final paidAtStr = txData?['paidAt']?.toString();
      final paidAt = paidAtStr != null
          ? DateTime.tryParse(paidAtStr)
          : DateTime.now();

      await _database.payments.updateOne(
        where.eq('md5', md5.trim()),
        modify
            .set('status', 'PAID')
            .set('transactionHash', txHash)
            .set(
              'paidAt',
              paidAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
            )
            .set('updatedAt', DateTime.now().toIso8601String()),
      );

      final updatedDoc = await _database.payments.findOne(
        where.eq('md5', md5.trim()),
      );
      if (updatedDoc != null) {
        payment = PaymentRecord.fromMap(updatedDoc);
      }

      return {
        'status': 'PAID',
        'isPaid': true,
        'message': 'Transaction verified successfully',
        'payment': payment?.toJson(),
        'bakong': bakongRes.toJson(),
      };
    } else {
      return {
        'status': payment?.status ?? 'PENDING',
        'isPaid': false,
        'message': bakongRes.responseMessage,
        'responseCode': bakongRes.responseCode,
        'payment': payment?.toJson(),
        'bakong': bakongRes.toJson(),
      };
    }
  }

  Future<PaymentRecord?> getPaymentByMd5(String md5) async {
    await _database.connect();
    final doc = await _database.payments.findOne(where.eq('md5', md5.trim()));
    if (doc == null) return null;
    return PaymentRecord.fromMap(doc);
  }

  Future<List<PaymentRecord>> getAllPayments() async {
    await _database.connect();
    final list = await _database.payments.find().toList();
    return list.map(PaymentRecord.fromMap).toList();
  }

  Future<PaymentRecord> upsertStaticPayment({
    required String qr,
    required String md5,
    required String currency,
    String? qrImageUrl,
  }) async {
    await _database.connect();

    final existing = await _database.payments.findOne(where.eq('md5', md5.trim()));
    if (existing != null) {
      return PaymentRecord.fromMap(existing);
    }

    final payment = PaymentRecord(
      md5: md5,
      qr: qr,
      qrImageUrl: qrImageUrl,
      amount: 0.0,
      currency: currency,
      bakongAccountId: _bakongService.config.bakongAccountId,
      merchantName: _bakongService.config.bakongMerchantName,
      billNumber: 'STATIC-$currency',
      status: 'PENDING',
    );

    final map = payment.toMap(includeId: false);
    final res = await _database.payments.insertOne(map);
    final insertedId = res.id is ObjectId
        ? (res.id as ObjectId).toHexString()
        : res.id?.toString();

    return PaymentRecord.fromMap({
      ...map,
      '_id': insertedId != null ? ObjectId.fromHexString(insertedId) : null,
    });
  }
}
