import 'dart:convert';
import 'dart:io';
import 'package:api/services/auth_service.dart';
import 'package:api/services/cart_service.dart';
import 'package:api/services/order_service.dart';
import 'package:api/services/payment_service.dart';
import 'package:dart_frog/dart_frog.dart';

class PaymentController {
  PaymentController({
    required PaymentService paymentService,
    required AuthService authService,
    required OrderService orderService,
    required CartService cartService,
  })  : _paymentService = paymentService,
        _authService = authService,
        _orderService = orderService,
        _cartService = cartService;

  final PaymentService _paymentService;
  final AuthService _authService;
  final OrderService _orderService;
  final CartService _cartService;

  Future<String> _resolveUserId(
    RequestContext context, {
    Map<String, dynamic>? bodyJson,
  }) async {
    final authHeader = context.request.headers['authorization'] ??
        context.request.headers['Authorization'];
    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      final token = authHeader.substring(7).trim();
      if (token.isNotEmpty && !token.startsWith('{{')) {
        try {
          final user = await _authService.getUserFromToken(token);
          if (user?.id != null) return user!.id!;
        } catch (_) {}
      }
    }

    final headerToken = context.request.headers['x-auth-token'];
    if (headerToken != null && headerToken.isNotEmpty && !headerToken.startsWith('{{')) {
      try {
        final user = await _authService.getUserFromToken(headerToken);
        if (user?.id != null) return user!.id!;
      } catch (_) {}
    }

    if (bodyJson != null &&
        bodyJson['userId'] != null &&
        bodyJson['userId'].toString().isNotEmpty) {
      return bodyJson['userId'].toString();
    }

    final queryUserId = context.request.uri.queryParameters['userId'];
    if (queryUserId != null && queryUserId.isNotEmpty) {
      return queryUserId;
    }

