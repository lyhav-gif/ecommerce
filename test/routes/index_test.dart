import 'dart:io';

import 'package:api/config/app_config.dart';
import 'package:api/database/mongo_db.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}
class _MockMongoDatabase extends Mock implements MongoDatabase {}

void main() {
  group('GET /', () {
    test('responds with status 200 and application details', () async {
      final context = _MockRequestContext();
      final mongoDb = _MockMongoDatabase();
      final config = AppConfig.load();

      when(() => context.read<AppConfig>()).thenReturn(config);
      when(() => context.read<MongoDatabase>()).thenReturn(mongoDb);
      when(() => mongoDb.checkHealth()).thenAnswer(
        (_) async => {'status': 'mocked', 'database': 'api'},
      );

      final response = await route.onRequest(context);
      expect(response.statusCode, equals(HttpStatus.ok));
      final body = await response.body();
      expect(body, contains('MEAW'));
      expect(body, contains('lyhav_voeurn@bkrt'));
    });
  });
}
