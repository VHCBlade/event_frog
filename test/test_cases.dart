import 'package:dart_frog/dart_frog.dart';
import 'package:event_authentication/event_authentication.dart';
import 'package:event_db/event_db.dart';

import 'test_models.dart';

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
