import 'package:api/database/mongo_db.dart';
import 'package:api/models/cart.dart';
import 'package:api/models/product.dart';
import 'package:mongo_dart/mongo_dart.dart';

class CartService {
  CartService({required MongoDatabase database}) : _database = database;

  final MongoDatabase _database;

  Future<Cart> getCart(String userId) async {
    await _database.connect();

    final doc = await _database.carts.findOne(where.eq('userId', userId));
    if (doc != null) {
      return Cart.fromMap(doc);
    }

    final newCart = Cart(userId: userId, items: []);
    final map = newCart.toMap(includeId: false);
    final res = await _database.carts.insertOne(map);
    final insertedId = res.id is ObjectId
        ? (res.id as ObjectId).toHexString()
        : res.id?.toString();

    return Cart.fromMap({
      ...map,
      '_id': insertedId != null ? ObjectId.fromHexString(insertedId) : null,
    });
  }

  Future<Cart> addToCart(
    String userId, {
    required String productId,
    int quantity = 1,
  }) async {
    await _database.connect();

    final productDoc = await _findProduct(productId);
    if (productDoc == null) {
      throw Exception('Product not found: $productId');
    }

    final product = Product.fromMap(productDoc);
    final cart = await getCart(userId);
    final targetId = product.id ?? productId.trim();

    final items = List<CartItem>.from(cart.items);
    final existingIndex = items.indexWhere(
      (item) =>
          item.productId == targetId ||
          item.productId == productId.trim() ||
          item.name.toLowerCase() == product.name.toLowerCase(),
    );

    if (existingIndex >= 0) {
      final existing = items[existingIndex];
      final newQty = existing.quantity + quantity;
      items[existingIndex] = existing.copyWith(quantity: newQty);
    } else {
      items.add(
        CartItem(
          productId: targetId,
          name: product.name,
          category: product.category,
          price: product.price,
          currency: product.currency,
          quantity: quantity > 0 ? quantity : 1,
          imageUrl: product.imageUrl,
        ),
      );
    }

    final updatedCart = Cart(
      id: cart.id,
      userId: userId,
      items: items,
      promoCode: cart.promoCode,
      discount: cart.discount,
      shippingFee: 0.0,
      updatedAt: DateTime.now(),
    );

    await _saveCart(updatedCart);
    return updatedCart;
  }

  Future<Cart> updateItemQuantity(
    String userId, {
    required String productId,
    required int quantity,
  }) async {
    await _database.connect();
    final cart = await getCart(userId);

    final cleanId = productId.trim();
    final items = List<CartItem>.from(cart.items);
    final index = items.indexWhere(
      (item) =>
          item.productId == cleanId ||
          item.name.toLowerCase() == cleanId.toLowerCase(),
    );

    if (index >= 0) {
      if (quantity <= 0) {
        items.removeAt(index);
      } else {
        items[index] = items[index].copyWith(quantity: quantity);
      }
    }

    final updatedCart = Cart(
      id: cart.id,
      userId: userId,
      items: items,
      promoCode: cart.promoCode,
      discount: cart.discount,
      shippingFee: 0.0,
      updatedAt: DateTime.now(),
    );

    await _saveCart(updatedCart);
    return updatedCart;
  }

  Future<Cart> removeItem(String userId, String productId) async {
    return updateItemQuantity(userId, productId: productId, quantity: 0);
  }

  Future<Cart> clearCart(String userId) async {
    await _database.connect();
    final cart = await getCart(userId);

    final updatedCart = Cart(
      id: cart.id,
      userId: userId,
      items: [],
      promoCode: null,
      discount: 0.0,
      shippingFee: 0.0,
      updatedAt: DateTime.now(),
    );

    await _saveCart(updatedCart);
    return updatedCart;
  }

  Future<Cart> applyPromoCode(String userId, String promoCode) async {
    await _database.connect();
    final cart = await getCart(userId);

    double discount = 0.0;
    final normalized = promoCode.trim().toUpperCase();

    if (normalized == 'DISCOUNT10' || normalized == 'PROMO10') {
      discount = cart.subtotal >= 10 ? 10.0 : cart.subtotal * 0.10;
    } else if (normalized == 'FREESHIP' || normalized == 'WELCOME') {
      discount = 5.0;
    } else {
      throw Exception('Invalid or expired promo code: $promoCode');
    }

    final updatedCart = Cart(
      id: cart.id,
      userId: userId,
      items: cart.items,
      promoCode: normalized,
      discount: discount,
      shippingFee: 0.0,
      updatedAt: DateTime.now(),
    );

    await _saveCart(updatedCart);
    return updatedCart;
  }

  Future<void> _saveCart(Cart cart) async {
    final map = cart.toMap(includeId: false);
    await _database.carts.updateOne(
      where.eq('userId', cart.userId),
      modify
          .set('items', map['items'])
          .set('promoCode', map['promoCode'])
          .set('discount', map['discount'])
          .set('shippingFee', map['shippingFee'])
          .set('subtotal', map['subtotal'])
          .set('total', map['total'])
          .set('updatedAt', map['updatedAt']),
      upsert: true,
    );
  }

  Future<Map<String, dynamic>?> _findProduct(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;

    // 1. 24-character hexadecimal ObjectId
    if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(trimmed)) {
      try {
        final doc = await _database.products.findOne(
          where.id(ObjectId.fromHexString(trimmed)),
        );
        if (doc != null) return doc;
      } catch (_) {}
    }

    // 2. Exact _id match
    final doc2 = await _database.products.findOne(where.eq('_id', trimmed));
    if (doc2 != null) return doc2;

    // 3. Exact name match
    final doc3 = await _database.products.findOne(where.eq('name', trimmed));
    if (doc3 != null) return doc3;

    // 4. Case-insensitive exact name match
    final doc4 = await _database.products.findOne(
      where.match('name', '^$trimmed\$', caseInsensitive: true),
    );
    if (doc4 != null) return doc4;

    // 5. Partial name match (e.g. 'WEYOUNG', 'Aura Cream', 'Linin')
    final doc5 = await _database.products.findOne(
      where.match('name', trimmed, caseInsensitive: true),
    );
    return doc5;
  }
}

