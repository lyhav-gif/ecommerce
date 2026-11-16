import 'dart:convert';
import 'package:crypto/crypto.dart';

enum KhqrCurrency {
  khr,
  usd,
}

class KhqrResult {
  KhqrResult({
    required this.qr,
    required this.md5,
  });

  final String qr;
  final String md5;
}

class KhqrHelper {
  static const String verifiedStaticKhrQr =
      '00020101021129210017lyhav_voeurn@bkrt5204599953031165802KH5912LYHAV VOEURN6010Phnom Penh62150211855676878066304C9CA';
  static const String verifiedStaticKhrMd5 = '1039423af4af31a78945b40a87638134';
  static const String verifiedQrImageUrl =
      'https://api.qrserver.com/v1/create-qr-code/?size=500x500&margin=2&ecc=M&data=00020101021129210017lyhav_voeurn%40bkrt5204599953031165802KH5912LYHAV%20VOEURN6010Phnom%20Penh62150211855676878066304C9CA';
  static const String verifiedQrImageUrlFallback =
      'https://quickchart.io/qr?size=500&margin=2&ecLevel=M&text=00020101021129210017lyhav_voeurn%40bkrt5204599953031165802KH5912LYHAV%20VOEURN6010Phnom%20Penh62150211855676878066304C9CA';

  static String formatTlv(String tag, String value) {
    final len = utf8.encode(value).length.toString().padLeft(2, '0');
    return '$tag$len$value';
  }

  static String calculateCrc16(String payload) {
    var crc = 0xFFFF;
    const polynomial = 0x1021;
    final bytes = utf8.encode(payload);

    for (final b in bytes) {
      crc ^= b << 8;
      for (var i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ polynomial) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }

    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  static KhqrResult generateIndividual({
    required String bakongAccountId,
    required String merchantName,
    required KhqrCurrency currency,
    double amount = 0,
    String? accountInformation,
    String? acquiringBank,
    String? merchantCity,
    String? countryCode,
    String? billNumber,
    String? mobileNumber,
    String? storeLabel,
    String? terminalLabel,
  }) {
    final buffer = StringBuffer();

    // 00: Payload Format Indicator (01)
    buffer.write(formatTlv('00', '01'));

    // 01: Point of Initiation Method (11: Static, 12: Dynamic)
    final isDynamic = amount > 0;
    buffer.write(formatTlv('01', isDynamic ? '12' : '11'));

    // 29: Merchant Account Information (Individual)
    final tag29Buffer = StringBuffer();
    tag29Buffer.write(formatTlv('00', bakongAccountId));
    if (!bakongAccountId.contains('@')) {
      if (accountInformation != null && accountInformation.isNotEmpty) {
        tag29Buffer.write(formatTlv('01', accountInformation));
      }
      final bank = (acquiringBank != null && acquiringBank.isNotEmpty)
          ? acquiringBank
          : 'Bakong';
      tag29Buffer.write(formatTlv('02', bank));
    }
    buffer.write(formatTlv('29', tag29Buffer.toString()));

    // 52: Merchant Category Code (5999: Standard for Individual)
    buffer.write(formatTlv('52', '5999'));

    // 53: Transaction Currency (116: KHR, 840: USD)
    final currencyCode = currency == KhqrCurrency.usd ? '840' : '116';
    buffer.write(formatTlv('53', currencyCode));

    // 54: Transaction Amount
    if (isDynamic) {
      String amountStr;
      if (currency == KhqrCurrency.khr) {
        amountStr = amount % 1 == 0
            ? amount.toInt().toString()
            : amount.toString();
      } else {
        amountStr = amount.toStringAsFixed(2);
      }
      buffer.write(formatTlv('54', amountStr));
    }

    // 58: Country Code (KH)
    final country = (countryCode != null && countryCode.isNotEmpty)
        ? countryCode
        : 'KH';
    buffer.write(formatTlv('58', country));

    // 59: Merchant Name
    buffer.write(formatTlv('59', merchantName));

    // 60: Merchant City
    final city = (merchantCity != null && merchantCity.isNotEmpty)
        ? merchantCity
        : 'Phnom Penh';
    buffer.write(formatTlv('60', city));

    // 62: Additional Data Field Template
    final tag62Buffer = StringBuffer();
    if (billNumber != null && billNumber.isNotEmpty) {
      final safeBill = billNumber.length > 25
          ? billNumber.substring(0, 25)
          : billNumber;
      tag62Buffer.write(formatTlv('01', safeBill));
    }
    if (mobileNumber != null && mobileNumber.isNotEmpty) {
      var cleanMobile = mobileNumber.replaceAll(RegExp(r'\D'), '');
      if (cleanMobile.startsWith('0')) {
        cleanMobile = '855${cleanMobile.substring(1)}';
      } else if (!cleanMobile.startsWith('855')) {
        cleanMobile = '855$cleanMobile';
      }
      tag62Buffer.write(formatTlv('02', cleanMobile));
    }
    if (storeLabel != null && storeLabel.isNotEmpty) {
      tag62Buffer.write(formatTlv('03', storeLabel));
    }
    if (terminalLabel != null && terminalLabel.isNotEmpty) {
      tag62Buffer.write(formatTlv('07', terminalLabel));
    }

    if (tag62Buffer.isNotEmpty) {
      buffer.write(formatTlv('62', tag62Buffer.toString()));
    }

    // 63: CRC placeholder
    final payloadWithoutCrc = '${buffer}6304';
    final crc = calculateCrc16(payloadWithoutCrc);
    final fullQr = '$payloadWithoutCrc$crc';

    // MD5 calculation
    final md5Hash = md5.convert(utf8.encode(fullQr)).toString();

    return KhqrResult(qr: fullQr, md5: md5Hash);
  }
}
