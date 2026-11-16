import 'package:api/database/mongo_db.dart';
import 'package:api/models/product.dart';
import 'package:api/services/bakong_service.dart';
import 'package:mongo_dart/mongo_dart.dart';

class ProductService {
  ProductService({
    required MongoDatabase database,
    BakongService? bakongService,
  })  : _database = database,
        _bakongService = bakongService ?? BakongService();

  final MongoDatabase _database;
  final BakongService _bakongService;

  Product generateProductKhqr(Product product) {
    final qrRes = _bakongService.generateIndividualKhqr(
      amount: product.price,
      currency: product.currency,
      billNumber: _makeBillNumber(product.name),
    );

    return product.copyWith(
      khqr: qrRes.qr,
      md5: qrRes.md5,
      qrImageUrl: Product.buildQrImageUrl(qrRes.qr),
      qrImageUrlFallback: Product.buildQrImageFallbackUrl(qrRes.qr),
      bakongAccountId: qrRes.bakongAccountId,
      merchantName: qrRes.merchantName,
    );
  }

  String _makeBillNumber(String name) {
    final clean = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final short = clean.length > 8 ? clean.substring(0, 8) : clean;
    return 'INV-$short';
  }

  Future<List<Product>> getAllProducts(
      {String? category, String? search}) async {
    await _database.connect();

    var selector = where;
    if (category != null &&
        category.trim().isNotEmpty &&
        category.toLowerCase() != 'all') {
      selector = selector.eq('category', category.trim());
    }
    if (search != null && search.trim().isNotEmpty) {
      selector = selector.match('name', search.trim(), caseInsensitive: true);
    }

    final list = await _database.products.find(selector).toList();
    final results = <Product>[];

    for (final doc in list) {
      var prod = Product.fromMap(doc);
      if (prod.khqr == null || prod.khqr!.isEmpty) {
        prod = generateProductKhqr(prod);
        if (prod.id != null) {
          try {
            await _database.products.updateOne(
              where.id(ObjectId.fromHexString(prod.id!)),
              modify
                  .set('khqr', prod.khqr!)
                  .set('md5', prod.md5!)
                  .set('qrImageUrl', prod.qrImageUrl!)
                  .set('qrImageUrlFallback', prod.qrImageUrlFallback!)
                  .set('bakongAccountId',
                      prod.bakongAccountId ?? _bakongService.config.bakongAccountId)
                  .set('merchantName',
                      prod.merchantName ?? _bakongService.config.bakongMerchantName),
            );
          } catch (_) {}
        }
      }
      results.add(prod);
    }

    return results;
  }

  Future<Product?> getProductById(String id) async {
    await _database.connect();
    Product? prod;

    try {
      final doc = await _database.products
          .findOne(where.id(ObjectId.fromHexString(id)));
      if (doc != null) prod = Product.fromMap(doc);
    } catch (_) {}

    if (prod == null) {
      final doc2 = await _database.products.findOne(where.eq('_id', id));
      if (doc2 != null) prod = Product.fromMap(doc2);
    }

    if (prod == null) {
      final doc3 = await _database.products.findOne(where.eq('name', id));
      if (doc3 != null) prod = Product.fromMap(doc3);
    }

    if (prod != null) {
      if (prod.khqr == null || prod.khqr!.isEmpty) {
        prod = generateProductKhqr(prod);
        if (prod.id != null) {
          try {
            await _database.products.updateOne(
              where.id(ObjectId.fromHexString(prod.id!)),
              modify
                  .set('khqr', prod.khqr!)
                  .set('md5', prod.md5!)
                  .set('qrImageUrl', prod.qrImageUrl!)
                  .set('qrImageUrlFallback', prod.qrImageUrlFallback!)
                  .set('bakongAccountId',
                      prod.bakongAccountId ?? _bakongService.config.bakongAccountId)
                  .set('merchantName',
                      prod.merchantName ?? _bakongService.config.bakongMerchantName),
            );
          } catch (_) {}
        }
      }
      return prod;
    }

    return null;
  }

  Future<Product> createProduct(Product product) async {
    await _database.connect();

    var productToSave = product;
    if (productToSave.khqr == null || productToSave.khqr!.isEmpty) {
      productToSave = generateProductKhqr(productToSave);
    }

    final map = productToSave.toMap(includeId: false);
    final res = await _database.products.insertOne(map);
    final insertedId = res.id is ObjectId
        ? (res.id as ObjectId).toHexString()
        : res.id?.toString();

    // Register pre-generated payment record in MongoDB payments collection
    try {
      if (productToSave.md5 != null && productToSave.khqr != null) {
        await _database.payments.updateOne(
          where.eq('md5', productToSave.md5!),
          modify
              .set('qr', productToSave.khqr!)
              .set('md5', productToSave.md5!)
              .set('qrImageUrl', productToSave.qrImageUrl ?? '')
              .set('qrImageUrlFallback', productToSave.qrImageUrlFallback ?? '')
              .set('amount', productToSave.price)
              .set('currency', productToSave.currency)
              .set('bakongAccountId',
                  productToSave.bakongAccountId ?? _bakongService.config.bakongAccountId)
              .set('merchantName',
                  productToSave.merchantName ?? _bakongService.config.bakongMerchantName)
              .set('productId', insertedId)
              .set('billNumber', _makeBillNumber(productToSave.name))
              .set('status', 'PENDING')
              .set('createdAt', DateTime.now().toIso8601String())
              .set('updatedAt', DateTime.now().toIso8601String()),
          upsert: true,
        );
      }
    } catch (_) {}

    return Product.fromMap({
      ...map,
      '_id': insertedId != null ? ObjectId.fromHexString(insertedId) : null,
    });
  }

