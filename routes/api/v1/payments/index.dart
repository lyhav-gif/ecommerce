import 'dart:io';
import 'package:api/controller/payment_controller.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  final controller = context.read<PaymentController>();

  switch (context.request.method) {
    case HttpMethod.get:
      return controller.list(context);
    case HttpMethod.post:
      return controller.generate(context);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {'success': false, 'error': 'Method not allowed'},
      );
  }
}

