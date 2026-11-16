import 'dart:io';
import 'package:api/controller/auth_controller.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  final controller = context.read<AuthController>();
  return switch (context.request.method) {
    HttpMethod.get => controller.getMe(context),
    HttpMethod.put => controller.updateMe(context),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}
