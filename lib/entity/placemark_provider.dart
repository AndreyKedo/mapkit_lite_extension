import 'dart:ui' as ui;

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/v4.dart';
import 'package:yandex_mapkit_lite/yandex_mapkit_lite.dart';

typedef PlacemarkBuilder = PlacemarkIcon Function(BitmapDescriptor descriptor);

/// PlacemarkProvider.
///
/// Provide placemark [PlacemarkIcon].
abstract class PlacemarkProvider {
  PlacemarkProvider({String? id, this.cacheable = true}) : id = id ?? const UuidV4().generate() {
    FlutterMemoryAllocations.instance.dispatchObjectCreated(
      library: 'mapkit_lite_extension',
      className: 'PlacemarkProvider',
      object: this,
    );
  }

  /// Unique placemark id.
  final String id;

  /// Enable/disable cache.
  final bool cacheable;
  final _asyncCache = AsyncCache<PlacemarkIcon>.ephemeral();

  /// Cache of placemark.
  static final placemarkCache = <String, Future<PlacemarkIcon>>{};

  @protected
  Future<PlacemarkIcon> load();

  /// Load placemark.
  Future<PlacemarkIcon> resolve() => _asyncCache.fetch(() async {
        if (cacheable) {
          final result = await PlacemarkProvider.placemarkCache.putIfAbsent(id, load);

          return result;
        }

        return load();
      });

  /// Dispose placemark provider.
  void dispose() {
    FlutterMemoryAllocations.instance.dispatchObjectDisposed(object: this);
    placemarkCache.remove(id);
  }
}

/// SvgPlacemarkProvider.
///
/// Provide placemark from SVG assets.
class SvgPlacemarkProvider extends PlacemarkProvider {
  SvgPlacemarkProvider({required this.assetKey, required this.viewConfiguration, this.placemarkBuilder});

  /// Asset key.
  final String assetKey;
  final Size viewConfiguration;
  final PlacemarkBuilder? placemarkBuilder;

  @override
  Future<PlacemarkIcon> load() async {
    final svgString = await rootBundle.loadString(assetKey);
    final svgStringLoader = SvgStringLoader(svgString);
    final pictureInfo = await vg.loadPicture(svgStringLoader, null);
    final picture = pictureInfo.picture;
    final recorder = ui.PictureRecorder();

    final targetWidth = pictureInfo.size.width;
    final targetHeight = pictureInfo.size.height;

    final outputRect = Rect.fromPoints(Offset.zero, Offset(viewConfiguration.width, viewConfiguration.height));

    final canvas = ui.Canvas(recorder, outputRect);

    final imageSize = Size(targetWidth, targetHeight);
    final sizes = applyBoxFit(BoxFit.contain, imageSize, outputRect.size);
    final inputSubrect = Alignment.center.inscribe(sizes.source, Offset.zero & imageSize);
    final outputSubrect = Alignment.center.inscribe(sizes.destination, outputRect);

    // debug draw bounds
    assert(() {
      canvas.drawRect(
        outputSubrect,
        Paint()
          ..color = Colors.black
          ..strokeWidth = 0.6
          ..style = PaintingStyle.stroke,
      );
      return true;
    }(), 'debug draw');

    canvas.save();
    canvas.translate(outputSubrect.center.dx - (sizes.destination.width / 2), 0);
    canvas.scale(outputSubrect.width / inputSubrect.width, outputSubrect.height / inputSubrect.height);
    canvas.drawPicture(picture);
    canvas.restore();

    final image = recorder.endRecording().toImageSync(viewConfiguration.width.ceil(), viewConfiguration.height.ceil());
    final bytesData = await image.toByteData(format: ui.ImageByteFormat.png);
    final imageData = bytesData?.buffer.asUint8List();

    if (imageData == null) throw FlutterError('Image data is null');

    // release resource
    image.dispose();
    pictureInfo.picture.dispose();

    final descriptor = BitmapDescriptor.fromBytes(imageData);

    if (placemarkBuilder != null) {
      return placemarkBuilder!(descriptor);
    }

    return PlacemarkIcon.single(PlacemarkIconStyle(zIndex: 1, anchor: const Offset(0.5, 1), image: descriptor));
  }
}

