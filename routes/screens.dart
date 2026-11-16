import 'dart:io';
import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  final file = File('test_screens.html');
  String html;
  if (file.existsSync()) {
    html = file.readAsStringSync();
  } else {
    html = '<h1>MEAW Screen Tester</h1><p>test_screens.html not found</p>';
  }

  return Response(
    body: html,
    headers: {
      HttpHeaders.contentTypeHeader: 'text/html; charset=utf-8',
    },
  );
}
