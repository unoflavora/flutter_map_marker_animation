import 'dart:math';

import 'package:dart_exporter_annotation/dart_exporter_annotation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animated_marker/src/animated_marker_layer_options.dart';
import 'package:latlong2/latlong.dart';

@Export()
class AnimatedMarkerLayer<T> extends ImplicitlyAnimatedWidget {
  final AnimatedMarkerLayerOptions<T> options;
  AnimatedMarkerLayer({
    Key? key,
    required this.options,
  }) : super(
          key: key,
          duration: options.duration,
          curve: options.curve,
        );

  @override
  AnimatedWidgetBaseState createState() => _AnimatedMarkerLayerState();
}

class _AnimatedMarkerLayerState
    extends AnimatedWidgetBaseState<AnimatedMarkerLayer>
    with AutomaticKeepAliveClientMixin {
  Tween<double>? _latitude;
  Tween<double>? _longitude;

  Marker get marker => widget.options.marker;
  double get latitude =>
      _latitude?.evaluate(animation) ?? marker.point.latitude;
  double get longitude =>
      _longitude?.evaluate(animation) ?? marker.point.longitude;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _latitude = visitor(_latitude, widget.options.marker.point.latitude,
            (dynamic value) => Tween<double>(begin: value as double))
        as Tween<double>?;
    _longitude = visitor(_longitude, widget.options.marker.point.longitude,
            (dynamic value) => Tween<double>(begin: value as double))
        as Tween<double>?;
  }

  @override
  void didUpdateWidget(covariant AnimatedMarkerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final map = MapCamera.of(context);
    final markerLatLng = LatLng(latitude, longitude);
    
    // Get the pixel position using the correct method in Flutter Map 8.1.1
    final pxPoint = map.latLngToScreenOffset(markerLatLng);
    
    final width = marker.width;
    final height = marker.height;
    final left = 0.5 * marker.width * (((marker.alignment)?.x ?? 0) + 1);
    final top = 0.5 * marker.height * (((marker.alignment)?.y ?? 0) + 1);
    final right = width - left;
    final bottom = height - top;

    final sw = Point(pxPoint.dx + width, pxPoint.dy - height);
    final ne = Point(pxPoint.dx - width, pxPoint.dy + height);

    final visibleRect = Rect.fromLTRB(
      0,
      0,
      map.size.width,
      map.size.height,
    );
    final markerRect = Rect.fromLTRB(
      sw.x,
      ne.y,
      ne.x,
      sw.y,
    );

    if (!visibleRect.overlaps(markerRect)) {
      return const SizedBox();
    }

    final pos = Point(pxPoint.dx, pxPoint.dy);
    final markerWidget = (marker.rotate ?? widget.options.rotate ?? false)
        // Counter rotated marker to the map rotation
        ? Transform.rotate(
            angle: -map.rotation * (pi / 180.0),
            origin: widget.options.rotateOrigin,
            alignment: widget.options.rotateAlignment,
            child: marker.child,
          )
        : marker.child;
    return MobileLayerTransformer(
        child: Stack(
      children: [
        Positioned(
          key: marker.key,
          width: marker.width,
          height: marker.height,
          left: pos.x - right,
          top: pos.y - bottom,
          child: markerWidget,
        )
      ],
    ));
  }

  @override
  bool get wantKeepAlive => true;
}