    return 'guest_user';
  }

  Future<Response> generate(RequestContext context) async {
    try {
      final body = await context.request.body();
      Map<String, dynamic> json = {};
      if (body.isNotEmpty) {
        json = jsonDecode(body) as Map<String, dynamic>;
      }

      final userId = await _resolveUserId(context, bodyJson: json);
      final productId = json['productId']?.toString().trim();
      final quantity = (json['quantity'] as num?)?.toInt() ?? 1;
      final paymentMethod =
          json['paymentMethod']?.toString() ?? 'digital_payment';
      final deliveryAddress = json['deliveryAddress']?.toString();
      final promoCode = json['promoCode']?.toString();
      final orderId = json['orderId']?.toString().trim();
      final fromCart = json['fromCart'] == true || json['cart'] == true;
      final rawAmount = (json['amount'] as num?)?.toDouble();

      // Case 1: Direct Buy / Purchase of Product via /api/v1/payments
      if (productId != null &&
          productId.isNotEmpty &&
          !productId.startsWith('{{')) {
        final order = await _orderService.buyNow(
          userId: userId,
          productId: productId,
          quantity: quantity,
          paymentMethod: paymentMethod,
          deliveryAddress: deliveryAddress,
          promoCode: promoCode,
        );

        final paymentDoc =
            await _paymentService.getPaymentByMd5(order.md5 ?? '');

        return Response.json(
          statusCode: HttpStatus.created,
          body: {
            'success': true,
            'message': 'Payment generated successfully for Buy Now',
            'data': {
              if (paymentDoc != null) ...paymentDoc.toJson(),
              'orderId': order.id,
              'orderNumber': order.orderNumber,
              'customerName': order.customerName,
              'amount': order.totalAmount,
              'currency': order.currency,
              'qr': order.khqr,
              'md5': order.md5,
              'qrImageUrl': order.qrImageUrl,
              if (order.qrImageUrlFallback != null)
                'qrImageUrlFallback': order.qrImageUrlFallback,
              'orderStatus': order.orderStatus,
              'paymentStatus': order.paymentStatus,
              'paymentMethod': order.paymentMethod,
              'deliveryAddress': order.deliveryAddress,
              'items': order.items.map((i) => i.toJson()).toList(),
            },
            'order': order.toJson(),
          },
        );
      }

      // Case 2: Checkout Cart into Payment via /api/v1/payments
      final userCart = await _cartService.getCart(userId);
      final guestCart = await _cartService.getCart('guest_user');
      final hasCartItems =
          userCart.items.isNotEmpty || guestCart.items.isNotEmpty;

      final isCartCheckout = fromCart ||
          hasCartItems ||
          (productId == null &&
              orderId == null &&
              (rawAmount == null || rawAmount <= 0));

      if (isCartCheckout) {
        final order = await _orderService.checkout(
          userId: userId,
          paymentMethod: paymentMethod,
          deliveryAddress: deliveryAddress,
          promoCode: promoCode,
        );

        final paymentDoc =
            await _paymentService.getPaymentByMd5(order.md5 ?? '');

        return Response.json(
          statusCode: HttpStatus.created,
          body: {
            'success': true,
            'message': 'Payment generated successfully from shopping cart',
            'data': {
              if (paymentDoc != null) ...paymentDoc.toJson(),
              'orderId': order.id,
              'orderNumber': order.orderNumber,
              'customerName': order.customerName,
              'amount': order.totalAmount,
              'currency': order.currency,
              'qr': order.khqr,
              'md5': order.md5,
              'qrImageUrl': order.qrImageUrl,
              if (order.qrImageUrlFallback != null)
                'qrImageUrlFallback': order.qrImageUrlFallback,
              'orderStatus': order.orderStatus,
              'paymentStatus': order.paymentStatus,
              'paymentMethod': order.paymentMethod,
              'deliveryAddress': order.deliveryAddress,
              'items': order.items.map((i) => i.toJson()).toList(),
            },
            'order': order.toJson(),
          },
        );
      }

      // Case 3: Existing Order Payment
      if (orderId != null && orderId.isNotEmpty) {
        final order = await _orderService.getOrderById(orderId);
        if (order == null) {
          return Response.json(
            statusCode: HttpStatus.notFound,
            body: {'success': false, 'error': 'Order not found: $orderId'},
          );
        }

        final payment = await _paymentService.createPayment(
          amount: order.totalAmount,
          currency: order.currency,
          orderId: order.id,
          billNumber: order.orderNumber,
          metadata: {'orderNumber': order.orderNumber, 'userId': userId},
        );

        return Response.json(
          statusCode: HttpStatus.created,
          body: {
            'success': true,
            'message': 'Payment generated for order: ${order.orderNumber}',
            'data': payment.toJson(),
            'order': order.toJson(),
          },
        );
      }

      // Case 4: Custom Amount Payment
      if (rawAmount != null && rawAmount > 0) {
        final currency = json['currency']?.toString() ?? 'USD';
        final billNumber = json['billNumber']?.toString();
        final metadata = json['metadata'] as Map<String, dynamic>?;

        final payment = await _paymentService.createPayment(
          amount: rawAmount,
          currency: currency,
          billNumber: billNumber,
          metadata: metadata,
        );

        return Response.json(
          statusCode: HttpStatus.created,
          body: {
            'success': true,
            'message': 'KHQR payment generated successfully',
            'data': payment.toJson(),
          },
        );
      }

      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error':
              'Please provide productId (e.g. "Aura Cream 1+1" or "Linin Body Cream"), amount, or fromCart: true'
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': e.toString().replaceAll('Exception: ', '')},
      );
    }
  }

  Future<Response> verify(RequestContext context) async {
    try {
      String? md5;

      final queryParams = context.request.uri.queryParameters;
      if (queryParams.containsKey('md5')) {
        md5 = queryParams['md5'];
      }

      if (md5 == null || md5.trim().isEmpty) {
        final body = await context.request.body();
        if (body.isNotEmpty) {
          final json = jsonDecode(body) as Map<String, dynamic>;
          md5 = json['md5']?.toString();
        }
      }

      if (md5 == null || md5.trim().isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'MD5 hash is required to verify payment'},
        );
      }

      final result = await _paymentService.verifyPayment(md5.trim());
      return Response.json(
        body: {
          'success': true,
          ...result,
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'error': e.toString()},
      );
    }
  }

  Future<Response> getByMd5(RequestContext context, String md5) async {
    try {
      final payment = await _paymentService.getPaymentByMd5(md5);
      if (payment == null) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'success': false, 'error': 'Payment record not found'},
        );
      }

      return Response.json(
        body: {'success': true, 'data': payment.toJson()},
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'error': e.toString()},
      );
    }
  }

  Future<Response> list(RequestContext context) async {
    try {
      final list = await _paymentService.getAllPayments();
      return Response.json(
        body: {
          'success': true,
          'count': list.length,
          'data': list.map((p) => p.toJson()).toList(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'error': e.toString()},
      );
    }
  }
}

