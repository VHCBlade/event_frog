import 'package:dart_frog/dart_frog.dart';
import 'package:event_authentication/event_authenticator_db.dart';
import 'package:event_db/event_db.dart';
import 'package:event_frog/event_frog.dart';

/// Holds common middleware to be used in your websites at specific points.
class EventMiddleware {
  /// [Middleware] that causes all responses built underneath it to be safe.
  ///
  /// This means that if an [Exception] or an [Error] is thrown while the
  /// [Response] is being built, an automatic response is generated instead
  /// of returning the default 500 error.
  ///
  /// This requires a [ResponseErrorBuilder] to be provided before this
  /// middleware. You can also modify the automatic error to response mapping
  /// by modifying the provided [ResponseErrorBuilder]
  static Middleware get safeResponse =>
      (Handler handler) => (RequestContext context) =>
          context.responseBuilder.createSafeResponse(context, handler);

  /// [Middleware] that authenticates the existence of a JWT in the
  /// Authorization header and validates it. This will automatically throw
  /// errors if the JWT is invalid. You can use [safeResponse] above this
  /// to automatically catch these errors.
  ///
  /// This will also automatically update the token in the response if
  /// renewing it would cause the expiration to be extended. The expiry
  /// is set based on the value set in [EventEnvironment]
  ///
  /// This requires the following classes to be provided before this middleware:
  /// * [EventEnvironment]
  /// * [DatabaseRepository]
  /// * [AuthenticationSecretsRepository]
  /// * [JWTSigner]
  /// Consider using [EventFrogMiddlewareStack] to easily manage these.
  ///
  /// This also requires that you save your users in
  /// [ResponseBuilderContext.userDatabase] and your authentication using
  /// [ResponseBuilderContext.databaseUserAuthenticator]
  static Middleware get authenticatedResponse =>
      (handler) => (context) => context.authenticatedResponseBuilder
          .createAuthenticatedResponse(context, handler);
}
