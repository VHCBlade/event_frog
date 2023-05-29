import 'dart:math';

import 'package:dart_frog/dart_frog.dart';
import 'package:event_authentication/event_authenticator_db.dart';
import 'package:event_db/event_db.dart';
import 'package:event_frog/event_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRequestContext extends Mock implements RequestContext {
  @override
  final Request request = Request('POST', Uri.parse('https://example.com/a'));
}

class RequestRequestContextDecorator implements RequestContext {
  RequestRequestContextDecorator(this.request, this.requestContext);
  RequestContext requestContext;

  @override
  final Request request;

  @override
  RequestContext provide<T extends Object>(T Function() create) {
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

Future<void> createAuthenticatedResponseTest() async {
  final saved = UserModel()
    ..roles = (JWTRole()..roles = ['amazing'])
    ..idSuffix = 'saved';
  final unsaved = UserModel()
    ..idSuffix = 'unsaved'
    ..roles = (JWTRole()..roles = ['amazing']);
  final handler = providerStack.use((context) async {
    await context.userDatabase.saveModel(
      UserModel()
        ..roles = (JWTRole()..roles = ['amazing'])
        ..idSuffix = 'saved',
    );
    final model = context.read<UserModel>();
    if (model.id != null) {
      context = RequestRequestContextDecorator(
        context.request.copyWith(
          headers: <String, String>{
            ...context.request.headers,
          }..authorization = await context
              .read<JWTSigner>()
              .createToken(BaseJWT.fromUserModel(model)),
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
