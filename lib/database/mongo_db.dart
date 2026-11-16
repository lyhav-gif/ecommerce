import 'dart:async';
import 'package:api/config/app_config.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoDatabase {
  MongoDatabase({AppConfig? config}) : _config = config ?? AppConfig.instance;

  final AppConfig _config;
  Db? _db;
  bool _isConnecting = false;

  bool get isConnected => _db != null && _db!.isConnected;
  Db get db {
    if (_db == null || !_db!.isConnected) {
      throw StateError('Database is not connected. Call connect() first.');
    }
    return _db!;
  }

  DbCollection get products => db.collection('products');
  DbCollection get payments => db.collection('payments');
  DbCollection get transactions => db.collection('transactions');
  DbCollection get users => db.collection('users');
  DbCollection get sessions => db.collection('sessions');
  DbCollection get carts => db.collection('carts');
  DbCollection get orders => db.collection('orders');

  Future<void> connect() async {
    if (isConnected) return;
    if (_isConnecting) {
      while (_isConnecting) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isConnecting = true;
    try {
      final uri = _config.fullMongoUri;
      _db = await Db.create(uri);
      await _db!.open().timeout(const Duration(seconds: 4));
      print('[MongoDB] Connected successfully to ${_config.mongodbDatabase}');
    } catch (e) {
      print('[MongoDB] Connection failed: $e');
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      _db = null;
      print('[MongoDB] Connection closed.');
    }
  }

  Future<Map<String, dynamic>> checkHealth() async {
    try {
      if (!isConnected) {
        await connect();
      }
      final ping = await db.serverStatus();
      return {
        'status': 'connected',
        'database': _config.mongodbDatabase,
        'uptime': ping['uptime'],
        'version': ping['version'],
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'database': _config.mongodbDatabase,
      };
    }
  }
}

