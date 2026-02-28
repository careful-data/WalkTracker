import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants.dart';
import '../models/route_point.dart';
import '../providers/permission_provider.dart';
import '../providers/tracking_provider.dart';

/// Map widget showing OSM tiles, route polyline, and current position.
class WalkMap extends ConsumerStatefulWidget {
  const WalkMap({
    super.key,
    this.routePoints = const [],
    this.readOnly = false,
  });

  /// For history view: show a saved route without live tracking.
  final List<RoutePoint> routePoints;

  /// If true, no camera following; used for history screen.
  final bool readOnly;

  @override
  ConsumerState<WalkMap> createState() => _WalkMapState();
}

class _WalkMapState extends ConsumerState<WalkMap> {
  final MapController _mapController = MapController();
  static const LatLng _defaultCenter = LatLng(37.7749, -122.4194);

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.readOnly && widget.routePoints.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitToRoute());
    }
  }

  void _fitToRoute() {
    final points = widget.routePoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();
    if (points.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.readOnly) {
      return _buildMap(
        routePoints: widget.routePoints,
        currentPosition: null,
        followPosition: false,
        idlePosition: null,
      );
    }

    final state = ref.watch(trackingProvider);
    final routePoints = state.routePoints;
    final currentPosition = state.currentPosition;
    final followPosition = state.status == TrackingStatus.tracking;
    final idleLocationAsync = ref.watch(currentLocationProvider);

    ref.listen<TrackingState>(trackingProvider, (prev, next) {
      if (next.status == TrackingStatus.tracking &&
          next.currentPosition != null &&
          next.currentPosition != prev?.currentPosition) {
        _moveToPosition(next.currentPosition!);
      }
    });

    // When idle and we get our location, center the map on it
    ref.listen(currentLocationProvider, (prev, next) {
      if (!followPosition &&
          next.valueOrNull != null &&
          next.valueOrNull != prev?.valueOrNull) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _moveToPosition(next.valueOrNull!);
        });
      }
    });

    return idleLocationAsync.when(
      data: (idlePosition) => _buildMap(
        routePoints: routePoints,
        currentPosition: currentPosition,
        followPosition: followPosition,
        idlePosition: idlePosition,
      ),
      loading: () => _buildMap(
        routePoints: routePoints,
        currentPosition: currentPosition,
        followPosition: followPosition,
        idlePosition: null,
      ),
      error: (_, __) => _buildMap(
        routePoints: routePoints,
        currentPosition: currentPosition,
        followPosition: followPosition,
        idlePosition: null,
      ),
    );
  }

  void _moveToPosition(dynamic position) {
    final lat = position.latitude as double;
    final lng = position.longitude as double;
    _mapController.move(LatLng(lat, lng), kInitialZoom);
  }

  Widget _buildMap({
    required List<RoutePoint> routePoints,
    required dynamic currentPosition,
    required bool followPosition,
    dynamic idlePosition,
  }) {
    final polylinePoints = routePoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    LatLng? center;
    if (currentPosition != null) {
      center = LatLng(
        currentPosition.latitude as double,
        currentPosition.longitude as double,
      );
    } else if (idlePosition != null) {
      center = LatLng(
        idlePosition.latitude as double,
        idlePosition.longitude as double,
      );
    } else if (polylinePoints.isNotEmpty) {
      center = polylinePoints.last;
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center ?? _defaultCenter,
        initialZoom: kInitialZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.carefuldata.walk_tracker_lite',
        ),
        if (polylinePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: polylinePoints,
                color: const Color(kPolylineColor),
                strokeWidth: kPolylineStrokeWidth,
              ),
            ],
          ),
        if (currentPosition != null || idlePosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  (currentPosition ?? idlePosition).latitude as double,
                  (currentPosition ?? idlePosition).longitude as double,
                ),
                width: 24,
                height: 24,
                child: const _CurrentPositionMarker(),
              ),
            ],
          ),
      ],
    );
  }
}

class _CurrentPositionMarker extends StatelessWidget {
  const _CurrentPositionMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(kPolylineColor),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
