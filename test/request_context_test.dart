import 'package:dart_frog/dart_frog.dart';
import 'package:event_authentication/event_authentication.dart';
import 'package:event_bloc_tester/event_bloc_tester.dart';
import 'package:event_frog/event_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'test_cases.dart';
import 'test_models.dart';

class _MockRequestContext extends Mock implements RequestContext {
  final _request = {
    ResponseErrorBuilder: ResponseErrorBuilder(),
    EventEnvironment: const EventEnvironment(),
  };
  @override
  T read<T>() => _request[T] as T;
}

void main() {
  group('ModelRequest', () {
    group('bodyAsModel', bodyAsModelTest);
  });
  group('ResponseBuilderContext', () {
    test('ResponseErrorBuilder', () async {
      final context = _MockRequestContext();
      expect(
        await (await context.responseBuilder.createSafeResponse(
          context,
          (p0) => Response(body: 'Cool'),
        ))
            .body(),
        'Cool',
      );
    });
    test('isDevelopmentMode', () async {
      final context = _MockRequestContext();
      expect(context.isDevelopmentMode, true);
    });
    test('environment', () async {
      final context = _MockRequestContext();
      expect(context.environment.userDatabaseName, 'Users');
      expect(context.environment.authenticationDatabaseName, 'authentication');
    });
    test('userDatabase', () async {
      final context = _MockRequestContext();
      expect(context.userDatabase.databaseName, 'Users');
    });
  });
}

void bodyAsModelTest() {
  SerializableListTester<Request>(
    testGroupName: 'ModelRequest',
    mainTestName: 'bodyAsModel',
    mode: ListTesterMode.auto,
    testFunction: (value, tester) async {
      final types = [
        ExampleModel.new,
        BaseJWT.new,
        EmailLoginRequest.new,
        JWTRole.new
      ];
      for (final type in types) {
        try {
          tester.addTestValue((await value.bodyAsModel(type)).toMap());
          // ignore: avoid_catching_errors
        } on ArgumentError {
          tester.addTestValue('Invalid!');
        } on FormatException {
          tester.addTestValue('Invalid!');
        }
      }
    },
    testMap: requestTestCases,
  ).runTests();
}
