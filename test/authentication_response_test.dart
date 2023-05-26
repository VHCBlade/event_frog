import 'package:event_frog/event_frog.dart';
import 'package:test/test.dart';

void main() {
  group('HeaderExtension', () {
    test('Authorization', () {
      final map = <String, Object>{}..authorization = 'myToken';
      expect(map.authorization, 'myToken');
      expect(map, {'Authorization': 'Bearer myToken'});
      map.authorization = null;

      expect(map.authorization, null);
      expect(map, {});

      map['Authorization'] = 'Amazing';
      expect(map.authorization, 'Amazing');
      expect(map, {'Authorization': 'Amazing'});
    });
  });
}
