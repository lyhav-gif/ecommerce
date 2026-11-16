import 'dart:convert';
import 'dart:io';
import 'package:api/models/user.dart';
import 'package:api/services/auth_service.dart';
import 'package:dart_frog/dart_frog.dart';

class AuthController {
  AuthController({required AuthService authService})
      : _authService = authService;

  final AuthService _authService;

  String? _extractToken(RequestContext context) {
    final authHeader = context.request.headers['authorization'] ??
        context.request.headers['Authorization'];
    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      return authHeader.substring(7).trim();
    }
    return context.request.headers['x-auth-token'];
  }

  Future<Response> signUp(RequestContext context) async {
    try {
      final body = await context.request.body();
      if (body.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'Request body is required'},
        );
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final name = json['name'] as String?;
      final email = json['email'] as String?;
      final password = json['password'] as String?;

      if (name == null || name.trim().isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'Name is required'},
        );
      }

      if (email == null || email.trim().isEmpty || !email.contains('@')) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'Valid email is required'},
        );
      }

      if (password == null || password.length < 6) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {
            'success': false,
            'error': 'Password must be at least 6 characters',
          },
        );
      }

      final user = await _authService.signUp(
        name: name,
        email: email,
        password: password,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );

      final loginRes = await _authService.login(
        email: email,
        password: password,
      );

      return Response.json(
        statusCode: HttpStatus.ok,
        body: {
          'success': true,
          'message': 'Account ready and authenticated',
          'token_type': 'Bearer',
          'token': loginRes['token'],
          'expires_in': loginRes['expires_in'],
          'user': user.toJson(),
        },
      );
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      return Response.json(
        statusCode: msg.contains('already exists')
            ? HttpStatus.conflict
            : HttpStatus.badRequest,
        body: {'success': false, 'error': msg},
      );
    }
  }

  Future<Response> login(RequestContext context) async {
    try {
      final body = await context.request.body();
      if (body.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'Request body is required'},
        );
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final email = json['email'] as String?;
      final password = json['password'] as String?;

      if (email == null || email.trim().isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'Email is required'},
        );
      }

      if (password == null || password.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'Password is required'},
        );
      }

      final res = await _authService.login(email: email, password: password);
      return Response.json(
        body: {
          'success': true,
          'message': 'Login successful',
          'token_type': 'Bearer',
          'token': res['token'],
          'expires_in': res['expires_in'],
          'user': res['user'],
        },
      );
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': msg},
      );
    }
  }

  Future<Response> logout(RequestContext context) async {
    try {
      String? token = _extractToken(context);
      if (token == null || token.isEmpty) {
        try {
          final body = await context.request.body();
          if (body.isNotEmpty) {
            final json = jsonDecode(body) as Map<String, dynamic>;
            token = json['token'] as String?;
          }
        } catch (_) {}
      }

      if (token == null || token.isEmpty) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'success': false, 'error': 'Authorization token is required'},
        );
      }

      await _authService.logout(token);
      return Response.json(
        body: {'success': true, 'message': 'Logged out successfully'},
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'error': e.toString()},
      );
    }
  }

  Future<Response> getMe(RequestContext context) async {
    try {
      final token = _extractToken(context);
      User? user;

      if (token != null && token.isNotEmpty) {
        user = await _authService.getUserFromToken(token);
      }

      if (user == null) {
        final queryUserId = context.request.uri.queryParameters['userId'];
        if (queryUserId != null && queryUserId.isNotEmpty) {
          user = await _authService.getUserById(queryUserId);
        }
      }

      if (user == null) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {
            'success': false,
            'error': 'Unauthorized or user not found. Please login.',
          },
        );
      }

      return Response.json(
        body: {
          'success': true,
          'user': user.toJson(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'error': e.toString()},
      );
    }
  }

  Future<Response> updateMe(RequestContext context) async {
    try {
      final token = _extractToken(context);
      User? user;
      if (token != null && token.isNotEmpty) {
        user = await _authService.getUserFromToken(token);
      }

      final body = await context.request.body();
      final json = body.isNotEmpty
          ? jsonDecode(body) as Map<String, dynamic>
          : <String, dynamic>{};

      final targetUserId = user?.id ?? json['userId'] as String?;
      if (targetUserId == null) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {'success': false, 'error': 'Unauthorized'},
        );
      }

      final updated = await _authService.updateProfile(
        targetUserId,
        name: json['name'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );

      return Response.json(
        body: {
          'success': true,
          'message': 'Profile updated successfully',
          'user': updated.toJson(),
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'error': e.toString()},
      );
    }
  }
}

