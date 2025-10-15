// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';

// import 'package:mapkit_lite_extension/controller/app_map_controller.dart';
// import 'package:mapkit_lite_extension/entity/listeners.dart';
// import 'package:mapkit_lite_extension/entity/map_object.dart';
// import 'package:mapkit_lite_extension/entity/map_object_collection.dart';
// import 'package:mapkit_lite_extension/entity/placemark_provider.dart';
// import 'package:mapkit_lite_extension/utils/latlng_bounds.dart';
// import 'package:mapkit_lite_extension/widget/app_map.dart';
// import 'package:yandex_mapkit_lite/yandex_mapkit_lite.dart';

// abstract mixin class PointableMapObject {
//   double get latitude;
//   double get longitude;
// }

// final class ClusterableMapWidget<T extends PointableMapObject> extends StatefulWidget {
//   const ClusterableMapWidget({super.key, required this.objects, required this.onTap});

//   final List<T> objects;
//   final FutureOr<void> Function(T item) onTap;

//   @override
//   State<ClusterableMapWidget<T>> createState() => _ClusterableMapWidgetState<T>();
// }

// /// State for widget ClinicsMap
// class _ClusterableMapWidgetState<T extends PointableMapObject> extends State<ClusterableMapWidget<T>>
//     implements ClusterListener {
//   late final _mapController = AppMapController(init: const AppMapState(rotateGesturesEnabled: false));

//   late final placemarkViewBuilder = SvgPlacemarkProvider(
//     assetKey: Assets.images.map.clinicPin.keyName,
//     viewConfiguration: const Size.square(32) * _pixelRation,
//   );

//   late final placemarkSelectedViewBuilder = SvgPlacemarkProvider(
//     assetKey: Assets.images.map.clinicPinSelected.keyName,
//     viewConfiguration: const Size.square(32) * _pixelRation,
//   );

//   final _clusterPacemakers = <String, SvgPlacemarkProvider>{};

//   late List<T> objects = widget.objects;

//   double _pixelRation = 1;

//   ClusterMapObjectCollection? collection;

//   /* #region Lifecycle */

//   @override
//   void didChangeDependencies() {
//     _pixelRation = MediaQuery.devicePixelRatioOf(context);
//     super.didChangeDependencies();
//   }

//   @override
//   void didUpdateWidget(covariant ClusterableMapWidget<T> oldWidget) {
//     if (!listEquals(oldWidget.objects, widget.objects)) {
//       objects = widget.objects;
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         drawClusters(objects);
//       });
//     }
//     super.didUpdateWidget(oldWidget);
//   }

//   @override
//   void dispose() {
//     disposeCluster();
//     for (final entry in _clusterPacemakers.values) {
//       entry.dispose();
//     }
//     placemarkSelectedViewBuilder.dispose();
//     placemarkViewBuilder.dispose();
//     _mapController.dispose();
//     super.dispose();
//   }
//   /* #endregion */

//   // remove all map objects
//   void disposeCluster() {
//     collection?.onTapCallback = null;
//     collection = null;
//   }

//   Future<void> onTapPlacemark(BaseMapObject object, Point point) async {
//     if (object case final PlacemarkObject placemark) {
//       if (placemark.userData case final T data) {
//         collection?.updatePlacemark(placemark.copyWith(icon: await placemarkSelectedViewBuilder.resolve()));

//         final result = widget.onTap(data);

//         if (result is Future<void>) {
//           await result;
//         }

//         collection?.updatePlacemark(placemark.copyWith(icon: await placemarkViewBuilder.resolve()));
//       }
//     }
//   }

//   // draw clusters and placemark
//   void drawClusters(Iterable<PointableMapObject> clinics) {
//     collection ??= _mapController.mapObjects.addPlacemarkCollection(this);
//     collection?.onTapCallback ??= onTapPlacemark;

//     if (collection!.collection.isNotEmpty) {
//       collection?.clean();
//     }

//     _mapController.use((it) async {
//       if (clinics.length > 1) {
//         final bounds = LatLngBounds.fromPoints(
//           clinics.map((entry) => (latitude: entry.latitude, longitude: entry.longitude)),
//         );

//         final sw = bounds.southWest;
//         final ne = bounds.northEast;

//         await it.moveCamera(
//           CameraUpdate.newGeometry(
//             Geometry.fromBoundingBox(
//               BoundingBox(
//                 northEast: Point(latitude: ne.latitude, longitude: ne.longitude),
//                 southWest: Point(latitude: sw.latitude, longitude: sw.longitude),
//               ),
//             ),
//           ),
//         );

//         final position = await it.getCameraPosition();
//         await it.moveCamera(CameraUpdate.zoomTo(position.zoom - 0.5));
//       } else {
//         final first = clinics.first;
//         await it.moveCamera(
//           CameraUpdate.newCameraPosition(
//             CameraPosition(target: Point(latitude: first.latitude, longitude: first.longitude)),
//           ),
//         );
//         await it.moveCamera(CameraUpdate.zoomTo(15));
//       }

//       final placemark = await placemarkViewBuilder.resolve();
//       collection?.addPoints(
//         clinics.map(
//           (entry) => PlacemarkObject(
//             latLng: (latitude: entry.latitude, longitude: entry.longitude),
//             icon: placemark,
//             userData: entry,
//           ),
//         ),
//       );
//       await collection?.attachCluster(await it.getVisibleRegion(), await it.getCameraPosition());
//     });
//   }

//   @override
//   Future<PlacemarkMapObject> onAddCluster(ClusterableMapObject cluster) async {
//     final provider =
//         _clusterPacemakers[cluster.clusterId!.toString()] ??= SvgPlacemarkProvider(
//           assetKey: Assets.images.map.cluster.keyName,
//           viewConfiguration: const Size.square(48) * _pixelRation,
//         );

//     return PlacemarkMapObject(
//       mapId: MapObjectId(cluster.clusterId!.toString()),
//       point: cluster.location!.toObject(),
//       opacity: 1,
//       icon: await provider.resolve(),
//       text: PlacemarkText(
//         text: cluster.pointsSize!.toString(),
//         style: const PlacemarkTextStyle(color: Colors.white, outlineColor: Colors.transparent),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) => AppMapWidget(
//     controller: _mapController,
//     onMapCreated: () {
//       drawClusters(objects);
//     },
//   );
// }
