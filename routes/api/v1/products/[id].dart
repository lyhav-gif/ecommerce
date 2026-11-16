import 'dart:io';
import 'package:api/controller/product_controller.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final controller = context.read<ProductController>();

  return switch (context.request.method) {
    HttpMethod.get => controller.getById(context, id),
    HttpMethod.put || HttpMethod.patch => controller.update(context, id),
    HttpMethod.delete => controller.delete(context, id),
    _ => Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {'success': false, 'error': 'Method not allowed'},
      ),
  };
}
