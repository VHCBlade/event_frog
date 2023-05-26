import 'package:dart_frog/dart_frog.dart';

/// The default 404 response of Dart_Frog. Used to hide an actual handling by
/// the server.
Response notFoundResponse([RequestContext? _]) {
  return Response(statusCode: 404, body: 'Route not found');
}

/// Default login fail response. Should be returned whether the account was
/// not found or the password is incorrect.
Response loginFailResponse([RequestContext? _]) {
  return Response(
    statusCode: 401,
    body:
        'We could not find an account with that email and/or password. Please try again.',
  );
}

/// Default response for an invalid JWTResponse
Response invalidJWTResponse([RequestContext? _]) {
  return Response(statusCode: 401, body: 'Invalid or Expired Token');
}

/// Default response for permission errors. Sometimes, for security, it would be
/// better to return a [notFoundResponse] instead.
Response permissionResponse([RequestContext? _]) {
  return Response(
    statusCode: 401,
    body: 'You do not have adequate permission to access that resource.',
  );
}

/// Default error response when something is wrong with a model.
Response syntaxErrorResponse([RequestContext? _]) {
  return Response(statusCode: 400, body: 'Syntax Error for Request');
}

/// The default 500 response of Dart_Frog. Used for simple consistency.
Response unexpectedErrorResponse([RequestContext? _]) {
  return Response(
    statusCode: 500,
    body: 'Internal Server Error',
  );
}
