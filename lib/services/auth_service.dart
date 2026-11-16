import 'dart:convert';
import 'package:api/database/mongo_db.dart';
import 'package:api/models/user.dart';
import 'package:api/services/jwt_service.dart';
import 'package:crypto/crypto.dart';
import 'package:mongo_dart/mongo_dart.dart';

class AuthService {
  AuthService({
    required MongoDatabase database,
    JwtService? jwtService,
  }) : _database = database,
       _jwtService = jwtService ?? JwtService();

  final MongoDatabase _database;
  final JwtService _jwtService;

  JwtService get jwtService => _jwtService;

  static String hashPassword(String password) {
    final bytes = utf8.encode('salt_meaw_ecommerce_$password');
    return sha256.convert(bytes).toString();
  }

  Future<User> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? address,
    String? avatarUrl,
  }) async {
    await _database.connect();

    final normalizedEmail = email.toLowerCase().trim();
    final existing = await _database.users.findOne(
      where.eq('email', normalizedEmail),
    );

    if (existing != null) {
      // If user already exists, update profile/password and return existing user
      final existingUser = User.fromMap(existing);
      final updates = <String, dynamic>{
        'passwordHash': hashPassword(password),
        if (name.trim().isNotEmpty) 'name': name.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (address != null && address.trim().isNotEmpty)
          'address': address.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      try {
        await _database.users.updateOne(
          where.eq('email', normalizedEmail),
          modify.setAll(updates),
        );
      } catch (_) {}
      final refreshed = await getUserByEmail(normalizedEmail);
      return refreshed ?? existingUser;
    }

    final user = User(
      name: name.trim(),
      email: normalizedEmail,
      passwordHash: hashPassword(password),
      phone: phone?.trim() ?? '',
      address: address?.trim() ?? 'Street 2004, Phnom Penh, Cambodia',
      avatarUrl:
          avatarUrl ??
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
    );

    final map = user.toMap(includeId: false);
    final res = await _database.users.insertOne(map);
    final insertedId =
        res.id is ObjectId ? (res.id as ObjectId).oid : res.id?.toString();

    return User.fromMap({
      ...map,
      '_id': insertedId != null ? ObjectId.fromHexString(insertedId) : null,
    });
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    int expiresInSeconds = 2592000,
  }) async {
    await _database.connect();

    final normalizedEmail = email.toLowerCase().trim();
    final userDoc = await _database.users.findOne(
      where.eq('email', normalizedEmail),
    );

    if (userDoc == null) {
      throw Exception('Invalid email or password');
    }

    final user = User.fromMap(userDoc);
    final inputHash = hashPassword(password);

    if (user.passwordHash != inputHash) {
      throw Exception('Invalid email or password');
    }

    final userId = user.id ?? normalizedEmail;
    final jwtToken = _jwtService.generateToken(
      userId: userId,
      email: user.email,
      name: user.name,
      expiresInSeconds: expiresInSeconds,
    );

    final sessionDoc = {
      'token': jwtToken,
      'userId': userId,
      'email': user.email,
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt': DateTime.now()
          .add(Duration(seconds: expiresInSeconds))
          .toIso8601String(),
    };

    await _database.sessions.insertOne(sessionDoc);

    return {
      'token_type': 'Bearer',
      'token': jwtToken,
      'expires_in': expiresInSeconds,
      'user': user.toJson(),
    };
  }

  Future<bool> logout(String token) async {
    await _database.connect();
    final res = await _database.sessions.deleteMany(
      where.eq('token', token.trim()),
    );
    return (res.nRemoved) > 0;
  }

  Future<User?> getUserFromToken(String token) async {
    await _database.connect();

    Map<String, dynamic> claims;
    try {
      claims = _jwtService.verifyToken(token.trim());
    } catch (_) {
      return null;
    }

    final userId = claims['sub'] as String? ?? claims['userId'] as String?;
    if (userId == null) return null;

    final session = await _database.sessions.findOne(
      where.eq('token', token.trim()),
    );
    if (session != null && session['isActive'] == false) {
      return null;
    }

    return getUserById(userId);
  }

  Future<User?> getUserById(String id) async {
    await _database.connect();
    try {
      final doc = await _database.users.findOne(
        where.id(ObjectId.fromHexString(id)),
      );
      if (doc != null) return User.fromMap(doc);
    } catch (_) {}

    final doc2 = await _database.users.findOne(where.eq('_id', id));
    if (doc2 != null) return User.fromMap(doc2);
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    await _database.connect();
    final doc = await _database.users.findOne(
      where.eq('email', email.toLowerCase().trim()),
    );
    return doc != null ? User.fromMap(doc) : null;
  }

  Future<User> updateProfile(
    String userId, {
    String? name,
    String? phone,
    String? address,
    String? avatarUrl,
  }) async {
    await _database.connect();

    final updates = <String, dynamic>{
      if (name != null) 'name': name.trim(),
      if (phone != null) 'phone': phone.trim(),
      if (address != null) 'address': address.trim(),
      if (avatarUrl != null) 'avatarUrl': avatarUrl.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      await _database.users.updateOne(
        where.id(ObjectId.fromHexString(userId)),
        modify.setAll(updates),
      );
    } catch (_) {
      await _database.users.updateOne(
        where.eq('_id', userId),
        modify.setAll(updates),
      );
    }

    final updated = await getUserById(userId);
    if (updated == null) {
      throw Exception('User not found after update');
    }
    return updated;
  }
}

extension on ModifierBuilder {
  ModifierBuilder setAll(Map<String, dynamic> values) {
    for (final entry in values.entries) {
      set(entry.key, entry.value);
    }
    return this;
  }
}
