import 'dart:io';

import 'package:event_db/event_db.dart';
import 'package:event_frog/event_frog.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

void main() {
  group('SecretsOrigin', () {
    test('File', () async {
      final fileSecrets = FileSecretsOrigin<ExampleSecrets>(
        'test_input/example.secret',
        ExampleSecrets.new,
      );

      await fileSecrets.registerSecrets(
        ExampleSecrets()
          ..number = 1245
          ..secrets = 'Being Cool',
      );
      final secrets = await fileSecrets.secrets;
      expect(secrets.number, 1245);
      expect(secrets.secrets, 'Being Cool');
      final secrets2 = await fileSecrets.secrets;
      expect(secrets2.number, 1245);
      expect(secrets2.secrets, 'Being Cool');

      await fileSecrets.clearSecrets();
      await fileSecrets.clearSecrets();

      expect(
        () async => await fileSecrets.secrets,
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}

class ExampleSecrets extends GenericModel {
  late String secrets;
  late int number;

  @override
  Map<String, Tuple2<Getter<dynamic>, Setter<dynamic>>> getGetterSetterMap() =>
      {
        'secrets':
            GenericModel.primitive(() => secrets, (value) => secrets = value!),
        'number': GenericModel.number(
          () => number,
          (value) => number = value!.toInt(),
        ),
      };

  @override
  String get type => 'ExampleSecrets';
}
