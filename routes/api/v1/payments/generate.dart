import 'dart:io';
import 'package:api/controller/payment_controller.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'success': false, 'error': 'Method not allowed. Use POST.'},
    );
  }

  final controller = context.read<PaymentController>();
  return controller.generate(context);
}

