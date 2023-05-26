import 'package:dart_frog/dart_frog.dart';
import 'package:event_authentication/event_authentication.dart';
import 'package:event_frog/event_frog.dart';

/// Represents an exception when some permission level is not met.
class PermissionException implements EventFrogException {}

/// Represents an exception where nothing appropriate was found.
class NotFoundException implements EventFrogException {}

/// This allows you to perform permission checks on user's JWTs
abstract class PermissionChecker {
  /// Checks if the given [baseJWT] is allowed.
  bool checkPermission(RequestContext context, BaseJWT baseJWT);

  /// Throws an error if a [checkPermission] call with [context] and [baseJWT]
  /// would return false.
  ///
  /// If [hideError] is true, a [NotFoundException] will be thrown instead of a
  /// [PermissionException]
  void assertPermission(
    RequestContext context,
    BaseJWT baseJWT, {
    bool hideError = false,
  }) {
    if (!checkPermission(context, baseJWT)) {
      throw hideError ? NotFoundException() : PermissionException();
    }
  }
}

/// The superuser role
const superuserRole = 'superuser';

/// Implementation of [PermissionChecker] that will always return true.
class AllowAllPermissionChecker extends PermissionChecker {
  @override
  bool checkPermission(RequestContext context, BaseJWT baseJWT) {
    return true;
  }
}

/// A [PermissionChecker] that does a hard role check to see if a [BaseJWT] is
/// allowed.
class RolePermissionChecker extends PermissionChecker {
  /// [allowedRoles] represents all of the roles that are allowed for
  /// [checkPermission]. This will always implicitly accept [superuserRole]
  RolePermissionChecker(this.allowedRoles);

  /// All of the allowed roles for this permission checker
  final List<String> allowedRoles;

  @override
  bool checkPermission(RequestContext context, BaseJWT baseJWT) {
    return baseJWT.jwtRole.containsAnyRoles([...allowedRoles, superuserRole]);
  }
}
