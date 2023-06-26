import 'dart:async';

import 'package:dart_frog/dart_frog.dart';
import 'package:event_authentication/event_authentication.dart';
import 'package:event_frog/event_frog.dart';

/// These are implemented by exceptions that are specifically used by event_frog
abstract class EventFrogException implements Exception {}

/// Maps a thrown exception to a response builder
typedef ResponseBuilder<T> = FutureOr<Response> Function(RequestContext, T);

/// Automatically maps thrown exceptions/errors to responses to reduce boilerplate.
class ResponseErrorBuilder {
  /// [logger] can be passed to have some logging for unexpected errors.
  ///
  /// If [logAllErrors] is true, all errors will be logged instead of just
  /// unexpected errors.
  ResponseErrorBuilder({this.logger, this.logAllErrors = false});

  /// This is used when something is thrown while running [createSafeResponse]
  ///
  /// You can add to this map to add more exception to response handling.
  final Map<Type, ResponseBuilder<dynamic>> map = {
    EventJWTExpiredException: (context, _) => invalidJWTResponse(),
    EventJWTInvalidException: (context, _) => invalidJWTResponse(),
    PermissionException: (context, _) => permissionResponse(),
    NotFoundException: (context, _) => notFoundResponse(),
    FormatException: (context, _) => syntaxErrorResponse(),
    TypeError: (context, _) => syntaxErrorResponse(),
  };

  /// Called when an unexpected error occurs.
  final void Function(Object)? logger;

  /// If true, [logger] will be called on all errors/exceptions rather than just unexpected ones.
  bool logAllErrors;

  /// Allows the [builder] to create a response. If anything is thrown by
  /// builder, it will automatically catch it and create a new response.
  ///
  /// The response when something is thrown will be generated based on the type.
  /// If no response builder is found for the type it will default to the 500
  /// error.
  ///
  /// You can add [ResponseBuilder]s to [map] to add more thrown handling.
  ///
  /// If [defaultResponse] is provided, it will be used in case of an unhandled
  /// error instead of [unexpectedErrorResponse]
  FutureOr<Response> createSafeResponse(
    RequestContext context,
    FutureOr<Response> Function(RequestContext) builder, {
    FutureOr<Response> Function(RequestContext)? defaultResponse,
  }) async {
    try {
      return await builder(context);
    } on Object catch (e) {
      if (logAllErrors) {
        logger?.call(e);
      }
      if (map.containsKey(e.runtimeType)) {
        return map[e.runtimeType]!(context, e);
      }
      // Need to do this for _CastErrors. Really this will always be an issue
      // for for any form of implementation or extension, but it can't be worked
      // around if the implementing class is private.
      if (e is TypeError && map.containsKey(TypeError)) {
        return map[TypeError]!(context, e);
      }
      if (defaultResponse != null) {
        return defaultResponse(context);
      }
      if (!logAllErrors) {
        logger?.call(e);
      }
      return unexpectedErrorResponse();
    }
  }
}
