import 'dart:io';
import 'package:api/controller/product_controller.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final controller = context.read<ProductController>();

  switch (context.request.method) {
    case HttpMethod.get:
      return controller.getById(context, id);
    case HttpMethod.put:
    case HttpMethod.patch:
      return controller.update(context, id);
    case HttpMethod.delete:
      return controller.delete(context, id);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {'success': false, 'error': 'Method not allowed'},
      );
  }
}

