import 'dart:io';
import 'package:api/controller/product_controller.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  final controller = context.read<ProductController>();

  return switch (context.request.method) {
    HttpMethod.get => controller.getAll(context),
    HttpMethod.post => controller.create(context),
    _ => Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {'success': false, 'error': 'Method not allowed'},
      ),
  };
}
