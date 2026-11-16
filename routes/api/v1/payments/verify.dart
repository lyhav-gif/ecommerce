import 'dart:io';
import 'package:api/controller/payment_controller.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post && context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'success': false, 'error': 'Method not allowed. Use GET or POST.'},
    );
  }

  final controller = context.read<PaymentController>();
  return controller.verify(context);
}

