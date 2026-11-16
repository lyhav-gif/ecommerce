import 'package:api/config/app_config.dart';
import 'package:api/controller/auth_controller.dart';
import 'package:api/controller/cart_controller.dart';
import 'package:api/controller/order_controller.dart';
import 'package:api/controller/payment_controller.dart';
import 'package:api/controller/product_controller.dart';
import 'package:api/database/mongo_db.dart';
import 'package:api/models/product.dart';
import 'package:api/services/auth_service.dart';
import 'package:api/services/bakong_service.dart';
import 'package:api/services/cart_service.dart';
import 'package:api/services/jwt_service.dart';
import 'package:api/services/order_service.dart';
import 'package:api/services/payment_service.dart';
import 'package:api/services/product_service.dart';
import 'package:dart_frog/dart_frog.dart';

final _config = AppConfig.load();
final _mongoDb = MongoDatabase(config: _config);
final _jwtService = JwtService(secret: _config.jwtSecret);
final _bakongService = BakongService(config: _config);
final _productService = ProductService(
  database: _mongoDb,
  bakongService: _bakongService,
);
final _paymentService = PaymentService(
  database: _mongoDb,
  bakongService: _bakongService,
);
final _authService = AuthService(
  database: _mongoDb,
  jwtService: _jwtService,
);
final _cartService = CartService(database: _mongoDb);
final _orderService = OrderService(
  database: _mongoDb,
  paymentService: _paymentService,
  cartService: _cartService,
  authService: _authService,
);

final _productController = ProductController(productService: _productService);
final _paymentController = PaymentController(
  paymentService: _paymentService,
  authService: _authService,
  orderService: _orderService,
  cartService: _cartService,
);
final _authController = AuthController(authService: _authService);
final _cartController = CartController(
  cartService: _cartService,
  authService: _authService,
);
final _orderController = OrderController(
  orderService: _orderService,
  authService: _authService,
);

bool _initialized = false;

Future<void> _ensureInitialData() async {
  if (_initialized) return;
  _initialized = true;

  try {
    // 1. Seed static KHQR for USD and KHR
    final staticUsd = _bakongService.generateIndividualKhqr(
      amount: 0,
      currency: 'USD',
      storeLabel: 'MEAW Store',
      terminalLabel: 'Main Store',
    );
    await _paymentService.upsertStaticPayment(
      qr: staticUsd.qr,
      md5: staticUsd.md5,
      currency: 'USD',
      qrImageUrl: Product.buildQrImageUrl(staticUsd.qr),
    );

    final staticKhr = _bakongService.generateIndividualKhqr(
      amount: 0,
      currency: 'KHR',
      storeLabel: 'MEAW Store',
      terminalLabel: 'Main Store',
    );
    await _paymentService.upsertStaticPayment(
      qr: staticKhr.qr,
      md5: staticKhr.md5,
      currency: 'KHR',
      qrImageUrl: Product.buildQrImageUrl(staticKhr.qr),
    );
  } catch (_) {}

  try {
    // 2. Seed default Figma user (Roth Sethi / Sethi@gmail.com)
    final existingUser = await _authService.getUserByEmail('Sethi@gmail.com');
    if (existingUser == null) {
      await _authService.signUp(
        name: 'Roth Sethi',
        email: 'Sethi@gmail.com',
        password: 'Password123!',
        phone: '+855 12 345 678',
        address: 'Street 2004, Phnom Penh, Cambodia',
        avatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      );
    }
  } catch (_) {}

  try {
    // 3. Seed default Figma products
    await _productService.seedFigmaProducts();
  } catch (_) {}
}

Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(_initMiddleware)
      .use(_corsMiddleware)
      .use(provider<AppConfig>((_) => _config))
      .use(provider<MongoDatabase>((_) => _mongoDb))
      .use(provider<JwtService>((_) => _jwtService))
      .use(provider<BakongService>((_) => _bakongService))
      .use(provider<ProductService>((_) => _productService))
      .use(provider<PaymentService>((_) => _paymentService))
      .use(provider<AuthService>((_) => _authService))
      .use(provider<CartService>((_) => _cartService))
      .use(provider<OrderService>((_) => _orderService))
      .use(provider<ProductController>((_) => _productController))
      .use(provider<PaymentController>((_) => _paymentController))
      .use(provider<AuthController>((_) => _authController))
      .use(provider<CartController>((_) => _cartController))
      .use(provider<OrderController>((_) => _orderController));
}

Handler _initMiddleware(Handler handler) {
  return (context) async {
    await _ensureInitialData();
    return handler(context);
  };
}

Handler _corsMiddleware(Handler handler) {
  return (context) async {
    if (context.request.method == HttpMethod.options) {
      return Response(
        statusCode: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers':
              'Origin, Content-Type, Authorization, x-auth-token',
        },
      );
    }
    final response = await handler(context);
    return response.copyWith(
      headers: {
        ...response.headers,
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers':
            'Origin, Content-Type, Authorization, x-auth-token',
      },
    );
  };
}
