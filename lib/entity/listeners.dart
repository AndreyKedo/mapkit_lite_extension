import 'dart:async';

import 'package:mapkit_lite_extension/entity/map_object.dart';
import 'package:yandex_mapkit_lite/yandex_mapkit_lite.dart' as map_kit;

typedef MapObjectTapListener = void Function(BaseMapObject object, map_kit.Point point);

abstract interface class ClusterListener {
  FutureOr<map_kit.PlacemarkMapObject> onAddCluster(ClusterableMapObject cluster);
}
