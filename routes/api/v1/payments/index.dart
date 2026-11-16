import 'dart:io';
import 'package:api/controller/payment_controller.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  final controller = context.read<PaymentController>();

  return switch (context.request.method) {
    HttpMethod.get => controller.list(context),
    HttpMethod.post => controller.generate(context),
    _ => Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {'success': false, 'error': 'Method not allowed'},
      ),
  };
}
