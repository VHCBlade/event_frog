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

final _fakeDatabase = FakeDatabaseRepository(
  constructors: {
    UserModel: UserModel.new,
    UserAuthentication: UserAuthentication.new,
  },
);
void main() {
  group('EventMiddleware', () {
    test('safeResponse', () async {
      final stack = EventFrogMiddlewareStack(
        [
          provider<EventEnvironment>((context) => const EventEnvironment()),
          provider<ResponseErrorBuilder>((context) => ResponseErrorBuilder()),
          EventMiddleware.safeResponse
        ],
      );

      expect(
        await (await stack
                .use((context) => throw PermissionException())
                .use(provider<UserModel>((_) => UserModel()))(
          _MockRequestContext(),
        ))
            .body(),
        await permissionResponse().body(),
      );
    });
    test('authenticatedResponse', () async {
      final stack = EventFrogMiddlewareStack(
        [
          provider<AuthenticationSecretsRepository>(
            (context) => FileSecretsRepository(
              secretsFile: 'test.txt',
              random: Random(120),
            ),
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
          EventMiddleware.safeResponse,
          EventMiddleware.authenticatedResponse,
        ],
      );

      expect(
        await (await stack
                .use((context) => Response())
                .use(provider<UserModel>((_) => UserModel()))(
          _MockRequestContext(),
        ))
            .body(),
        await permissionResponse().body(),
      );
    });
  });
}
