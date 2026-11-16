import 'dart:convert';
import 'package:crypto/crypto.dart';

class JwtException implements Exception {
  JwtException(this.message);
  final String message;

  @override
  String toString() => 'JwtException: $message';
}

class JwtService {
  JwtService({String? secret})
    : _secret = secret ?? 'meaw_ecommerce_jwt_secret_key_2026_super_secure';

  final String _secret;

  static String _base64UrlEncode(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static List<int> _base64UrlDecode(String str) {
    var normalized = str.replaceAll('-', '+').replaceAll('_', '/');
    final remainder = normalized.length % 4;
    if (remainder > 0) {
      normalized =
          normalized.padRight(normalized.length + (4 - remainder), '=');
    }
    return base64.decode(normalized);
  }

  String generateToken({
    required String userId,
    required String email,
    String? name,
    int expiresInSeconds = 2592000, // 30 days default
    Map<String, dynamic>? extraClaims,
  }) {
    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };

    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expSeconds = nowSeconds + expiresInSeconds;

    final payload = <String, dynamic>{
      'sub': userId,
      'userId': userId,
      'email': email.toLowerCase().trim(),
      if (name != null) 'name': name,
      'iat': nowSeconds,
      'exp': expSeconds,
      if (extraClaims != null) ...extraClaims,
    };

    final headerEncoded = _base64UrlEncode(utf8.encode(jsonEncode(header)));
    final payloadEncoded = _base64UrlEncode(utf8.encode(jsonEncode(payload)));

    final message = '$headerEncoded.$payloadEncoded';
    final hmac = Hmac(sha256, utf8.encode(_secret));
    final digest = hmac.convert(utf8.encode(message));
    final signatureEncoded = _base64UrlEncode(digest.bytes);

    return '$message.$signatureEncoded';
  }

  Map<String, dynamic> verifyToken(String token) {
    final parts = token.trim().split('.');
    if (parts.length != 3) {
      throw JwtException('Invalid JWT format: token must contain 3 parts');
    }

    final message = '${parts[0]}.${parts[1]}';
    final hmac = Hmac(sha256, utf8.encode(_secret));
    final digest = hmac.convert(utf8.encode(message));
    final expectedSignature = _base64UrlEncode(digest.bytes);

    if (parts[2] != expectedSignature) {
      throw JwtException('Invalid JWT signature');
    }

    try {
      final payloadBytes = _base64UrlDecode(parts[1]);
      final payloadJson =
          jsonDecode(utf8.decode(payloadBytes)) as Map<String, dynamic>;

      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final exp = payloadJson['exp'] as num?;
      if (exp != null && nowSeconds > exp.toInt()) {
        throw JwtException('JWT token has expired');
      }

      return payloadJson;
    } on JwtException {
      rethrow;
    } catch (e) {
      throw JwtException('Failed to decode JWT payload: $e');
    }
  }

  Map<String, dynamic>? decodeTokenUnverified(String token) {
    final parts = token.trim().split('.');
    if (parts.length != 3) return null;
    try {
      final payloadBytes = _base64UrlDecode(parts[1]);
      return jsonDecode(utf8.decode(payloadBytes)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
