import 'package:api/models/cart.dart';
import 'package:api/models/order.dart';
import 'package:api/models/payment.dart';
import 'package:api/models/product.dart';
import 'package:api/models/user.dart';
import 'package:api/services/auth_service.dart';
import 'package:api/services/jwt_service.dart';
import 'package:api/services/khqr_helper.dart';
import 'package:test/test.dart';

void main() {
  group('E-Commerce User & Auth', () {
    test('User serialization and hashing', () {
      final hash = AuthService.hashPassword('Password123!');
      expect(hash, isNotEmpty);
      expect(hash, equals(AuthService.hashPassword('Password123!')));

      final user = User(
        name: 'Roth Sethi',
        email: 'Sethi@gmail.com',
        passwordHash: hash,
        phone: '+855 12 345 678',
      );

      final json = user.toJson();
      expect(json['name'], equals('Roth Sethi'));
      expect(json['email'], equals('Sethi@gmail.com'));
      expect(json.containsKey('passwordHash'), isFalse);
    });

    test('JWT Token Generation and Verification', () {
      final jwtService = JwtService(secret: 'test_secret_12345');
      final token = jwtService.generateToken(
        userId: 'user_12345',
        email: 'sethi@gmail.com',
        name: 'Roth Sethi',
        expiresInSeconds: 3600,
      );

      expect(token, isNotEmpty);
      expect(token.split('.').length, equals(3));

      final claims = jwtService.verifyToken(token);
      expect(claims['sub'], equals('user_12345'));
      expect(claims['email'], equals('sethi@gmail.com'));
      expect(claims['name'], equals('Roth Sethi'));

      // Tampered token fails
      final tampered = '${token.substring(0, token.length - 4)}xxxx';
      expect(() => jwtService.verifyToken(tampered), throwsA(isA<JwtException>()));

      // Expired token fails
      final expiredToken = jwtService.generateToken(
        userId: 'user_12345',
        email: 'sethi@gmail.com',
        expiresInSeconds: -10, // already expired
      );
      expect(() => jwtService.verifyToken(expiredToken), throwsA(isA<JwtException>()));
    });
  });

  group('E-Commerce Products', () {
    test('Product model supports Figma fields', () {
      final product = Product(
        name: 'Aura Cream 1+1',
        category: 'Beauty',
        brand: 'GOODY BLESSED MOON',
        price: 40.0,
        currency: 'USD',
        rating: 4.9,
        reviewCount: 128,
        tag: '1+1 FREE',
      );

      final json = product.toJson();
      expect(json['name'], equals('Aura Cream 1+1'));
      expect(json['price'], equals(40.0));
      expect(json['category'], equals('Beauty'));
      expect(json['tag'], equals('1+1 FREE'));
      expect(json['rating'], equals(4.9));
    });

    test('Product model includes embedded KHQR for direct payments', () {
      final product = Product(
        name: 'Aura Cream 1+1',
        category: 'Beauty',
        price: 40.0,
        currency: 'USD',
        khqr: KhqrHelper.verifiedStaticKhrQr,
        md5: KhqrHelper.verifiedStaticKhrMd5,
        bakongAccountId: 'lyhav_voeurn@bkrt',
        merchantName: 'LYHAV VOEURN',
      );

      final json = product.toJson();
      expect(json['khqr'], equals(KhqrHelper.verifiedStaticKhrQr));
      expect(json['md5'], equals('1039423af4af31a78945b40a87638134'));
      expect(json['qrImageUrl'], equals(KhqrHelper.verifiedQrImageUrl));
      expect(json['qrImageUrlFallback'], equals(KhqrHelper.verifiedQrImageUrlFallback));
      expect(json['bakongAccountId'], equals('lyhav_voeurn@bkrt'));
      expect(json['merchantName'], equals('LYHAV VOEURN'));
    });
  });

  group('E-Commerce Cart', () {
    test('Cart calculations with items, promo, and subtotal', () {
      final item1 = CartItem(
        productId: 'prod_1',
        name: 'Aura Cream 1+1',
        category: 'Beauty',
        price: 40.0,
        quantity: 1,
      );

      expect(item1.subtotal, equals(40.0));

      final cart = Cart(
        userId: 'user_123',
        items: [item1],
        discount: 10.0,
        shippingFee: 0.0,
      );

      expect(cart.totalItemCount, equals(1));
      expect(cart.subtotal, equals(40.0));
      expect(cart.total, equals(30.0));

      final updatedItem = item1.copyWith(quantity: 2);
      expect(updatedItem.subtotal, equals(80.0));
    });
  });

  group('E-Commerce Orders', () {
    test('Order creation with Digital Payment (KHQR)', () {
      final order = Order(
        orderNumber: 'ORD-20261110-001',
        userId: 'user_123',
        customerName: 'Roth Sethi',
        customerEmail: 'Sethi@gmail.com',
        items: [
          CartItem(
            productId: 'prod_1',
            name: 'Aura Cream 1+1',
            price: 40.0,
            quantity: 1,
          )
        ],
        subtotal: 40.0,
        totalAmount: 40.0,
        currency: 'USD',
        paymentMethod: 'digital_payment',
        paymentStatus: 'PENDING',
        khqr: '00020101...',
        md5: '1039423af4af31a78945b40a87638134',
        qrImageUrl: 'https://api.qrserver.com/...',
      );

      final json = order.toJson();
      expect(json['orderNumber'], equals('ORD-20261110-001'));
      expect(json['totalAmount'], equals(40.0));
      expect(json['paymentMethod'], equals('digital_payment'));
      expect(json['md5'], equals('1039423af4af31a78945b40a87638134'));
      expect(json['paymentStatus'], equals('PENDING'));
    });
  });

  group('E-Commerce KHQR & Payments', () {
    test('KhqrHelper formats compliant Bakong KHQR for USD and KHR', () {
      final resUsd = KhqrHelper.generateIndividual(
        bakongAccountId: 'lyhav_voeurn@bkrt',
        merchantName: 'LYHAV VOEURN',
        currency: KhqrCurrency.usd,
        amount: 40.0,
        billNumber: 'ORD-123456',
        storeLabel: 'MEAW Store',
        terminalLabel: 'Online Web',
        accountInformation: '067687806',
        acquiringBank: 'Bakong',
      );

      expect(resUsd.qr, startsWith('000201'));
      expect(resUsd.qr, contains('29210017lyhav_voeurn@bkrt')); // Verified Bakong Account Tag 29
      expect(resUsd.qr, contains('5303840')); // Tag 53: USD (840)
      expect(resUsd.qr, contains('540540.00')); // Tag 54: 40.00 (2 decimals)
      expect(resUsd.qr, contains('LYHAV VOEURN'));
      expect(resUsd.qr, contains('ORD-123456'));
      expect(resUsd.md5, isNotEmpty);
      expect(resUsd.md5.length, equals(32));

      // Check CRC16 checksum at the end (Tag 63)
      final payloadWithoutCrc = resUsd.qr.substring(0, resUsd.qr.length - 4);
      final crc = KhqrHelper.calculateCrc16(payloadWithoutCrc);
      expect(resUsd.qr.endsWith(crc), isTrue);
    });

    test('Payment model uses high-density scannable QR image url', () {
      final payment = Payment(
        qr: KhqrHelper.verifiedStaticKhrQr,
        md5: KhqrHelper.verifiedStaticKhrMd5,
        amount: 40.0,
        currency: 'USD',
        bakongAccountId: 'lyhav_voeurn@bkrt',
        merchantName: 'LYHAV VOEURN',
      );

      expect(payment.qrImageUrl, equals(KhqrHelper.verifiedQrImageUrl));
      expect(payment.qrImageUrlFallback, equals(KhqrHelper.verifiedQrImageUrlFallback));
      expect(payment.md5, equals('1039423af4af31a78945b40a87638134'));
      expect(payment.qr, startsWith('00020101021129210017lyhav_voeurn@bkrt'));
    });
  });
}

