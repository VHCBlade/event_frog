import 'dart:math';

import 'package:dart_frog/dart_frog.dart';
import 'package:event_authentication/event_authenticator_db.dart';
import 'package:event_bloc_tester/event_bloc_tester.dart';
import 'package:event_db/event_db.dart';
import 'package:event_frog/event_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'test_cases.dart';

class _FakeRequestContext extends Fake implements RequestContext {
  _FakeRequestContext(this.request);

  @override
  final Request request;

  bool initialized = false;
  late final Map<Type, dynamic> _readMap;

  Map<Type, dynamic> get _read {
    if (initialized) {
      return _readMap;
    }
    initialized = true;
    return _readMap = {
      ResponseErrorBuilder: ResponseErrorBuilder(),
      EventEnvironment: const EventEnvironment(),
      DatabaseRepository: FakeDatabaseRepository(
        constructors: {
          UserModel: UserModel.new,
          UserAuthentication: UserAuthentication.new,
        },
      ),
      JWTSigner: JWTSigner(
        () => read<AuthenticationSecretsRepository>().jwtSecret,
        issuer: 'accounting.vhcblade.com',
      ),
      AuthenticationSecretsRepository:
          FileSecretsRepository(secretsFile: 'test.txt', random: Random(120)),
    };
  }

  @override
  T read<T>() => _read[T] as T;
}

void main() {
  group('AuthenticatedResponseBuilder', () {
    group('emailLogin', emailLoginTest);
  });
  group('HeaderExtension', () {
    test('Authorization', () {
      final map = <String, Object>{}..authorization = 'myToken';
      expect(map.authorization, 'myToken');
      expect(map, {'Authorization': 'Bearer myToken'});
      map.authorization = null;

      expect(map.authorization, null);
      expect(map, <String, Object>{});

      map['Authorization'] = 'Amazing';
      expect(map.authorization, 'Amazing');
      expect(map, {'Authorization': 'Amazing'});
    });
  });
}

void emailLoginTest() {
  SerializableListTester<EmailLoginRequest?>(
    testGroupName: 'AuthenticatedResponseBuilder',
    mainTestName: 'emailLogin',
    mode: ListTesterMode.auto,
    testFunction: (value, tester) async {
      final context = _FakeRequestContext(
        Request(
          'POST',
          Uri.parse('https://example.com/login'),
          body: value?.toJsonString() ?? '{}',
        ),
      );
      final authenticator = await context.databaseUserAuthenticator;
      final model = UserModel()
        ..idSuffix = 'amazing'
        ..email = 'full@example.com';
      await context.userDatabase.saveModel(model);
      await authenticator.saveUserAuthentication(model, 'password');

      try {
        final loginResult =
            await AuthenticatedResponseBuilder().emailLogin(context);
        tester
          ..addTestValue(loginResult.statusCode)
          ..addTestValue(await loginResult.body());

        final auth = loginResult.headers.authorization;
        if (auth == null) {
          tester.addTestValue('No JWT!');
        } else {
          final jwt = BaseJWT.fromToken(auth);
          tester.addTestValue(jwt.expiry.inMinutes);
        }
      } on FormatException {
        tester.addTestValue('Format Failed');
        // ignore: avoid_catching_errors
      } on TypeError {
        tester.addTestValue('Type Failed');
      }

      await context.read<AuthenticationSecretsRepository>().clearSecrets();
    },
    testMap: emailLoginRequestTestCases,
  ).runTests();
}
