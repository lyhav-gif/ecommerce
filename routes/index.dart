import 'package:api/config/app_config.dart';
import 'package:api/database/mongo_db.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  final config = context.read<AppConfig>();
  final mongoDb = context.read<MongoDatabase>();

  Map<String, dynamic> dbStatus;
  try {
    dbStatus = await mongoDb.checkHealth();
  } catch (e) {
    dbStatus = {'status': 'disconnected', 'error': e.toString()};
  }

  return Response.json(
    body: {
      'name': config.appName,
      'environment': config.appEnv,
      'status': 'online',
      'timestamp': DateTime.now().toIso8601String(),
      'database': dbStatus,
      'bakong': {
        'environment': config.bakongEnv,
        'accountId': config.bakongAccountId,
        'merchantName': config.bakongMerchantName,
        'currency': config.khqrCurrency,
        'apiUrl': config.bakongApiUrl,
      },
      'routes': {
        'auth': {
          'signup': 'POST /api/v1/auth/signup',
          'login': 'POST /api/v1/auth/login',
          'logout': 'POST /api/v1/auth/logout',
          'me': 'GET /api/v1/auth/me | PUT /api/v1/auth/me',
        },
        'cart': {
          'get_or_clear': 'GET /api/v1/cart | DELETE /api/v1/cart',
          'add_item': 'POST /api/v1/cart/add',
          'update_qty': 'PUT /api/v1/cart/update',
          'remove_item': 'POST /api/v1/cart/remove',
          'apply_promo': 'POST /api/v1/cart/promo',
        },
        'orders': {
          'buy_now':
              'POST /api/v1/orders/buy-now (Instant Purchase + KHQR/COD)',
          'checkout': 'POST /api/v1/orders/checkout (Cart Checkout + KHQR/COD)',
          'list_orders': 'GET /api/v1/orders',
          'order_detail': 'GET /api/v1/orders/[id]',
        },
        'products': {
          'list_or_create':
              'POST /api/v1/products | GET /api/v1/products?category=Beauty',
          'seed_figma': 'POST /api/v1/products/seed',
          'item_operations':
              'GET /api/v1/products/[id] | PUT /api/v1/products/[id] | DELETE /api/v1/products/[id]',
        },
        'payments': {
          'buy_or_checkout':
              'POST /api/v1/payments (Buy product, checkout cart, or custom KHQR)',
          'generate_khqr': 'POST /api/v1/payments/generate',
          'verify_transaction':
              'POST /api/v1/payments/verify or GET /api/v1/payments/verify?md5={md5}',
          'list_payments': 'GET /api/v1/payments',
          'payment_detail': 'GET /api/v1/payments/[md5]',
        },
        'screens_testing': {
          'interactive_ui':
              'GET /screens (Interactive Figma App simulator for testing)',
          'khqr_scanner': 'GET /qr (Bakong KHQR test card)',
        },
      },
    },
  );
}
