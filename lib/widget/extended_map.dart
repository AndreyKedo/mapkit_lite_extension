import 'package:flutter/material.dart';
import 'package:mapkit_lite_extension/controller/extended_map_controller.dart';
import 'package:yandex_mapkit_lite/yandex_mapkit_lite.dart';

const kDefaultLogoAlignment = MapAlignment(horizontal: HorizontalAlignment.left, vertical: VerticalAlignment.bottom);

final class ExtendedMapWidget extends StatefulWidget {
  const ExtendedMapWidget({
    super.key,
    this.controller,
    this.logoAlignment = kDefaultLogoAlignment,
    this.onMapCreated,
  });

  final ExtendedMapController? controller;

  final MapAlignment logoAlignment;

  /// Called when the map is ready to use.
  /// Use this method when you want to call certain actions after the map appears on the screen.
  /// For example, move the camera to a point, add markers, etc.
  final VoidCallback? onMapCreated;

  @override
  State<ExtendedMapWidget> createState() => _ExtendedMapWidgetState();
}

class _ExtendedMapWidgetState extends State<ExtendedMapWidget> {
  late var _controller = widget.controller ?? ExtendedMapController();

  late var _listenable = Listenable.merge([_controller.rootCollection, _controller]);

  /* #region Lifecycle */
  @override
  void didUpdateWidget(ExtendedMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller == null) {
        _controller.dispose();
      }

      _controller = widget.controller ?? ExtendedMapController();
      _listenable = Listenable.merge([_controller.rootCollection, _controller]);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }

    super.dispose();
  }
  /* #endregion */

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: ListenableBuilder(
          listenable: _listenable,
          builder: (context, child) {
            final value = _controller.value;

            return YandexMap(
              mapObjects: _controller.mapObjects,
              tiltGesturesEnabled: value.tiltGesturesEnabled,
              zoomGesturesEnabled: value.zoomGesturesEnabled,
              rotateGesturesEnabled: value.rotateGesturesEnabled,
              scrollGesturesEnabled: value.scrollGesturesEnabled,
              nightModeEnabled: value.nightModeEnabled,
              fastTapEnabled: value.fastTapEnabled,
              mode2DEnabled: value.mode2DEnabled,
              logoAlignment: widget.logoAlignment,
              onCameraPositionChanged: _controller.onCameraPositionChange,
              onMapCreated: (instance) async {
                await _controller.onMapCreate(instance);
                widget.onMapCreated?.call();
              },
            );
          },
        ),
      );
}
