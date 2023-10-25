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
          EventMiddleware.safeResponse,
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
            (context) => const AuthenticatedResponseBuilder(),
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
    test('permissionChecker', () async {
      final model = UserModel()
        ..idSuffix = 'amazing'
        ..roles = (JWTRole()..roles = ['cool']);
      _fakeDatabase.saveModel('Users', model);
      final middlewares = [
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
          (context) => const AuthenticatedResponseBuilder(),
        ),
        EventMiddleware.safeResponse,
      ];

      expect(
        await (await EventFrogMiddlewareStack([
          ...middlewares,
          EventMiddleware.permissionLevel(RolePermissionChecker(['amazing'])),
        ])
                .use((context) => Response())
                .use(provider<BaseJWT>((_) => BaseJWT.fromUserModel(model)))(
          _MockRequestContext(),
        ))
            .body(),
        await notFoundResponse().body(),
      );

      expect(
        await (await EventFrogMiddlewareStack([
          ...middlewares,
          EventMiddleware.permissionLevel(
            RolePermissionChecker(['amazing']),
            hideError: false,
          ),
        ])
                .use((context) => Response())
                .use(provider<BaseJWT>((_) => BaseJWT.fromUserModel(model)))(
          _MockRequestContext(),
        ))
            .body(),
        await permissionResponse().body(),
      );
      model.roles = JWTRole()..roles = ['amazing'];
      _fakeDatabase.saveModel('Users', model);

      expect(
        await (await EventFrogMiddlewareStack([
          ...middlewares,
          EventMiddleware.permissionLevel(RolePermissionChecker(['amazing'])),
        ]).use((context) => Response(body: 'Cool')).use(
                  provider<BaseJWT>(
                    (_) => BaseJWT.fromUserModel(model),
                  ),
                )(
          _MockRequestContext(),
        ))
            .body(),
        'Cool',
      );
    });
  });
}
