import 'dart:io';
import 'package:api/controller/auth_controller.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  final controller = context.read<AuthController>();
  switch (context.request.method) {
    case HttpMethod.get:
      return controller.getMe(context);
    case HttpMethod.put:
      return controller.updateMe(context);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

