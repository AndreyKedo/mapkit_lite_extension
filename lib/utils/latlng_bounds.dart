import 'dart:math';

class LatLngBounds {
  const LatLngBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  static const degreesToRadians = pi / 180;
  static const radiansToDegrees = 180 / pi;

  static const double minLatitude = -90;
  static const double maxLatitude = 90;
  static const double minLongitude = -180;
  static const double maxLongitude = 180;

  final double north;
  final double south;
  final double east;
  final double west;

  factory LatLngBounds.fromPoints(Iterable<({double latitude, double longitude})> points) {
    assert(
      points.isNotEmpty,
      'LatLngBounds cannot be created with an empty List of LatLng',
    );

    var minX = maxLongitude;
    var maxX = minLongitude;
    var minY = maxLatitude;
    var maxY = minLatitude;

    for (final point in points) {
      if (point.longitude < minX) minX = point.longitude;
      if (point.longitude > maxX) maxX = point.longitude;
      if (point.latitude < minY) minY = point.latitude;
      if (point.latitude > maxY) maxY = point.latitude;
    }
    return LatLngBounds(
      north: maxY,
      south: minY,
      east: maxX,
      west: minX,
    );
  }

  ({double latitude, double longitude}) get southWest => (latitude: south, longitude: west);
  ({double latitude, double longitude}) get northEast => (latitude: north, longitude: east);
  ({double latitude, double longitude}) get northWest => (latitude: north, longitude: west);
  ({double latitude, double longitude}) get southEast => (latitude: south, longitude: east);

  ({double latitude, double longitude}) get center {
    final phi1 = south * degreesToRadians;
    final lambda1 = west * degreesToRadians;
    final phi2 = north * degreesToRadians;

    final dLambda = degreesToRadians * (east - west);

    final bx = cos(phi2) * cos(dLambda);
    final by = cos(phi2) * sin(dLambda);
    final phi3 = atan2(sin(phi1) + sin(phi2), sqrt((cos(phi1) + bx) * (cos(phi1) + bx) + by * by));
    final lambda3 = lambda1 + atan2(by, cos(phi1) + bx);

    return (
      latitude: phi3 * radiansToDegrees,
      longitude: (lambda3 * radiansToDegrees + 540) % 360 - 180,
    );
  }
}
