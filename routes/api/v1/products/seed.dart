import 'dart:io';
import 'package:api/controller/product_controller.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post ||
      context.request.method == HttpMethod.get) {
    return context.read<ProductController>().seed(context);
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}
