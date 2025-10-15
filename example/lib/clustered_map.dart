import 'package:flutter/material.dart';
import 'package:mapkit_lite_extension/mapkit_lite_extension.dart';
import 'package:yandex_mapkit_lite/yandex_mapkit_lite.dart';

class ClusteredMapExample extends StatefulWidget {
  const ClusteredMapExample({super.key});

  @override
  State<ClusteredMapExample> createState() => _ClusteredMapExampleState();
}

class _ClusteredMapExampleState extends State<ClusteredMapExample> implements ClusterListener {
  late final ExtendedMapController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ExtendedMapController();

    // Создаем коллекцию для маркеров
    final collection = ExtendedMapObjectCollection('markers_collection');

    // Создаем кластер в коллекции
    final cluster = collection.addPlacemarkCollection(this);

    // Добавляем точки в кластер
    cluster.addPoints([
      PlacemarkObject(
        latLng: (latitude: 55.7558, longitude: 37.6173), // Москва
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage('assets/marker.png'),
            anchor: const Offset(0.5, 1),
          ),
        ),
      ),
      PlacemarkObject(
        latLng: (latitude: 59.9343, longitude: 30.3351), // Санкт-Петербург
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage('assets/marker.png'),
            anchor: const Offset(0.5, 1),
          ),
        ),
      ),
      PlacemarkObject(
        latLng: (latitude: 56.8280, longitude: 35.8980), // Тверь
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage('assets/marker.png'),
            anchor: const Offset(0.5, 1),
          ),
        ),
      ),
    ]);

    // Добавляем коллекцию в корневую коллекцию контроллера
    _controller.rootCollection.addCollection(collection);
  }

  @override
  Future<PlacemarkMapObject> onAddCluster(ClusterableMapObject cluster) async {
    return PlacemarkMapObject(
      mapId: MapObjectId(cluster.clusterId?.toString() ?? 'cluster_${cluster.markerId}'),
      point: Point(latitude: cluster.latitude ?? 0, longitude: cluster.longitude ?? 0),
      opacity: 1,
      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(
          image: BitmapDescriptor.fromAssetImage('assets/cluster_marker.png'),
          anchor: const Offset(0.5, 1),
        ),
      ),
      text: PlacemarkText(
        text: cluster.pointsSize?.toString() ?? '0',
        style: const PlacemarkTextStyle(color: Colors.white, outlineColor: Colors.transparent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ExtendedMapWidget(
        controller: _controller,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
