import 'package:fluster/fluster.dart';
import 'package:mapkit_lite_extension/entity/listeners.dart';
import 'package:uuid/v4.dart' show UuidV4;
import 'package:yandex_mapkit_lite/yandex_mapkit_lite.dart';

class BaseMapObject {
  BaseMapObject({required this.latLng, String? id, this.zIndex = .0, this.onTap})
      : id = id ?? const UuidV4().generate();

  final String id;
  final ({double latitude, double longitude}) latLng;
  final double zIndex;
  final MapObjectTapListener? onTap;

  @override
  int get hashCode => Object.hash(runtimeType, id, latLng);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseMapObject && runtimeType == other.runtimeType && id == other.id && latLng == other.latLng;
}

class PlacemarkObject extends BaseMapObject {
  PlacemarkObject({required super.latLng, required this.icon, super.id, super.zIndex, super.onTap, this.userData});

  final PlacemarkIcon icon;
  final Object? userData;

  PlacemarkMapObject toObject({MapObjectTapListener? onTap}) => PlacemarkMapObject(
        mapId: MapObjectId(id),
        point: latLng.toObject(),
        opacity: 1,
        icon: icon,
        consumeTapEvents: true,
        zIndex: zIndex,
        onTap: (mapObject, point) {
          onTap?.call(this, point);
          this.onTap?.call(this, point);
        },
      );

  PlacemarkObject copyWith({
    ({double latitude, double longitude})? latLng,
    PlacemarkIcon? icon,
    Object? userData,
    MapObjectTapListener? onTap,
  }) =>
      PlacemarkObject(
        id: id,
        latLng: latLng ?? this.latLng,
        icon: icon ?? this.icon,
        onTap: onTap ?? this.onTap,
        userData: userData ?? this.userData,
      );
}

class ClusterableMapObject extends Clusterable {
  ClusterableMapObject({
    required super.latitude,
    required super.longitude,
    required super.childMarkerId,
    required super.clusterId,
    required super.isCluster,
    required super.markerId,
    required super.pointsSize,
  });

  factory ClusterableMapObject.fromPoint(PlacemarkObject placemarker) => ClusterableMapObject(
        latitude: placemarker.latLng.latitude,
        longitude: placemarker.latLng.longitude,
        isCluster: null,
        markerId: placemarker.id,
        clusterId: null,
        childMarkerId: null,
        pointsSize: null,
      );

  ({double latitude, double longitude})? get location {
    if (latitude == null || longitude == null) return null;

    return (latitude: latitude!, longitude: longitude!);
  }

  @override
  int get hashCode => Object.hash(runtimeType, location, childMarkerId, clusterId, isCluster, markerId, pointsSize);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClusterableMapObject &&
          runtimeType == other.runtimeType &&
          location == other.location &&
          childMarkerId == other.childMarkerId &&
          clusterId == other.clusterId &&
          isCluster == other.isCluster &&
          markerId == other.markerId &&
          pointsSize == other.pointsSize;
}

extension PointRecordExtension on ({double latitude, double longitude}) {
  Point toObject() => Point(latitude: latitude, longitude: longitude);
}
