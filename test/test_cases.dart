import 'package:dart_frog/dart_frog.dart';
import 'package:event_authentication/event_authentication.dart';
import 'package:event_db/event_db.dart';
import 'package:event_frog/event_frog.dart';

import 'test_models.dart';

Map<String, JWTRole Function()> get roleTestCases => {
      'Superuser': () => JWTRole()..roles = [superuserRole],
      'Empty': () => JWTRole()..roles = [],
      'Regular': () => JWTRole()..roles = ['regular'],
      'Superuser and Reqular': () =>
          JWTRole()..roles = ['regular', superuserRole],
    };

Map<String, EmailLoginRequest? Function()> get emailLoginRequestTestCases => {
      'Null': () => null,
      'Full Request': () => EmailLoginRequest()
        ..email = 'full@example.com'
        ..password = 'password',
      'No Expiry Request': () => EmailLoginRequest()
        ..email = 'full@example.com'
        ..password = 'password'
        ..noExpiry = true,
      'Failed Password Request': () => EmailLoginRequest()
        ..email = 'full@example.com'
        ..password = 'failed'
        ..noExpiry = true,
      'Failed Email Request': () => EmailLoginRequest()
        ..email = 'lost@example.com'
        ..password = 'password'
        ..noExpiry = true,
    };

Map<String, Request Function()> get requestTestCases => {
      'Example Model': () => Request.post(
            Uri.parse('https://example.com/a'),
            body: (ExampleModel()
                  ..s = 'Amazing'
                  ..i = 120)
                .toJsonString(),
          ),
      'BaseJWT Model': () => Request.post(
            Uri.parse('https://example.com/a'),
            body: (BaseJWT()
                  ..expiry = const Duration(days: 20)
                  ..dateIssued = DateTime(2012)
                  ..jwtRole = (JWTRole()
                    ..roles = [
                      'Great',
                      'Cool',
                    ]))
                .toJsonString(),
          ),
      'EmailLoginRequest Model': () => Request.post(
            Uri.parse('https://example.com/a'),
            body: (EmailLoginRequest()
                  ..email = 'email@example.com'
                  ..noExpiry = true
                  ..password = 'example')
                .toJsonString(),
          ),
      'Failed Model': () => Request.post(
            Uri.parse('https://example.com/a'),
            body: 'abcdefghijklmnopqrstuvwxyz',
          ),
    };
