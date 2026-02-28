import 'package:flutter/material.dart';

// Location filtering (ported from Kotlin LocationService)
const double kMaxAccuracyMeters = 25.0;
const int kMaxAgeMs = 30000;
const double kMinMoveThreshold = 1.0;
const double kPathSmoothingThreshold = 3.0;
const double kDistanceFilter = 10.0; // geolocator distance filter for battery
const double kMaxSpeedMps = 100.0; // reject unrealistic jumps (>360 km/h)

// Map defaults
const double kInitialZoom = 15.0;
const double kPolylineStrokeWidth = 4.0;
const int kPolylineColor = 0xFF2196F3; // blue

// Theme
const Color kAccentColor = Color(0xFF4CAF50); // walking green
