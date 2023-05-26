import 'package:dart_frog/dart_frog.dart';
import 'package:event_authentication/event_authenticator_db.dart';
import 'package:event_db/event_db.dart';
import 'package:event_frog/event_frog.dart';

/// Adds functions to make it easier to make responses to [RequestContext]
extension ResponseBuilderContext on RequestContext {
  /// Returns the closest [ResponseErrorBuilder]
  ResponseErrorBuilder get responseBuilder => read<ResponseErrorBuilder>();

  /// Convenience function to check if the current server is made for a dev
  /// environment or a production environment.
  bool get isDevelopmentMode =>
      const bool.fromEnvironment('dart.vm.product') == false;

  /// Holds variables that controls settings for event_frog
  EventEnvironment get environment => read<EventEnvironment>();

  /// Generates the [DatabaseUserAuthenticator] using [environment] and the
  /// provided [AuthenticationSecretsRepository] and [DatabaseRepository]
  Future<DatabaseUserAuthenticator> get databaseUserAuthenticator async {
    final secrets = read<AuthenticationSecretsRepository>();
    final database = read<DatabaseRepository>();

    return DatabaseUserAuthenticator(
      database: database,
      authenticationDatabase: environment.authenticationDatabaseName,
      authenticationGenerator: await secrets.generator,
      secretsRepository: secrets,
    );
  }

  /// The database for the [UserModel]s
  SpecificDatabase get userDatabase => SpecificDatabase(
        read<DatabaseRepository>(),
        environment.userDatabaseName,
      );
}

/// Adds integration function with event_db and event_authentication
extension ModelRequest on Request {
  /// Retrieves the [body] of this request as a [T]. Will throw a [TypeError] or
  /// [FormatException] if the [body] doesn't conform to the format expected by
  /// [T]
  Future<T> bodyAsModel<T extends GenericModel>(T Function() supplier) async {
    final myBody = await body();
    return supplier()..loadFromJsonString(myBody);
  }
}
