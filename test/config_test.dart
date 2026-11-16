import 'package:api/config/app_config.dart';
import 'package:api/services/bakong_service.dart';
import 'package:test/test.dart';

void main() {
  group('AppConfig', () {
    test('loads default values and environment variables', () {
      final config = AppConfig.load();
      expect(config.appName, equals('MEAW'));
      expect(config.appEnv, equals('development'));
      expect(config.appPort, equals(8080));
      expect(config.mongodbDatabase, equals('api'));
      expect(config.bakongAccountId, equals('lyhav_voeurn@bkrt'));
      expect(config.bakongMerchantName, equals('LYHAV VOEURN'));
      expect(config.khqrCurrency, isIn(['USD', 'KHR']));
    });
  });

  group('BakongService', () {
    test('generates individual KHQR code', () {
      final config = AppConfig.load();
      final service = BakongService(config: config);

      final result = service.generateIndividualKhqr(
        amount: 1000,
        currency: 'KHR',
      );

      expect(result.qr, isNotEmpty);
      expect(result.md5, isNotEmpty);
      expect(result.amount, equals(1000.0));
      expect(result.currency, equals('KHR'));
      expect(result.bakongAccountId, equals('lyhav_voeurn@bkrt'));
    });
  });
}
