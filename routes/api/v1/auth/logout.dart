import 'dart:io';
import 'package:api/controller/auth_controller.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    return context.read<AuthController>().logout(context);
  }
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

