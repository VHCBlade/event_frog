import 'package:event_authentication/event_authentication.dart';

/// Holds settings for how event frog will handle your database. You can change
/// this by modifying the constructor.
class EventEnvironment {
  /// You can set the environment variables by adding specific values in this
  /// constructor. For more information, see the documentation of each variable.
  const EventEnvironment({
    this.userDatabaseName = 'Users',
    this.authenticationDatabaseName = 'authentication',
    this.sessionLength = const Duration(hours: 2),
  });

  /// The database for the [UserModel]s
  final String userDatabaseName;

  /// The database for the [UserAuthentication]s
  final String authenticationDatabaseName;

  /// Describes the expiry session used when generating and updating JWTs
  final Duration sessionLength;
}
