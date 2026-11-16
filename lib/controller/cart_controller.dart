import 'dart:convert';
import 'dart:io';
import 'package:api/services/auth_service.dart';
import 'package:api/services/cart_service.dart';
import 'package:dart_frog/dart_frog.dart';

class CartController {
  CartController({
    required CartService cartService,
    required AuthService authService,
  }) : _cartService = cartService,
       _authService = authService;

  final CartService _cartService;
  final AuthService _authService;

  Future<String> _resolveUserId(
    RequestContext context, {
    Map<String, dynamic>? bodyJson,
  }) async {
    final authHeader =
        context.request.headers['authorization'] ??
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

    // Default guest identifier if not logged in
    return 'guest_user';
  }

  Future<Response> getCart(RequestContext context) async {
    try {
      final userId = await _resolveUserId(context);
      final cart = await _cartService.getCart(userId);
      return Response.json(
        body: {
          'success': true,
          'data': cart.toJson(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'error': e.toString()},
      );
    }
  }

  Future<Response> addToCart(RequestContext context) async {
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

      if (productId == null || productId.trim().isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {
            'success': false,
            'error': 'productId is required to add product to bag',
          },
        );
      }

      final userId = await _resolveUserId(context, bodyJson: json);
      final cart = await _cartService.addToCart(
        userId,
        productId: productId.trim(),
        quantity: quantity,
      );

      return Response.json(
        body: {
          'success': true,
          'message': 'Product added to bag successfully',
          'data': cart.toJson(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': e.toString().replaceAll('Exception: ', ''),
        },
      );
    }
  }

  Future<Response> updateItem(RequestContext context) async {
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
      final quantity = (json['quantity'] as num?)?.toInt();

      if (productId == null || productId.trim().isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'productId is required'},
        );
      }

      if (quantity == null) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'quantity is required'},
        );
      }

      final userId = await _resolveUserId(context, bodyJson: json);
      final cart = await _cartService.updateItemQuantity(
        userId,
        productId: productId.trim(),
        quantity: quantity,
      );

      return Response.json(
        body: {
          'success': true,
          'message': 'Cart updated successfully',
          'data': cart.toJson(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'error': e.toString()},
      );
    }
  }

  Future<Response> removeItem(RequestContext context) async {
    try {
      String? productId;
      Map<String, dynamic>? json;

      final body = await context.request.body();
      if (body.isNotEmpty) {
        json = jsonDecode(body) as Map<String, dynamic>;
        productId = json['productId'] as String?;
      }

      productId ??= context.request.uri.queryParameters['productId'];

      if (productId == null || productId.trim().isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'productId is required'},
        );
      }

      final userId = await _resolveUserId(context, bodyJson: json);
      final cart = await _cartService.removeItem(userId, productId.trim());

      return Response.json(
        body: {
          'success': true,
          'message': 'Item removed from bag',
          'data': cart.toJson(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'error': e.toString()},
      );
    }
  }

  Future<Response> clearCart(RequestContext context) async {
    try {
      final userId = await _resolveUserId(context);
      final cart = await _cartService.clearCart(userId);
      return Response.json(
        body: {
          'success': true,
          'message': 'Cart cleared successfully',
          'data': cart.toJson(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'error': e.toString()},
      );
    }
  }

  Future<Response> applyPromo(RequestContext context) async {
    try {
      final body = await context.request.body();
      if (body.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'Request body is required'},
        );
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final code = json['promoCode'] as String? ?? json['code'] as String?;

      if (code == null || code.trim().isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'promoCode is required'},
        );
      }

      final userId = await _resolveUserId(context, bodyJson: json);
      final cart = await _cartService.applyPromoCode(userId, code.trim());

      return Response.json(
        body: {
          'success': true,
          'message': 'Promo code applied successfully',
          'data': cart.toJson(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': e.toString().replaceAll('Exception: ', ''),
        },
      );
    }
  }
}
