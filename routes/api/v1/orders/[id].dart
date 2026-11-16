import 'dart:io';
import 'package:api/controller/order_controller.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method == HttpMethod.get) {
    return context.read<OrderController>().getOrderById(context, id);
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

