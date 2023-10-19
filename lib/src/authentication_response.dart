import 'dart:async';

import 'package:dart_frog/dart_frog.dart';
import 'package:event_authentication/event_authentication.dart';
import 'package:event_db/event_db.dart';
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

  /// Pulls the [BaseJWT] from the [context]'s headers and authenticates it.
  ///
  /// This will also update the Authorization token on 200 status code response
  /// to have a more up to date token.
  Future<Response> createAuthenticatedResponse(
    RequestContext context,
    FutureOr<Response> Function(RequestContext) builder, {
    FutureOr<Response> Function(RequestContext)? defaultResponse,
  }) async {
    final authorization = context.request.headers.authorization;
    if (authorization == null) {
      throw PermissionException();
    }
    final signer = context.read<JWTSigner>();
    final jwt = await signer.validateAndDecodeToken(authorization);

    await validateRoles(context, jwt);

    final response = await builder(context.provide<BaseJWT>(() => jwt));
    if (response.statusCode != 200) {
      return response;
    }
    final renewedJWT = BaseJWT()
      ..copy(jwt)
      ..dateIssued = DateTime.now()
      ..expiry = context.environment.sessionLength;

    if (renewedJWT.dateIssued
        .add(renewedJWT.expiry)
        .isAfter(jwt.dateIssued.add(jwt.expiry))) {
      return response.copyWith(
        headers: <String, String>{...response.headers}..authorization =
            await signer.createToken(renewedJWT),
      );
    }

    return response.copyWith(
      headers: <String, String>{...response.headers}..authorization =
          authorization,
    );
  }

  /// Checks the User database in [context] to make sure that the user reference
  /// in [jwt] is still valid.
  Future<void> validateRoles(RequestContext context, BaseJWT jwt) async {
    final database = context.userDatabase;
    final user = await database.findModel<UserModel>(jwt.id!);
    if (user == null) {
      throw PermissionException();
    }

    final checker = AllRoleChecker(user.roles.roles.toSet());
    await checker.assertPermission(context, jwt);
  }
}
