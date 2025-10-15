import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mapkit_lite_extension/entity/extended_map_object_collection.dart';

import 'package:yandex_mapkit_lite/yandex_mapkit_lite.dart';

/// Map state.
///
/// See more [YandexMap]
class ExtendedMapState {
  const ExtendedMapState({
    this.tiltGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.nightModeEnabled = false,
    this.fastTapEnabled = false,
    this.mode2DEnabled = false,
  });

  /// Enable/disable user interaction tilt, zoom, rotate, scroll.
  factory ExtendedMapState.enableUserInteractions(bool enabled) => ExtendedMapState(
        tiltGesturesEnabled: enabled,
        zoomGesturesEnabled: enabled,
        rotateGesturesEnabled: enabled,
        scrollGesturesEnabled: enabled,
      );

  /// [YandexMap.tiltGesturesEnabled]
  final bool tiltGesturesEnabled;

  /// [YandexMap.zoomGesturesEnabled]
  final bool zoomGesturesEnabled;

  /// [YandexMap.rotateGesturesEnabled]
  final bool rotateGesturesEnabled;

  /// [YandexMap.scrollGesturesEnabled]
  final bool scrollGesturesEnabled;

  /// [YandexMap.nightModeEnabled]
  final bool nightModeEnabled;

  /// [YandexMap.fastTapEnabled]
  final bool fastTapEnabled;

  /// [YandexMap.mode2DEnabled]
  final bool mode2DEnabled;

  ExtendedMapState copyWith({
    bool? tiltGesturesEnabled,
    bool? zoomGesturesEnabled,
    bool? rotateGesturesEnabled,
    bool? scrollGesturesEnabled,
    bool? nightModeEnabled,
    bool? fastTapEnabled,
    bool? mode2DEnabled,
  }) =>
      ExtendedMapState(
        tiltGesturesEnabled: tiltGesturesEnabled ?? this.tiltGesturesEnabled,
        zoomGesturesEnabled: zoomGesturesEnabled ?? this.zoomGesturesEnabled,
        rotateGesturesEnabled: rotateGesturesEnabled ?? this.rotateGesturesEnabled,
        scrollGesturesEnabled: scrollGesturesEnabled ?? this.scrollGesturesEnabled,
        nightModeEnabled: nightModeEnabled ?? this.nightModeEnabled,
        fastTapEnabled: fastTapEnabled ?? this.fastTapEnabled,
        mode2DEnabled: mode2DEnabled ?? this.mode2DEnabled,
      );

  @override
  int get hashCode => Object.hash(
        runtimeType,
        tiltGesturesEnabled,
        zoomGesturesEnabled,
        rotateGesturesEnabled,
        scrollGesturesEnabled,
        nightModeEnabled,
        fastTapEnabled,
        mode2DEnabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtendedMapController &&
          runtimeType == other.runtimeType &&
          tiltGesturesEnabled == other.tiltGesturesEnabled &&
          zoomGesturesEnabled == other.zoomGesturesEnabled &&
          rotateGesturesEnabled == other.rotateGesturesEnabled &&
          scrollGesturesEnabled == other.scrollGesturesEnabled &&
          nightModeEnabled == other.nightModeEnabled &&
          fastTapEnabled == other.fastTapEnabled &&
          mode2DEnabled == other.mode2DEnabled;
}

class ExtendedMapController extends ValueNotifier<ExtendedMapState> {
  ExtendedMapController({String? styleAssetsPath, ExtendedMapState init = const ExtendedMapState()}) : super(init) {
    if (styleAssetsPath != null) {
      final completer = Completer<String>.sync()..complete(rootBundle.loadString(styleAssetsPath));
      _style = completer.future;
    }
  }

  late final mapObjectTree = MapCollectionTree();
  late final rootCollection = mapObjectTree.root;

  List<MapObject> get mapObjects => mapObjectTree.mapObjects;

  Future<String>? _style;
  YandexMapController? _controller;

  bool get tiltGesturesEnabled => value.tiltGesturesEnabled;
  set tiltGesturesEnabled(bool enabled) {
    if (enabled == tiltGesturesEnabled) return;

    value = value.copyWith(tiltGesturesEnabled: enabled);
  }

  bool get zoomGesturesEnabled => value.zoomGesturesEnabled;
  set zoomGesturesEnabled(bool enabled) {
    if (enabled == zoomGesturesEnabled) return;

    value = value.copyWith(zoomGesturesEnabled: enabled);
  }

  bool get rotateGesturesEnabled => value.rotateGesturesEnabled;
  set rotateGesturesEnabled(bool enabled) {
    if (enabled == value.rotateGesturesEnabled) return;

    value = value.copyWith(rotateGesturesEnabled: enabled);
  }

  bool get scrollGesturesEnabled => value.scrollGesturesEnabled;
  set scrollGesturesEnabled(bool enabled) {
    if (enabled == value.scrollGesturesEnabled) return;

    value = value.copyWith(scrollGesturesEnabled: enabled);
  }

  bool get nightModeEnabled => value.nightModeEnabled;
  set nightModeEnabled(bool enabled) {
    if (enabled == value.nightModeEnabled) return;

    value = value.copyWith(nightModeEnabled: enabled);
  }

  bool get fastTapEnabled => value.fastTapEnabled;
  set fastTapEnabled(bool enabled) {
    if (enabled == value.fastTapEnabled) return;

    value = value.copyWith(fastTapEnabled: enabled);
  }

  bool get mode2DEnabled => value.mode2DEnabled;
  set mode2DEnabled(bool enabled) {
    if (enabled == value.mode2DEnabled) return;

    value = value.copyWith(mode2DEnabled: enabled);
  }

  void use(void Function(YandexMapController it) block) {
    if (_controller case final YandexMapController it) {
      block(it);
    }
  }

  Future<void> onMapCreate(YandexMapController controller) async {
    if (identical(controller, _controller)) return;

    if (_controller != null) {
      _controller = null;
    }

    _controller = controller;

    if (_style != null) {
      await controller.setMapStyle(await _style!);
    }
  }

  void onCameraPositionChange(
    CameraPosition cameraPosition,
    CameraUpdateReason reason,
    bool finished,
    VisibleRegion visibleRegion,
  ) {
    final clusters = rootCollection.children.whereType<ExtendedClusteredMapObjectCollection>();

    for (final cluster in clusters) {
      cluster.attachCluster(visibleRegion, cameraPosition);
    }
  }

  @override
  void dispose() {
    rootCollection.dispose();
    super.dispose();
  }
}
