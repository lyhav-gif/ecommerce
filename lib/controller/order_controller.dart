import 'dart:convert';
import 'dart:io';
import 'package:api/services/auth_service.dart';
import 'package:api/services/order_service.dart';
import 'package:dart_frog/dart_frog.dart';

class OrderController {
  OrderController({
    required OrderService orderService,
    required AuthService authService,
  })  : _orderService = orderService,
        _authService = authService;

  final OrderService _orderService;
  final AuthService _authService;

  Future<String> _resolveUserId(
    RequestContext context, {
    Map<String, dynamic>? bodyJson,
  }) async {
    final authHeader = context.request.headers['authorization'] ??
        context.request.headers['Authorization'];
    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      final token = authHeader.substring(7).trim();
      final user = await _authService.getUserFromToken(token);
      if (user?.id != null) return user!.id!;
    }

    final headerToken = context.request.headers['x-auth-token'];
    if (headerToken != null && headerToken.isNotEmpty) {
      final user = await _authService.getUserFromToken(headerToken);
      if (user?.id != null) return user!.id!;
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

  Future<Response> buyNow(RequestContext context) async {
    try {
      final body = await context.request.body();
      if (body.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'Request body is required'},
        );
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final productId = json['productId'] as String?;
      final quantity = (json['quantity'] as num?)?.toInt() ?? 1;
      final paymentMethod =
          json['paymentMethod'] as String? ?? 'digital_payment';
      final deliveryAddress = json['deliveryAddress'] as String?;
      final promoCode = json['promoCode'] as String?;

      if (productId == null || productId.trim().isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'productId is required for Buy Now'},
        );
      }

      final userId = await _resolveUserId(context, bodyJson: json);
      final order = await _orderService.buyNow(
        userId: userId,
        productId: productId.trim(),
        quantity: quantity,
        paymentMethod: paymentMethod,
        deliveryAddress: deliveryAddress,
        promoCode: promoCode,
      );

      return Response.json(
        statusCode: HttpStatus.created,
        body: {
          'success': true,
          'message': 'Order placed successfully via Buy Now',
          'data': order.toJson(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': e.toString().replaceAll('Exception: ', '')},
      );
    }
  }

  Future<Response> checkout(RequestContext context) async {
    try {
      Map<String, dynamic> json = {};
      final body = await context.request.body();
      if (body.isNotEmpty) {
        json = jsonDecode(body) as Map<String, dynamic>;
      }

      final paymentMethod =
          json['paymentMethod'] as String? ?? 'digital_payment';
      final deliveryAddress = json['deliveryAddress'] as String?;
      final promoCode = json['promoCode'] as String?;

      final userId = await _resolveUserId(context, bodyJson: json);
      final order = await _orderService.checkout(
        userId: userId,
        paymentMethod: paymentMethod,
        deliveryAddress: deliveryAddress,
        promoCode: promoCode,
      );

      return Response.json(
        statusCode: HttpStatus.created,
        body: {
          'success': true,
          'message': 'Cart checked out successfully',
          'data': order.toJson(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': e.toString().replaceAll('Exception: ', '')},
      );
    }
  }

  Future<Response> getOrders(RequestContext context) async {
    try {
      final userId = await _resolveUserId(context);
      final orders = await _orderService.getUserOrders(userId);

      return Response.json(
        body: {
          'success': true,
          'count': orders.length,
          'data': orders.map((o) => o.toJson()).toList(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'error': e.toString()},
      );
    }
  }

  Future<Response> getOrderById(RequestContext context, String id) async {
    try {
      final order = await _orderService.getOrderById(id);
      if (order == null) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'success': false, 'error': 'Order not found: $id'},
        );
      }

      return Response.json(
        body: {
          'success': true,
          'data': order.toJson(),
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

