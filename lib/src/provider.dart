import 'package:dart_frog/dart_frog.dart';

/// Transforms a list of [Middleware]s into the single [Middleware] by calling
/// them sequentially.
///
/// This calls it in reverse order so that the more intuitive order is used. IE
/// The earlier [Middleware]s are applied for the later [Middleware]s
class EventFrogMiddlewareStack {
  /// [middlewares] will be called sequentially to create a single [Middleware]
  /// in [use]
  EventFrogMiddlewareStack(this.middlewares);

  /// called sequentially to create a single [Middleware] in [use]
  final List<Middleware> middlewares;

  /// Sequentiall calls [Middleware]s in [middlewares] to be used by the
  /// [handler] until a single [Handler] that has all the [Middleware].
  ///
  /// This calls [middlewares] in reverse order so that the more intuitive order
  /// is used. IE The earlier [Middleware]s are applied for the later
  /// [Middleware]s
  Handler use(Handler handler) {
    var currentHandler = handler;

    for (final middleware in middlewares.reversed) {
      currentHandler = currentHandler.use(middleware);
    }

    return currentHandler;
  }
}
