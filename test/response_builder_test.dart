import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:event_authentication/event_authentication.dart';
import 'package:event_db/event_db.dart';
import 'package:event_frog/event_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'test_models.dart';

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  group('ResponseErrorBuilder', () {
    group('createSafeResponse', () {
      test('Expected', () async {
        expect(
          await (await ResponseErrorBuilder().createSafeResponse(
            _MockRequestContext(),
            (p0) => Response(body: 'Cool'),
          ))
              .body(),
          await Response(body: 'Cool').body(),
        );
        expect(
          await (await ResponseErrorBuilder().createSafeResponse(
            _MockRequestContext(),
            (p0) => notFoundResponse(),
          ))
              .body(),
          await notFoundResponse().body(),
        );
      });
      test('Cast Error', () async {
        expect(
          await (await ResponseErrorBuilder().createSafeResponse(
            _MockRequestContext(),
            (p0) => Response(
              body: '${(ExampleModel()..loadFromMap({})).toMap()}',
            ),
          ))
              .body(),
          await syntaxErrorResponse().body(),
        );
        expect(
          await (await ResponseErrorBuilder().createSafeResponse(
            _MockRequestContext(),
            (p0) => Response(
              body: '${json.decode('')}',
            ),
          ))
              .body(),
          await syntaxErrorResponse().body(),
        );
        expect(
          await (await ResponseErrorBuilder().createSafeResponse(
            _MockRequestContext(),
            (p0) => Response(
              body: '${json.decode('{')}',
            ),
          ))
              .body(),
          await syntaxErrorResponse().body(),
        );
      });
    });
    test('Default Response', () async {
      expect(
        await (await ResponseErrorBuilder().createSafeResponse(
          _MockRequestContext(),
          (p0) => throw ArgumentError(),
        ))
            .body(),
        await unexpectedErrorResponse().body(),
      );
      expect(
        await (await ResponseErrorBuilder().createSafeResponse(
          _MockRequestContext(),
          (p0) => throw ArgumentError(),
          defaultResponse: loginFailResponse,
        ))
            .body(),
        await loginFailResponse().body(),
      );
    });
    test('Unexpected Response', () async {
      var i = 0;
      expect(
        await (await ResponseErrorBuilder(
          logger: (e) {
            expect(e, isArgumentError);
            i++;
          },
        ).createSafeResponse(
          _MockRequestContext(),
          (p0) => throw ArgumentError(),
        ))
            .body(),
        await unexpectedErrorResponse().body(),
      );
      expect(i, 1);
    });
    test('JWT Exception', () async {
      expect(
        await (await ResponseErrorBuilder().createSafeResponse(
          _MockRequestContext(),
          (p0) => throw EventJWTExpiredException(),
        ))
            .body(),
        await invalidJWTResponse().body(),
      );
      expect(
        await (await ResponseErrorBuilder().createSafeResponse(
          _MockRequestContext(),
          (p0) => throw EventJWTInvalidException('Invalid!'),
          defaultResponse: loginFailResponse,
        ))
            .body(),
        await invalidJWTResponse().body(),
      );
    });
    test('Permission Exception', () async {
      expect(
        await (await ResponseErrorBuilder().createSafeResponse(
          _MockRequestContext(),
          (p0) => throw PermissionException(),
        ))
            .body(),
        await permissionResponse().body(),
      );
      expect(
        await (await ResponseErrorBuilder().createSafeResponse(
          _MockRequestContext(),
          (p0) => throw NotFoundException(),
          defaultResponse: loginFailResponse,
        ))
            .body(),
        await notFoundResponse().body(),
      );
    });
    test('Logger', () async {
      var i = 0;
      await ResponseErrorBuilder(
        logger: (event) {
          expect(event, isArgumentError);
          i++;
        },
        logAllErrors: false,
      ).createSafeResponse(
        _MockRequestContext(),
        (p0) => throw ArgumentError(),
      );
      await ResponseErrorBuilder(
        logger: (event) {
          expect(event, isArgumentError);
          i++;
        },
        logAllErrors: true,
      ).createSafeResponse(
        _MockRequestContext(),
        (p0) => throw ArgumentError(),
      );
      expect(i, 2);
      await ResponseErrorBuilder(
        logger: (event) {
          expect(event, isA<PermissionException>());
          i++;
        },
        logAllErrors: false,
      ).createSafeResponse(
        _MockRequestContext(),
        (p0) => throw PermissionException(),
      );
      await ResponseErrorBuilder(
        logger: (event) {
          expect(event, isA<PermissionException>());
          i++;
        },
        logAllErrors: true,
      ).createSafeResponse(
        _MockRequestContext(),
        (p0) => throw PermissionException(),
      );
      expect(i, 3);
    });
    test('Logger StackTrace', () async {
      var i = 0;
      await ResponseErrorBuilder(
        logger: (event) => i++,
        logAllErrors: false,
        logStackTrace: true,
      ).createSafeResponse(
        _MockRequestContext(),
        (p0) => throw ArgumentError(),
      );
      await ResponseErrorBuilder(
        logger: (event) => i++,
        logAllErrors: true,
        logStackTrace: true,
      ).createSafeResponse(
        _MockRequestContext(),
        (p0) => throw ArgumentError(),
      );
      expect(i, 4);
      await ResponseErrorBuilder(
        logger: (event) => i++,
        logAllErrors: false,
        logStackTrace: true,
      ).createSafeResponse(
        _MockRequestContext(),
        (p0) => throw PermissionException(),
      );
      await ResponseErrorBuilder(
        logger: (event) => i++,
        logAllErrors: true,
        logStackTrace: true,
      ).createSafeResponse(
        _MockRequestContext(),
        (p0) => throw PermissionException(),
      );
      expect(i, 6);
    });
    test('Validation Exception', () async {
      expect(
        await (await ResponseErrorBuilder().createSafeResponse(
          _MockRequestContext(),
          (p0) => throw const ValidationException('cool', 'Amazing'),
        ))
            .body(),
        await validationExceptionResponse(
          const ValidationException('cool', 'Amazing'),
        ).body(),
      );
      expect(
        await (await ResponseErrorBuilder().createSafeResponse(
          _MockRequestContext(),
          (p0) => throw const ValidationCollectionException(
            [
              ValidationException('cool', 'Amazing'),
              ValidationException('Incredible', 'Astounding'),
            ],
          ),
          defaultResponse: loginFailResponse,
        ))
            .body(),
        await validationCollectionExceptionResponse(
          const ValidationCollectionException(
            [
              ValidationException('cool', 'Amazing'),
              ValidationException('Incredible', 'Astounding'),
            ],
          ),
        ).body(),
      );
    });
  });
}
