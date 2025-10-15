import 'dart:async';

import 'package:mapkit_lite_extension/entity/map_object.dart';
import 'package:yandex_mapkit_lite/yandex_mapkit_lite.dart';

typedef MapObjectTapListener = void Function(BaseMapObject object, Point point);

abstract interface class ClusterListener {
  FutureOr<PlacemarkMapObject> onAddCluster(ClusterableMapObject cluster);
}
