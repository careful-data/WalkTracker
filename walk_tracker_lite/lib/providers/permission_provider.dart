import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

enum PermissionState {
  unknown,
  checking,
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

class PermissionNotifier extends StateNotifier<PermissionState> {
  PermissionNotifier(this._locationService) : super(PermissionState.unknown);

  final LocationService _locationService;

  Future<void> check() async {
    state = PermissionState.checking;
    final enabled = await _locationService.isLocationServiceEnabled();
    // On macOS, isLocationServiceEnabled() can return false until the app has
    // requested permission at least once. Always try the permission flow so
    // the system dialog can appear and add the app to Location Services.
    final permission = await _locationService.checkAndRequestPermission();
    if (!enabled && permission == LocationPermission.denied) {
      state = PermissionState.serviceDisabled;
      return;
    }
    _applyPermission(permission);
  }

  Future<void> request() async {
    state = PermissionState.checking;
    final enabled = await _locationService.isLocationServiceEnabled();
    // On macOS, always try requestPermission—it may trigger the system dialog.
    final permission = await _locationService.checkAndRequestPermission();
    if (!enabled && permission == LocationPermission.denied) {
      state = PermissionState.serviceDisabled;
      return;
    }
    _applyPermission(permission);
  }

  void _applyPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        state = PermissionState.denied;
        break;
      case LocationPermission.deniedForever:
        state = PermissionState.deniedForever;
        break;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        state = PermissionState.granted;
        break;
      case LocationPermission.unableToDetermine:
        state = PermissionState.denied;
        break;
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final permissionProvider =
    StateNotifierProvider<PermissionNotifier, PermissionState>((ref) {
  return PermissionNotifier(ref.watch(locationServiceProvider));
});

/// Fetches current position when permission is granted. Used to center the map
/// when the user is idle (not tracking). On desktop, tries cached position first,
/// then getCurrentPosition with a long timeout (WiFi location can be slow).
final currentLocationProvider = FutureProvider<Position?>((ref) async {
  final perm = ref.watch(permissionProvider);
  if (perm != PermissionState.granted) return null;
  try {
    // Try cached position first (instant on desktop if available)
    final cached = await Geolocator.getLastKnownPosition();
    if (cached != null) return cached;
    // Fall back to fresh position with 30s timeout (desktop WiFi can take a while)
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        timeLimit: Duration(seconds: 30),
        accuracy: LocationAccuracy.medium,
      ),
    );
  } catch (_) {
    return null;
  }
});
