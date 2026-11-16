import 'dart:convert';
import 'dart:io';
import 'package:api/models/product.dart';
import 'package:api/services/product_service.dart';
import 'package:dart_frog/dart_frog.dart';

class ProductController {
  ProductController({required ProductService productService})
      : _productService = productService;

  final ProductService _productService;

  Future<Response> getAll(RequestContext context) async {
    try {
      final category = context.request.uri.queryParameters['category'];
      final search = context.request.uri.queryParameters['search'];
      final products = await _productService.getAllProducts(
        category: category,
        search: search,
      );
      return Response.json(
        body: {
          'success': true,
          'count': products.length,
          if (category != null) 'category': category,
          'data': products.map((p) => p.toJson()).toList(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'error': e.toString()},
      );
    }
  }

  Future<Response> getById(RequestContext context, String id) async {
    try {
      final product = await _productService.getProductById(id);
      if (product == null) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'success': false, 'error': 'Product not found'},
        );
      }
      return Response.json(
        body: {'success': true, 'data': product.toJson()},
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'error': e.toString()},
      );
    }
  }

  Future<Response> create(RequestContext context) async {
    try {
      final body = await context.request.body();
      if (body.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'Request body is empty'},
        );
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final name = json['name'] as String?;
      final price = (json['price'] as num?)?.toDouble();

      if (name == null || name.trim().isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'Product name is required'},
        );
      }

      if (price == null || price <= 0) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'Valid product price is required'},
        );
      }

      final product = Product(
        name: name.trim(),
        description: json['description']?.toString() ?? '',
        price: price,
        currency: (json['currency']?.toString() ?? 'USD').toUpperCase(),
        imageUrl: json['imageUrl']?.toString() ?? '',
        category: json['category']?.toString() ?? 'Beauty',
        brand: json['brand']?.toString() ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 128,
        stock: (json['stock'] as num?)?.toInt() ?? 100,
        tag: json['tag']?.toString() ?? '',
        isFlash: json['isFlash'] as bool? ?? false,
      );

      final created = await _productService.createProduct(product);
      return Response.json(
        statusCode: HttpStatus.created,
        body: {
          'success': true,
          'message': 'Product created successfully',
          'data': created.toJson(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'error': e.toString()},
      );
    }
  }

  Future<Response> update(RequestContext context, String id) async {
    try {
      final body = await context.request.body();
      if (body.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'Request body is empty'},
        );
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final updated = await _productService.updateProduct(id, json);
      if (updated == null) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'success': false, 'error': 'Product not found or update failed'},
        );
      }

      return Response.json(
        body: {
          'success': true,
          'message': 'Product updated successfully',
          'data': updated.toJson(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'error': e.toString()},
      );
    }
  }

  Future<Response> delete(RequestContext context, String id) async {
    try {
      final deleted = await _productService.deleteProduct(id);
      if (!deleted) {
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {'success': false, 'error': 'Product not found or delete failed'},
        );
      }

      return Response.json(
        body: {'success': true, 'message': 'Product deleted successfully'},
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'error': e.toString()},
      );
    }
  }

  Future<Response> seed(RequestContext context) async {
    try {
      final products = await _productService.seedFigmaProducts();
      return Response.json(
        body: {
          'success': true,
          'message': 'Default Figma products seeded successfully',
          'count': products.length,
          'data': products.map((p) => p.toJson()).toList(),
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
