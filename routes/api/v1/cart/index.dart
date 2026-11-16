import 'dart:io';
import 'package:api/controller/cart_controller.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  final controller = context.read<CartController>();
  return switch (context.request.method) {
    HttpMethod.get => controller.getCart(context),
    HttpMethod.delete => controller.clearCart(context),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}