  Future<Product?> updateProduct(
      String id, Map<String, dynamic> updates) async {
    await _database.connect();
    try {
      final objectId = ObjectId.fromHexString(id);
      final updateData = Map<String, dynamic>.from(updates);
      updateData.remove('_id');
      updateData.remove('id');
      updateData['updatedAt'] = DateTime.now().toIso8601String();

      var modifier = modify;
      updateData.forEach((key, value) {
        modifier = modifier.set(key, value);
      });

      await _database.products.updateOne(where.id(objectId), modifier);
      return getProductById(id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteProduct(String id) async {
    await _database.connect();
    try {
      final objectId = ObjectId.fromHexString(id);
      final res = await _database.products.deleteOne(where.id(objectId));
      return (res.nRemoved) > 0;
    } catch (_) {
      return false;
    }
  }

  Future<List<Product>> seedFigmaProducts() async {
    await _database.connect();

    final figmaItems = [
      Product(
        name: 'Aura Cream 1+1',
        description:
            '1+1 FREE on Blessed Moon Aura Cream. Deep hydration and glow effect.',
        price: 40.0,
        currency: 'USD',
        imageUrl:
            'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=500',
        category: 'Beauty',
        brand: 'GOODY BLESSED MOON',
        rating: 4.9,
        reviewCount: 128,
        tag: '1+1 FREE',
        isFlash: false,
      ),
      Product(
        name: 'Linin Body Cream',
        description:
            'Glow should be weightless. Instant skin nourishing body cream.',
        price: 24.0,
        currency: 'USD',
        imageUrl:
            'https://images.unsplash.com/photo-1608248597359-5283b05fca1c?w=500',
        category: 'Beauty',
        brand: 'LININ',
        rating: 4.9,
        reviewCount: 128,
        tag: 'FLASH',
        isFlash: true,
      ),
      Product(
        name: 'WEYOUNG Facial Essence',
        description: 'Natural clarifying toner and essence for radiant skin.',
        price: 30.0,
        currency: 'USD',
        imageUrl:
            'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=500',
        category: 'Beauty',
        brand: 'WEYOUNG',
        rating: 4.9,
        reviewCount: 128,
        tag: 'FLASH',
        isFlash: true,
      ),
      Product(
        name: 'Classic Trench Coat',
        description: 'Premium tailored cotton trench coat with sleek design.',
        price: 85.0,
        currency: 'USD',
        imageUrl:
            'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=500',
        category: 'Fashion',
        brand: 'NAMAN',
        rating: 4.8,
        reviewCount: 64,
        tag: 'TRENDING',
        isFlash: false,
      ),
      Product(
        name: 'Wireless Noise-Cancelling Headphones',
        description: 'Charming melody, all-day comfort with active ANC.',
        price: 120.0,
        currency: 'USD',
        imageUrl:
            'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500',
        category: 'Electronics',
        brand: 'SONY',
        rating: 4.9,
        reviewCount: 310,
        tag: 'TOP',
        isFlash: false,
      ),
      Product(
        name: 'Minimalist Chrono Watch',
        description: 'Sapphire glass dial with genuine leather strap.',
        price: 95.0,
        currency: 'USD',
        imageUrl:
            'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500',
        category: 'Watches',
        brand: 'KRONOS',
        rating: 4.7,
        reviewCount: 88,
        tag: 'NEW',
        isFlash: false,
      ),
    ];

    for (final item in figmaItems) {
      final existing =
          await _database.products.findOne(where.eq('name', item.name));
      if (existing == null) {
        await createProduct(item);
      } else {
        // Upgrade existing product with the verified Bakong KHQR
        final withQr = generateProductKhqr(Product.fromMap(existing));
        final docId = existing['_id'] is ObjectId
            ? (existing['_id'] as ObjectId).toHexString()
            : existing['_id'].toString();

        await updateProduct(
          docId,
          {
            'khqr': withQr.khqr,
            'md5': withQr.md5,
            'qrImageUrl': withQr.qrImageUrl,
            'qrImageUrlFallback': withQr.qrImageUrlFallback,
            'bakongAccountId': withQr.bakongAccountId,
            'merchantName': withQr.merchantName,
          },
        );

        try {
          await _database.payments.updateOne(
            where.eq('md5', withQr.md5!),
            modify
                .set('qr', withQr.khqr!)
                .set('md5', withQr.md5!)
                .set('qrImageUrl', withQr.qrImageUrl ?? '')
                .set('qrImageUrlFallback', withQr.qrImageUrlFallback ?? '')
                .set('amount', withQr.price)
                .set('currency', withQr.currency)
                .set('bakongAccountId',
                    withQr.bakongAccountId ?? _bakongService.config.bakongAccountId)
                .set('merchantName',
                    withQr.merchantName ?? _bakongService.config.bakongMerchantName)
                .set('productId', docId)
                .set('billNumber', _makeBillNumber(withQr.name))
                .set('status', 'PENDING')
                .set('createdAt', DateTime.now().toIso8601String())
                .set('updatedAt', DateTime.now().toIso8601String()),
            upsert: true,
          );
        } catch (_) {}
      }
    }

    return getAllProducts();
  }
}
