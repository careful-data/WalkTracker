import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants.dart';
import '../models/walk_session.dart';
import '../models/route_point.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import 'permission_provider.dart';

enum TrackingStatus { idle, tracking, paused }

class TrackingState {
  final TrackingStatus status;
  final double distanceMeters;
  final List<RoutePoint> routePoints;
  final Position? currentPosition;
  final Duration elapsedDuration;
  final int? sessionId;

  const TrackingState({
    this.status = TrackingStatus.idle,
    this.distanceMeters = 0.0,
    this.routePoints = const [],
    this.currentPosition,
    this.elapsedDuration = Duration.zero,
    this.sessionId,
  });

  TrackingState copyWith({
    TrackingStatus? status,
    double? distanceMeters,
    List<RoutePoint>? routePoints,
    Position? currentPosition,
    Duration? elapsedDuration,
    int? sessionId,
  }) {
    return TrackingState(
      status: status ?? this.status,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      routePoints: routePoints ?? this.routePoints,
      currentPosition: currentPosition ?? this.currentPosition,
      elapsedDuration: elapsedDuration ?? this.elapsedDuration,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class TrackingNotifier extends StateNotifier<TrackingState> {
  TrackingNotifier(this._db, this._locationService)
      : super(const TrackingState());

  final DatabaseService _db;
  final LocationService _locationService;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _elapsedTimer;
  Position? _lastValidPosition;
  DateTime? _sessionStartTime;

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  Future<void> start() async {
    if (state.status != TrackingStatus.idle) return;

    final session = WalkSession(
      startTime: DateTime.now(),
      isActive: true,
    );
    final id = await _db.insertSession(session);
    _sessionStartTime = session.startTime;
    _lastValidPosition = null;

    state = state.copyWith(
      status: TrackingStatus.tracking,
      sessionId: id,
      distanceMeters: 0.0,
      routePoints: [],
      elapsedDuration: Duration.zero,
    );

    _startElapsedTimer();
    _subscribeToPositionStream();
  }

  void pause() {
    if (state.status != TrackingStatus.tracking) return;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _elapsedTimer?.cancel();
    state = state.copyWith(status: TrackingStatus.paused);
  }

  void resume() {
    if (state.status != TrackingStatus.paused) return;
    _startElapsedTimer();
    _subscribeToPositionStream();
    state = state.copyWith(status: TrackingStatus.tracking);
  }

  Future<void> stop() async {
    if (state.status == TrackingStatus.idle) return;

    _positionSubscription?.cancel();
    _positionSubscription = null;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;

    final sessionId = state.sessionId;
    if (sessionId != null) {
      final endTime = DateTime.now();
      final session = WalkSession(
        id: sessionId,
        startTime: _sessionStartTime ?? endTime,
        endTime: endTime,
        distanceMeters: state.distanceMeters,
        isActive: false,
      );
      await _db.updateSession(session);
    }

    _lastValidPosition = null;
    _sessionStartTime = null;

    state = const TrackingState();
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    final start = _sessionStartTime ?? DateTime.now();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(
        elapsedDuration: DateTime.now().difference(start),
      );
    });
  }

  void _subscribeToPositionStream() {
    _positionSubscription?.cancel();
    _positionSubscription = _locationService.positionStream().listen(
      _onPositionUpdate,
      onError: (_) {},
    );
  }

  void _onPositionUpdate(Position position) {
    final sessionId = state.sessionId;
    if (sessionId == null) return;

    final routePoint = _locationService.validateAndToRoutePoint(
      position,
      sessionId,
      lastValidPosition: _lastValidPosition,
    );

    if (routePoint == null) return;

    double newDistance = state.distanceMeters;
    List<RoutePoint> newRoute = List.from(state.routePoints);

    if (_lastValidPosition != null) {
      final distance = LocationService.distanceBetween(
        _lastValidPosition!,
        position,
      );
      if (distance >= kMinMoveThreshold) {
        newDistance += distance;
        if (distance >= kPathSmoothingThreshold) {
          newRoute.add(routePoint);
          _db.insertRoutePoint(routePoint);
        }
      }
    } else {
      // First valid position: add to route as start point
      newRoute.add(routePoint);
      _db.insertRoutePoint(routePoint);
    }

    _lastValidPosition = position;

    state = state.copyWith(
      currentPosition: position,
      distanceMeters: newDistance,
      routePoints: newRoute,
    );
  }
}

final databaseProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final trackingProvider =
    StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  return TrackingNotifier(
    ref.watch(databaseProvider),
    ref.watch(locationServiceProvider),
  );
});
