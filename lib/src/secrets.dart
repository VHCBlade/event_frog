import 'dart:async';
import 'dart:io';

import 'package:event_db/event_db.dart';

/// Provides a [T] that represents a secrets [GenericModel] from
/// a particular source based on the concrete implementation
abstract class SecretsOrigin<T extends GenericModel> {
  /// Loads the secrets from the source given by the implementation
  FutureOr<T> get secrets;
}

/// An additional interface for [SecretsOrigin] that is testable.
abstract class TestableSecretsOrigin<T extends GenericModel>
    extends SecretsOrigin<T> {
  /// Clears the current secrets, they'll need to reregistered using
  /// [registerSecrets]
  FutureOr<void> clearSecrets();

  /// Registers the secrets so that they can be loaded later.
  FutureOr<void> registerSecrets(T secrets);
}

/// Loads secrets from a file in the filesystem given by [secretsFile]
class FileSecretsOrigin<T extends GenericModel>
    extends TestableSecretsOrigin<T> {
  /// [secretsFile] is the file in the filesystem from where the secrets will
  /// be read.
  ///
  /// [supplier] creates a new instance of [T] for the secrets to be loaded into
  FileSecretsOrigin(this.secretsFile, this.supplier);

  /// the path to where the secrets file can be found and stored.
  final String secretsFile;

  /// creates a new instance of [T] for the secrets to be loaded into
  final T Function() supplier;

  @override
  FutureOr<void> clearSecrets() {
    try {
      File(secretsFile).deleteSync();
    } on FileSystemException {
      // just go on
    }
  }

  @override
  FutureOr<void> registerSecrets(T secrets) {
    File(secretsFile).writeAsStringSync(secrets.toJsonString());
  }

  @override
  FutureOr<T> get secrets {
    final file = File(secretsFile);

    return supplier()..loadFromJsonString(file.readAsStringSync());
  }
}
