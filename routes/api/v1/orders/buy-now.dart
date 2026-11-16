import 'dart:io';
import 'package:api/controller/order_controller.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    return context.read<OrderController>().buyNow(context);
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}
