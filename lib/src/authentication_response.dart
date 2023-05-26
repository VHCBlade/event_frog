import 'dart:async';

import 'package:dart_frog/dart_frog.dart';
import 'package:event_authentication/event_authentication.dart';
import 'package:event_frog/event_frog.dart';

/// Helps authenticate jwts and create them from logins
class AuthenticatedResponseBuilder {
  /// Performs an emailLogin for an [EmailLoginRequest] that is
  /// in the request inside [context]
  ///
  /// Change referenced database in [EventEnvironment]
  Future<Response> emailLogin(
    RequestContext context,
  ) async {
    final database = context.userDatabase;

    final emailLoginRequest =
        await context.request.bodyAsModel(EmailLoginRequest.new);

    final users = await database.searchByModelAndFields(
      UserModel.new,
      UserModel()..email = emailLoginRequest.email,
      ['email'],
    );

    if (users.length != 1) {
      return loginFailResponse();
    }

    final savedUser = users.first;

    final authenticator = await context.databaseUserAuthenticator;
    final confirmed = await authenticator.confirmPassword(
      savedUser,
      emailLoginRequest.password,
    );
    if (!confirmed) {
      return loginFailResponse();
    }
    final jwt = BaseJWT.fromUserModel(
      savedUser,
      duration: emailLoginRequest.noExpiry
          ? const Duration(days: 365 * 200)
          : context.environment.sessionLength,
    );
    final token = await context.read<JWTSigner>().createToken(jwt);

    return Response(
      body: 'Successful Login',
      headers: {}..authorization = token,
    );
  }

  Future<Response> createSafeResponse(
    RequestContext context,
    FutureOr<Response> Function(RequestContext, BaseJWT) builder, {
    FutureOr<Response> Function(RequestContext)? defaultResponse,
    required PermissionChecker permissionChecker,
  }) async {
    return Response();
  }
}

/// Adds header methods for passing into [Response]
extension HeaderExtension on Map<String, Object> {
  /// Sets the [token] into the Authrorization header
  set authorization(String? token) => token == null
      ? remove('Authorization')
      : this['Authorization'] = 'Bearer $token';

  /// Gets the JWT Token from the Authorization header
  String? get authorization => this['Authorization'] == null
      ? null
      : "${this['Authorization']}".startsWith('Bearer ')
          ? "${this['Authorization']}".substring('Bearer '.length)
          : "${this['Authorization']}";
}
