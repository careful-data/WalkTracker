class WalkSession {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceMeters;
  final bool isActive;

  const WalkSession({
    this.id,
    required this.startTime,
    this.endTime,
    this.distanceMeters = 0.0,
    this.isActive = false,
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'distance_meters': distanceMeters,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory WalkSession.fromMap(Map<String, Object?> map) {
    return WalkSession(
      id: map['id'] as int?,
      startTime: DateTime.fromMillisecondsSinceEpoch(
        (map['start_time'] as num).toInt(),
      ),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['end_time'] as num).toInt(),
            )
          : null,
      distanceMeters: (map['distance_meters'] as num?)?.toDouble() ?? 0.0,
      isActive: (map['is_active'] as int?) == 1,
    );
  }

  WalkSession copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    double? distanceMeters,
    bool? isActive,
  }) {
    return WalkSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      isActive: isActive ?? this.isActive,
    );
  }
}
