import 'dart:convert';
import 'dart:io';
import 'package:api/config/app_config.dart';
import 'package:api/services/khqr_helper.dart';

class BakongQrResult {
  BakongQrResult({
    required this.qr,
    required this.md5,
    required this.amount,
    required this.currency,
    required this.bakongAccountId,
    required this.merchantName,
  });

  final String qr;
  final String md5;
  final double amount;
  final String currency;
  final String bakongAccountId;
  final String merchantName;

  Map<String, dynamic> toJson() => {
        'qr': qr,
        'md5': md5,
        'amount': amount,
        'currency': currency,
        'bakongAccountId': bakongAccountId,
        'merchantName': merchantName,
      };
}

class BakongTransactionResult {
  BakongTransactionResult({
    required this.isSuccess,
    required this.responseCode,
    required this.responseMessage,
    this.data,
    this.rawResponse,
  });

  final bool isSuccess;
  final int responseCode;
  final String responseMessage;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? rawResponse;

  Map<String, dynamic> toJson() => {
        'isSuccess': isSuccess,
        'responseCode': responseCode,
        'responseMessage': responseMessage,
        if (data != null) 'data': data,
      };
}

class BakongService {
  BakongService({AppConfig? config}) : _config = config ?? AppConfig.instance;

  final AppConfig _config;
  AppConfig get config => _config;

  BakongQrResult generateIndividualKhqr({
    required double amount,
    String? currency,
    String? accountInformation,
    String? acquiringBank,
    String? billNumber,
    String? mobileNumber,
    String? storeLabel,
    String? terminalLabel,
    bool forceVerifiedStatic = true,
  }) {
    final curString = (currency != null && currency.isNotEmpty)
        ? currency.toUpperCase()
        : _config.khqrCurrency.toUpperCase();

    // Use verified static KHQR as requested: "use this for buy all product"
    if (forceVerifiedStatic) {
      return BakongQrResult(
        qr: KhqrHelper.verifiedStaticKhrQr,
        md5: KhqrHelper.verifiedStaticKhrMd5,
        amount: amount,
        currency: curString,
        bakongAccountId: _config.bakongAccountId,
        merchantName: _config.bakongMerchantName,
      );
    }

    final khqrCur = curString == 'USD' ? KhqrCurrency.usd : KhqrCurrency.khr;

    final result = KhqrHelper.generateIndividual(
      bakongAccountId: _config.bakongAccountId,
      merchantName: _config.bakongMerchantName,
      currency: khqrCur,
      amount: amount,
      accountInformation: accountInformation ?? _config.bakongPhoneNumber,
      acquiringBank: acquiringBank ?? 'Bakong',
      merchantCity: _config.khqrCity,
      countryCode: _config.khqrCountry,
      billNumber: billNumber,
      mobileNumber: mobileNumber ?? _config.bakongPhoneNumber,
      storeLabel: storeLabel,
      terminalLabel: terminalLabel,
    );

    return BakongQrResult(
      qr: result.qr,
      md5: result.md5,
      amount: amount,
      currency: curString,
      bakongAccountId: _config.bakongAccountId,
      merchantName: _config.bakongMerchantName,
    );
  }

  Future<BakongTransactionResult> checkTransactionByMd5(String md5) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      final endpoint = '${_config.bakongApiUrl}/v1/check_transaction_by_md5';
      final uri = Uri.parse(endpoint);
      final request = await client.postUrl(uri);

      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      if (_config.bakongToken.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer ${_config.bakongToken}',
        );
      }

      final payload = jsonEncode({'md5': md5.trim()});
      request.add(utf8.encode(payload));

      final response = await request.close();
      final responseBody = await utf8.decodeStream(response);

      if (responseBody.isEmpty) {
        return BakongTransactionResult(
          isSuccess: false,
          responseCode: response.statusCode,
          responseMessage: 'Empty response from Bakong API',
        );
      }

      final json = jsonDecode(responseBody) as Map<String, dynamic>;

      int code = -1;
      String message = 'Unknown';
      Map<String, dynamic>? data;

      if (json['status'] is Map) {
        final statusMap = json['status'] as Map<String, dynamic>;
        code = int.tryParse(statusMap['code']?.toString() ?? '-1') ?? -1;
        message = statusMap['message']?.toString() ?? 'Unknown';
      } else if (json.containsKey('responseCode')) {
        code = int.tryParse(json['responseCode']?.toString() ?? '-1') ?? -1;
        message = json['responseMessage']?.toString() ?? '';
      }

      if (json['data'] is Map) {
        data = json['data'] as Map<String, dynamic>;
      }

      final isSuccess = code == 0;

      return BakongTransactionResult(
        isSuccess: isSuccess,
        responseCode: code,
        responseMessage: message,
        data: data,
        rawResponse: json,
      );
    } catch (e) {
      return BakongTransactionResult(
        isSuccess: false,
        responseCode: -1,
        responseMessage: 'Error checking transaction: $e',
      );
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> checkAccountById(String accountId) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      final endpoint = '${_config.bakongApiUrl}/v1/check_account_by_id';
      final uri = Uri.parse(endpoint);
      final request = await client.postUrl(uri);

      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      if (_config.bakongToken.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer ${_config.bakongToken}',
        );
      }

      final payload = jsonEncode({'accountId': accountId.trim()});
      request.add(utf8.encode(payload));

      final response = await request.close();
      final responseBody = await utf8.decodeStream(response);
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      return {
        'status': {'code': -1, 'message': e.toString()}
      };
    } finally {
      client.close();
    }
  }
}
