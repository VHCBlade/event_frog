import 'package:event_db/event_db.dart';
import 'package:tuple/tuple.dart';

class ExampleModel extends GenericModel {
  late final String s;
  late final int i;

  @override
  Map<String, Tuple2<Getter<dynamic>, Setter<dynamic>>> getGetterSetterMap() =>
      {
        's': Tuple2(() => s, (val) => s = val as String),
        'i': Tuple2(() => i, (val) => i = val as int),
      };

  @override
  String get type => 'Example';
}
