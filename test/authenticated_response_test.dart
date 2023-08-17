import 'dart:math';

import 'package:dart_frog/dart_frog.dart';
import 'package:event_authentication/event_authenticator_db.dart';
import 'package:event_db/event_db.dart';
import 'package:event_frog/event_frog.dart';
import 'package:test/test.dart';

class _MockRequestContext extends TestRequestContext {
  @override
  final Request request = Request('POST', Uri.parse('https://example.com/a'));
}

class RequestRequestContextDecorator implements RequestContext {
  RequestRequestContextDecorator(this.request, this.requestContext);
  RequestContext requestContext;

  @override
  final Request request;

  @override
  RequestContext provide<T extends Object?>(T Function() create) {
    requestContext = requestContext.provide<T>(create);
    return this;
  }

  @override
  T read<T>() {
    return requestContext.read<T>();
  }
}

void main() {
  group('AuthenticatedResponseBuilder', () {
    test('createAuthenticatedResponse', createAuthenticatedResponseTest);
    test('refreshedAuthentication', refreshedAuthenticationTest);
  });
}

final _fakeDatabase = FakeDatabaseRepository(
  constructors: {
    UserModel: UserModel.new,
    UserAuthentication: UserAuthentication.new,
  },
);

final providerStack = EventFrogMiddlewareStack(
  [
    provider<AuthenticationSecretsRepository>(
      (context) =>
          FileSecretsRepository(secretsFile: 'test.txt', random: Random(120)),
    ),
    provider<JWTSigner>(
      (context) => JWTSigner(
        () => context.read<AuthenticationSecretsRepository>().jwtSecret,
        issuer: 'accounting.vhcblade.com',
      ),
    ),
    provider<DatabaseRepository>((context) => _fakeDatabase),
    provider<EventEnvironment>((context) => const EventEnvironment()),
    provider<ResponseErrorBuilder>((context) => ResponseErrorBuilder()),
    provider<AuthenticatedResponseBuilder>(
      (context) => AuthenticatedResponseBuilder(),
    ),
  ],
);

Handler _createHandler(
  UserModel saved, [
  Duration duration = const Duration(hours: 2),
]) {
  return providerStack.use((context) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await context.userDatabase.saveModel(
      saved,
    );
    final model = context.read<UserModel>();
    if (model.id != null) {
      context = RequestRequestContextDecorator(
        context.request.copyWith(
          headers: <String, String>{
            ...context.request.headers,
          }..authorization = await context
              .read<JWTSigner>()
              .createToken(BaseJWT.fromUserModel(model)..expiry = duration),
        ),
        context,
      );
    }
    final builder = context.authenticatedResponseBuilder;

    return context.responseBuilder.createSafeResponse(
      context,
      (context) => builder.createAuthenticatedResponse(
        context,
        (p0) => Response(body: 'Cool'),
      ),
    );
  });
}

Future<void> refreshedAuthenticationTest() async {
  final saved = UserModel()
    ..roles = (JWTRole()..roles = ['amazing'])
    ..idSuffix = 'saved';
  final handler = _createHandler(saved);

  final token = (await handler.use(provider<UserModel>((_) => saved))(
    _MockRequestContext(),
  ))
      .headers
      .authorization;
  final jwt = BaseJWT.fromToken(token!);

  final token2 = (await handler.use(provider<UserModel>((_) => saved))(
    _MockRequestContext(),
  ))
      .headers
      .authorization;
  final jwt2 = BaseJWT.fromToken(token2!);

  final token3 = (await _createHandler(saved, const Duration(days: 100000))
          .use(provider<UserModel>((_) => saved))(
    _MockRequestContext(),
  ))
      .headers
      .authorization;
  final jwt3 = BaseJWT.fromToken(token3!);

  expect(
    jwt.dateIssued,
    (DateTime issued) => issued != jwt2.dateIssued,
  );

  expect(
    jwt3.dateIssued,
    (DateTime issued) => issued != jwt2.dateIssued,
  );

  expect(
    jwt3.dateIssued,
    (DateTime issued) => issued != jwt.dateIssued,
  );

  expect(
    (await handler.use(provider<UserModel>((_) => UserModel()))(
      _MockRequestContext(),
    ))
        .headers
        .authorization,
    null,
  );
}

Future<void> createAuthenticatedResponseTest() async {
  final saved = UserModel()
    ..roles = (JWTRole()..roles = ['amazing'])
    ..idSuffix = 'saved';
  final unsaved = UserModel()
    ..idSuffix = 'unsaved'
    ..roles = (JWTRole()..roles = ['amazing']);
  final handler = _createHandler(saved);

  expect(
    await (await handler.use(provider<UserModel>((_) => UserModel()))(
      _MockRequestContext(),
    ))
        .body(),
    await permissionResponse().body(),
  );

  expect(
    await (await handler.use(provider<UserModel>((_) => saved))(
      _MockRequestContext(),
    ))
        .body(),
    'Cool',
  );

  expect(
    await (await handler.use(provider<UserModel>((_) => unsaved))(
      _MockRequestContext(),
    ))
        .body(),
    await permissionResponse().body(),
  );

  expect(
    await (await handler.use(
      provider<UserModel>(
        (_) => UserModel()
          ..copy(saved)
          ..roles = (JWTRole()..roles = ['superuser']),
      ),
    )(
      _MockRequestContext(),
    ))
        .body(),
    await permissionResponse().body(),
  );

  expect(
    await (await handler.use(
      provider<UserModel>(
        (_) => UserModel()
          ..copy(saved)
          ..roles = (JWTRole()..roles = []),
      ),
    )(
      _MockRequestContext(),
    ))
        .body(),
    'Cool',
  );
}
