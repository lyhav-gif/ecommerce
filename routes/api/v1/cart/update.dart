import 'dart:io';
import 'package:api/controller/cart_controller.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  final controller = context.read<CartController>();
  if (context.request.method == HttpMethod.put ||
      context.request.method == HttpMethod.post) {
    return controller.updateItem(context);
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

