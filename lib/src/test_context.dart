import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';

/// A Test [RequestContext] that provides a simple implementation for the
/// [RequestContext.read] and [RequestContext.provide]
class TestRequestContext extends Mock implements RequestContext {
  final _map = <Type, Object?>{};

  @override
  RequestContext provide<T extends Object?>(T Function() function) {
    _map[T] = function();
    return this;
  }

  @override
  T read<T extends Object?>() {
    return _map[T] as T;
  }
}
