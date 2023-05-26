import 'package:dart_frog/dart_frog.dart';
import 'package:event_authentication/event_authentication.dart';
import 'package:event_bloc_tester/event_bloc_tester.dart';
import 'package:event_db/event_db.dart';
import 'package:event_frog/event_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'test_cases.dart';

class _MockRequestContext extends Mock implements RequestContext {
  final _request = {
    ResponseErrorBuilder: ResponseErrorBuilder(),
    EventEnvironment: const EventEnvironment(),
    DatabaseRepository:
        FakeDatabaseRepository(constructors: {UserModel: UserModel.new}),
  };
  @override
  T read<T>() => _request[T] as T;
}

void main() {
  group('Permission', () {
    group('Allow All', allowAllTest);
    group('Role', roleTest);
  });
}

void roleTest() {
  SerializableListTester<JWTRole>(
    testGroupName: 'Permission',
    mainTestName: 'Role',
    mode: ListTesterMode.auto,
    testFunction: (value, tester) async {
      final checker = RolePermissionChecker(value.roles);
      final roleList = <List<String>>[
        [superuserRole],
        ['regular'],
        [superuserRole, 'regular'],
        ['amazing'],
        ['absolute'],
        [],
      ];

      for (final roles in roleList) {
        final jwt = BaseJWT()..jwtRole = (JWTRole()..roles = roles);
        tester.addTestValue(roles);
        try {
          checker.assertPermission(_MockRequestContext(), jwt);
          tester.addTestValue('Allowed');
        } on NotFoundException {
          tester.addTestValue('Not Found');
        } on PermissionException {
          tester.addTestValue('Failed');
        }
        try {
          checker.assertPermission(_MockRequestContext(), jwt, hideError: true);
          tester.addTestValue('Allowed');
        } on NotFoundException {
          tester.addTestValue('Not Found');
        } on PermissionException {
          tester.addTestValue('Failed');
        }
      }
    },
    testMap: roleTestCases,
  ).runTests();
}

void allowAllTest() {
  SerializableListTester<JWTRole>(
    testGroupName: 'Permission',
    mainTestName: 'Allow All',
    mode: ListTesterMode.auto,
    testFunction: (value, tester) async {
      final checker = AllowAllPermissionChecker();
      expect(
        checker.checkPermission(
          _MockRequestContext(),
          BaseJWT()..jwtRole = value,
        ),
        true,
      );
    },
    testMap: roleTestCases,
  ).runTests();
}
