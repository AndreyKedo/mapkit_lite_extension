import 'dart:collection';

import 'package:fluster/fluster.dart';
import 'package:flutter/foundation.dart' as framework show ChangeNotifier, listEquals;
import 'package:mapkit_lite_extension/entity/listeners.dart';
import 'package:mapkit_lite_extension/entity/map_object.dart';
import 'package:mapkit_lite_extension/controller/controller.dart';
import 'package:uuid/v4.dart';

import 'package:yandex_mapkit_lite/yandex_mapkit_lite.dart';

abstract class ListenableMapObjectCollection extends framework.ChangeNotifier with Controller {
  ListenableMapObjectCollection(this.id);

  final String id;

  Iterable<MapObject<Object?>> get children;
}

/// Map objects collection.
class ExtendedMapObjectCollection extends ListenableMapObjectCollection {
  ExtendedMapObjectCollection(super.id);

  final _objects = <BaseMapObject, PlacemarkMapObject>{};

  final _innerCollection = <String, ListenableMapObjectCollection>{};

  /// Children collections.
  Iterable<ListenableMapObjectCollection> get collections => _innerCollection.values;

  @override
  Iterable<MapObject<Object?>> get children => <MapObject>[
        MapObjectCollection(mapId: MapObjectId(id), mapObjects: UnmodifiableListView(_objects.values)),
        for (final object in _innerCollection.values)
          MapObjectCollection(mapId: MapObjectId(object.id), mapObjects: UnmodifiableListView(object.children))
      ];

  /// Creates a point cluster. Returns a [ExtendedClusteredMapObjectCollection] for interactions with the cluster.
  ///
  /// * [listener] - the callbacks for creation map objects.
  /// * [options] - the setup cluster options.
  ExtendedClusteredMapObjectCollection addPlacemarkCollection(
    ClusterListener listener, {
    ClusterOptions options = const ClusterOptions(),
  }) {
    final cluster = ExtendedClusteredMapObjectCollection(const UuidV4().generate(), WeakReference(listener), options);

    cluster.addListener(notifyListeners);

    return _innerCollection[cluster.id] = cluster;
  }

  /// Add placemark.
  void addPlacemark(PlacemarkObject object) {
    _objects[object] = object.toObject();

    notifyListeners();
  }

  /// Remove map object
  void removeMapObject(String id) {
    _objects.removeWhere((entry, _) => entry.id == id);
    notifyListeners();
  }

  void addCollection(ListenableMapObjectCollection collection) {
    _innerCollection[collection.id] = collection;

    collection.addListener(notifyListeners);

    notifyListeners();
  }

  /// Remove child collection by [id].
  void removeCollection(String id) {
    final collection = _innerCollection.remove(id);

    collection?.removeListener(notifyListeners);
    collection?.dispose();

    notifyListeners();
  }

  @override
  void dispose() {
    for (final entry in _innerCollection.values) {
      entry.removeListener(notifyListeners);
      entry.dispose();
    }
    _innerCollection.clear();
    _objects.clear();
    super.dispose();
  }
}

/// Cluster options.
class ClusterOptions {
  /// Recommended cluster options.
  const ClusterOptions({
    this.minZoom = 0,
    this.maxZoom = 20,
    this.radius = 150,
    this.extent = 1024,
    this.nodeSize = 64,
  });

  /// Any zoom value below minZoom will not generate clusters.
  final int minZoom;

  /// Any zoom value above maxZoom will not generate clusters.
  final int maxZoom;

  /// Cluster radius in pixels.
  final int radius;

  /// Adjust the extent by powers of 2 (e.g. 512. 1024, ... max 8192) to get the
  /// desired distance between markers where they start to cluster.
  final int extent;

  /// The size of the KD-tree leaf node, which affects performance.
  final int nodeSize;
}

/// Clustered map objects collection.
class ExtendedClusteredMapObjectCollection extends ListenableMapObjectCollection {
  ExtendedClusteredMapObjectCollection(super.id, this.listener, this.options);

  final ClusterOptions options;
  final WeakReference<ClusterListener> listener;

  static const _viewExpandFactor = 30;
  static const _emptyObjectsCollection = <MapObject<Object?>>[];

  var _clusterableObjects = const <ClusterableMapObject>[];
  var _mapObjects = _emptyObjectsCollection;
  var _points = const <PlacemarkObject>{};

  Fluster<ClusterableMapObject>? _cluster;

  /// Listening for click gesture on cluster objects.
  MapObjectTapListener? onTapPlacemarkCallback;

  @override
  Iterable<MapObject<Object?>> get children => _mapObjects;

  /// add point
  void addPoints(Iterable<PlacemarkObject> points) {
    _points = Set.from(points);
    _cluster = Fluster<ClusterableMapObject>(
      minZoom: options.minZoom,
      maxZoom: options.maxZoom,
      radius: options.radius,
      extent: options.extent,
      nodeSize: options.nodeSize,
      points: _points.map(ClusterableMapObject.fromPoint).toList(growable: false),
      // ignore: avoid_types_on_closure_parameters
      createCluster: (BaseCluster? cluster, double? longitude, double? latitude) {
        return ClusterableMapObject(
          latitude: latitude,
          longitude: longitude,
          isCluster: true,
          clusterId: cluster?.id,
          pointsSize: cluster?.pointsSize,
          childMarkerId: cluster?.childMarkerId,
          markerId: cluster?.markerId,
        );
      },
    );
  }

  /// Update placemark.
  void updatePlacemark(BaseMapObject object) {
    if (_mapObjects.isEmpty) return;

    // Update placemark
    if (object is PlacemarkObject) {
      _mapObjects = List<MapObject>.generate(_mapObjects.length, (index) {
        final item = _mapObjects[index];
        if (item.mapId.value == object.id) {
          return object.toObject(onTap: onTapPlacemarkCallback);
        }
        return item;
      });
      _points.remove(object);
      _points.add(object);
      notifyListeners();
    }
  }

  /// Clean collection.
  void clean() {
    _points = const <PlacemarkObject>{};
    _clusterableObjects = const [];
    _mapObjects = _emptyObjectsCollection;
    _cluster = null;
    notifyListeners();
  }

  Future<void> attachCluster(VisibleRegion visibleRegion, CameraPosition cameraPosition) async {
    final zoom = cameraPosition.zoom;

    final clusterObjects = _cluster?.clusters([
      visibleRegion.bottomLeft.longitude - _viewExpandFactor,
      visibleRegion.bottomLeft.latitude - _viewExpandFactor,
      visibleRegion.topRight.longitude + _viewExpandFactor,
      visibleRegion.topRight.latitude + _viewExpandFactor,
    ], zoom.toInt());

    if (clusterObjects == null || framework.listEquals(clusterObjects, _clusterableObjects)) {
      return;
    }

    _clusterableObjects = clusterObjects;

    final objects = await Stream.fromIterable(clusterObjects.where((element) => element.location != null)).asyncExpand((
      cluster,
    ) async* {
      if (cluster.isCluster ?? false) {
        final clusterObj = await listener.target?.onAddCluster(cluster);
        if (clusterObj != null) {
          yield clusterObj;
        }
      } else {
        final placemark = _points.singleWhere((entry) => entry.id == cluster.markerId);

        yield placemark.toObject(onTap: onTapPlacemarkCallback);
      }
    }).toList();

    _mapObjects = List.generate(objects.length, objects.elementAt, growable: false);

    notifyListeners();
  }

  @override
  void dispose() {
    _points = const {};
    _clusterableObjects = const [];
    _mapObjects = _emptyObjectsCollection;
    _cluster = null;
    super.dispose();
  }
}
