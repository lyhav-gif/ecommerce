import 'dart:io';
import 'package:dotenv/dotenv.dart';

class AppConfig {
  AppConfig._({
    required this.appName,
    required this.appEnv,
    required this.appPort,
    required this.appUrl,
    required this.mongodbUri,
    required this.mongodbDatabase,
    required this.bakongEnv,
    required this.bakongApiUrl,
    required this.bakongToken,
    required this.bakongAccountId,
    required this.bakongMerchantName,
    required this.bakongPhoneNumber,
    required this.khqrCurrency,
    required this.khqrCountry,
    required this.khqrCity,
    required this.jwtSecret,
    required this.jwtExpiresInSeconds,
  });

  static AppConfig? _instance;

  final String appName;
  final String appEnv;
  final int appPort;
  final String appUrl;

  final String mongodbUri;
  final String mongodbDatabase;

  final String bakongEnv;
  final String bakongApiUrl;
  final String bakongToken;
  final String bakongAccountId;
  final String bakongMerchantName;
  final String bakongPhoneNumber;

  final String khqrCurrency;
  final String khqrCountry;
  final String khqrCity;

  final String jwtSecret;
  final int jwtExpiresInSeconds;

  bool get isDevelopment => appEnv.toLowerCase() == 'development';
  bool get isProduction => appEnv.toLowerCase() == 'production';
  bool get isSandbox => bakongEnv.toLowerCase() == 'sandbox';

  String get fullMongoUri {
    if (mongodbUri.endsWith('/')) {
      return '$mongodbUri$mongodbDatabase';
    }
    // If the URI doesn't include the db name
    final parsed = Uri.tryParse(mongodbUri);
    if (parsed != null && (parsed.path.isEmpty || parsed.path == '/')) {
      return '$mongodbUri/$mongodbDatabase';
    }
    return mongodbUri;
  }

  static AppConfig get instance {
    return _instance ?? load();
  }

  static AppConfig load({String envFilePath = '.env'}) {
    final dotEnv = DotEnv(includePlatformEnvironment: true);

    final envFile = File(envFilePath);
    if (envFile.existsSync()) {
      dotEnv.load([envFilePath]);
    } else {
      dotEnv.load();
    }

    String getVar(String key, {String fallback = ''}) {
      return dotEnv[key] ?? Platform.environment[key] ?? fallback;
    }

    final port = int.tryParse(getVar('APP_PORT', fallback: '8080')) ?? 8080;

    _instance = AppConfig._(
      appName: getVar('APP_NAME', fallback: 'MEAW'),
      appEnv: getVar('APP_ENV', fallback: 'development'),
      appPort: port,
      appUrl: getVar('APP_URL', fallback: 'http://localhost:$port'),
      mongodbUri: getVar('MONGODB_URI', fallback: 'mongodb://127.0.0.1:27017'),
      mongodbDatabase: getVar('MONGODB_DATABASE', fallback: 'api'),
      bakongEnv: getVar('BAKONG_ENV', fallback: 'sandbox'),
      bakongApiUrl: getVar(
        'BAKONG_API_URL',
        fallback: 'https://api-bakong.nbc.gov.kh',
      ),
      bakongToken: getVar('BAKONG_TOKEN'),
      bakongAccountId: getVar(
        'BAKONG_ACCOUNT_ID',
        fallback: 'lyhav_voeurn@bkrt',
      ),
      bakongMerchantName: getVar(
        'BAKONG_MERCHANT_NAME',
        fallback: 'LYHAV VOEURN',
      ),
      bakongPhoneNumber: getVar('BAKONG_PHONE_NUMBER', fallback: '067687806'),
      khqrCurrency: getVar('KHQR_CURRENCY', fallback: 'KHR'),
      khqrCountry: getVar('KHQR_COUNTRY', fallback: 'KH'),
      khqrCity: getVar('KHQR_CITY', fallback: 'Phnom Penh'),
      jwtSecret: getVar(
        'JWT_SECRET',
        fallback: 'meaw_ecommerce_jwt_secret_key_2026_super_secure',
      ),
      jwtExpiresInSeconds:
          int.tryParse(getVar('JWT_EXPIRES_IN', fallback: '2592000')) ??
          2592000,
    );

    return _instance!;
  }

  Map<String, dynamic> toPublicMap() {
    return {
      'appName': appName,
      'appEnv': appEnv,
      'appPort': appPort,
      'appUrl': appUrl,
      'mongodbDatabase': mongodbDatabase,
      'bakongEnv': bakongEnv,
      'bakongAccountId': bakongAccountId,
      'bakongMerchantName': bakongMerchantName,
      'khqrCurrency': khqrCurrency,
      'khqrCountry': khqrCountry,
      'khqrCity': khqrCity,
    };
  }
}