// class ViewProvider {
//   ViewProvider({
//     required FutureOr<Widget> Function() builder,
//     required ViewConfiguration Function(mapkit_lite_extensionaQueryData mapkit_lite_extensionaQuery) configurationFactory,
//     this.textDirection = TextDirection.ltr,
//     FlutterView? view,
//     String? id,
//     this.cacheable = false,
//   })  : id = id ?? const UuidV4().generate(),
//         _view = view ?? PlatformDispatcher.instance.views.first,
//         _builder = builder,
//         _configurationFactory = configurationFactory;

//   final FlutterView _view;
//   final FutureOr<Widget> Function() _builder;
//   final ViewConfiguration Function(mapkit_lite_extensionaQueryData mapkit_lite_extensionaQuery) _configurationFactory;
//   final TextDirection textDirection;
//   final String id;
//   final bool cacheable;

//   static final viewCache = <String, Image>{};

//   Future<Uint8List> getByteData =>

//   Future<Image> _drawWidget() async {
//     final repaintBoundary = RenderRepaintBoundary();
//     final widget = await _builder();
//     final mapkit_lite_extensionaQuery = mapkit_lite_extensionaQueryData.fromView(_view);
//     final renderView = _OffscreenRenderView(_view, _configurationFactory(mapkit_lite_extensionaQuery), repaintBoundary);

//     renderView.markNeedsLayout();
//     final pipelineOwner = PipelineOwner()..rootNode = renderView;
//     renderView.prepareInitialFrame();
//     pipelineOwner.requestVisualUpdate();

//     var isDirty = false;

//     final buildOwner = BuildOwner(
//       focusManager: FocusManager(),
//       onBuildScheduled: () {
//         isDirty = true;
//       },
//     );
//     final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
//       container: repaintBoundary,
//       child: mapkit_lite_extensionaQuery(
//         data: mapkit_lite_extensionaQuery,
//         child: Directionality(
//           textDirection: textDirection,
//           child: IntrinsicHeight(child: IntrinsicWidth(child: widget)),
//         ),
//       ),
//     ).attachToRenderTree(buildOwner);

//     buildOwner.buildScope(rootElement);
//     pipelineOwner.flushLayout();

//     if (!repaintBoundary.hasSize) {
//       final frameReady = Completer();
//       WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
//         frameReady.complete();
//       });
//       await frameReady.future;

//       buildOwner.buildScope(rootElement);
//       pipelineOwner.flushLayout();
//     }

//     pipelineOwner
//       ..flushCompositingBits()
//       ..flushPaint();

//     renderView.compositeFrame();
//     pipelineOwner.flushSemantics();
//     buildOwner.finalizeTree();

//     Image? image;

//     var retryCounter = 3;

//     do {
//       isDirty = false;

//       image?.dispose();

//       image = await repaintBoundary.toImage(pixelRatio: mapkit_lite_extensionaQuery.devicePixelRatio);

//       if (isDirty) {
//         buildOwner.buildScope(rootElement);
//         pipelineOwner.flushLayout();
//         pipelineOwner.flushCompositingBits();
//         pipelineOwner.flushPaint();
//         renderView.compositeFrame();
//         pipelineOwner.flushSemantics();
//         buildOwner.finalizeTree();
//       }

//       retryCounter--;
//     } while (isDirty && retryCounter >= 0);

//     buildOwner.finalizeTree();

//     return image;
//   }
// }

// class _OffscreenRenderView extends RenderView {
//   final RenderRepaintBoundary repaintBoundary;

//   _OffscreenRenderView(
//     FlutterView view,
//     ViewConfiguration configuration,
//     this.repaintBoundary,
//   ) : super(
//           child: RenderPositionedBox(
//             child: repaintBoundary,
//           ),
//           configuration: configuration,
//           view: view,
//         );

//   @override
//   void compositeFrame() {}
// }
