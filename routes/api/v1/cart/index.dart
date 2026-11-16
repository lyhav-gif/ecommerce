import 'dart:io';
import 'package:api/controller/cart_controller.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  final controller = context.read<CartController>();
  switch (context.request.method) {
    case HttpMethod.get:
      return controller.getCart(context);
    case HttpMethod.delete:
      return controller.clearCart(context);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

