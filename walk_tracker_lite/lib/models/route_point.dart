class RoutePoint {
  final int? id;
  final int sessionId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy;

  const RoutePoint({
    this.id,
    required this.sessionId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy = 0.0,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'accuracy': accuracy,
    };
  }

  factory RoutePoint.fromMap(Map<String, Object?> map) {
    return RoutePoint(
      id: map['id'] as int?,
      sessionId: (map['session_id'] as num).toInt(),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num).toInt(),
      ),
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
