import 'dart:async';

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
  FutureOr<bool> checkPermission(RequestContext context, BaseJWT baseJWT);

  /// Throws an error if a [checkPermission] call with [context] and [baseJWT]
  /// would return false.
  ///
  /// If [hideError] is true, a [NotFoundException] will be thrown instead of a
  /// [PermissionException]
  FutureOr<void> assertPermission(
    RequestContext context,
    BaseJWT baseJWT, {
    bool hideError = false,
  }) async {
    if (!await checkPermission(context, baseJWT)) {
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

/// A [PermissionChecker] that ensures that all roles in a list are present in a
/// provied [BaseJWT]
class AllRoleChecker extends PermissionChecker {
  /// [allRoles] represents all of the roles that are needed for
  /// [checkPermission].
  AllRoleChecker(this.allRoles);

  /// All of the roles that need to be present in the JWT to allow permission
  final Set<String> allRoles;

  @override
  bool checkPermission(RequestContext context, BaseJWT baseJWT) {
    return allRoles.containsAll(baseJWT.jwtRole.roles);
  }
}
