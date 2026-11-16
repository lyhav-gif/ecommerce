import 'dart:io';
import 'package:api/controller/product_controller.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  final controller = context.read<ProductController>();

  switch (context.request.method) {
    case HttpMethod.get:
      return controller.getAll(context);
    case HttpMethod.post:
      return controller.create(context);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {'success': false, 'error': 'Method not allowed'},
      );
  }
}

