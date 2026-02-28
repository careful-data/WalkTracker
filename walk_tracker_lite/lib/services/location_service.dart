import 'package:geolocator/geolocator.dart';
import '../core/constants.dart';
import '../models/route_point.dart';

/// Pure service for location: permission checks, GPS stream, position validation.
/// No state — consumers manage the stream lifecycle.
class LocationService {
  Future<LocationPermission> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermission.denied;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: kDistanceFilter.toInt(),
      ),
    );
  }

  /// Validates position (ported from Kotlin isLocationValid).
  /// Returns null if invalid, otherwise a RoutePoint.
  RoutePoint? validateAndToRoutePoint(
    Position position,
    int sessionId, {
    Position? lastValidPosition,
  }) {
    if (!_isPositionValid(position, lastValidPosition)) return null;
    return RoutePoint(
      sessionId: sessionId,
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp ?? DateTime.now(),
      accuracy: position.accuracy,
    );
  }

  bool _isPositionValid(Position position, Position? lastValidPosition) {
    // Accuracy filter
    if (position.accuracy > kMaxAccuracyMeters) return false;

    // Age filter
    final age = DateTime.now().difference(
      position.timestamp ?? DateTime.now(),
    ).inMilliseconds;
    if (age > kMaxAgeMs) return false;

    // Speed sanity check (>100 m/s is unrealistic for walking)
    if (lastValidPosition != null) {
      final timeDiff = (position.timestamp ?? DateTime.now())
          .difference(lastValidPosition.timestamp ?? DateTime.now())
          .inSeconds
          .toDouble();
      if (timeDiff > 0) {
        final distance = Geolocator.distanceBetween(
          lastValidPosition.latitude,
          lastValidPosition.longitude,
          position.latitude,
          position.longitude,
        );
        final speed = distance / timeDiff;
        if (speed > kMaxSpeedMps) return false;
      }
    }
    return true;
  }

  /// Distance in meters between two positions.
  static double distanceBetween(Position a, Position b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }
}
