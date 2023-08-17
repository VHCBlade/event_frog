import 'package:dart_frog/dart_frog.dart';
import 'package:event_frog/event_frog.dart';
import 'package:test/test.dart';

void main() {
  group('EventFrogMiddlewareStack', () {
    group('use', () {
      test('provides', () async {
        final providerStack = EventFrogMiddlewareStack(
          [
            provider<String>((context) => 'Amazing'),
            provider<int>((context) => context.read<String>().length),
            provider<bool>((context) => context.read<int>().isEven),
            provider<String>((context) => 'Cool'),
          ],
        );

        final handler = providerStack.use((context) {
          var value = '${context.read<int>()}';
          value += '${context.read<bool>()}';
          value += context.read<String>();
          return Response(body: value);
        });

        final response = await handler(TestRequestContext());

        expect(await response.body(), '7falseCool');
      });
    });
  });
}
