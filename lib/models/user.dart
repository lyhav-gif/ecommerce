import 'package:mongo_dart/mongo_dart.dart';

class User {
  User({
    required this.name,
    required this.email,
    required this.passwordHash,
    this.id,
    this.phone = '',
    this.avatarUrl =
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
    this.address = 'Street 2004, Phnom Penh, Cambodia',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory User.fromMap(Map<String, dynamic> map) {
    String? idStr;
    if (map['_id'] != null) {
      if (map['_id'] is ObjectId) {
        idStr = (map['_id'] as ObjectId).oid;
      } else {
        idStr = map['_id'].toString();
      }
    }

    return User(
      id: idStr,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      passwordHash: map['passwordHash'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      avatarUrl:
          map['avatarUrl'] as String? ??
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      address: map['address'] as String? ?? 'Street 2004, Phnom Penh, Cambodia',
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
                DateTime.now(),
      updatedAt: map['updatedAt'] is DateTime
          ? map['updatedAt'] as DateTime
          : DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
                DateTime.now(),
    );
  }

  final String? id;
  final String name;
  final String email;
  final String passwordHash;
  final String phone;
  final String avatarUrl;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap({bool includeId = true}) {
    final map = <String, dynamic>{
      'name': name,
      'email': email.toLowerCase().trim(),
      'passwordHash': passwordHash,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };

    if (includeId && id != null) {
      map['_id'] = ObjectId.fromHexString(id!);
    }
    return map;
  }

  Map<String, dynamic> toJson({bool includePassword = false}) {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'address': address,
      if (includePassword) 'passwordHash': passwordHash,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
