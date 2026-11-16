import 'dart:io';
import 'package:api/controller/payment_controller.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String md5) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'success': false, 'error': 'Method not allowed. Use GET.'},
    );
  }

  final controller = context.read<PaymentController>();
  return controller.getByMd5(context, md5);
}
