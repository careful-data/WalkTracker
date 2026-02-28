import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/permission_provider.dart';

/// Wraps child when permission is granted; shows permission UX otherwise.
class PermissionGate extends ConsumerWidget {
  const PermissionGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(permissionProvider);

    if (state == PermissionState.granted) {
      return child;
    }

    return _PermissionBlockedContent(
      state: state,
      onCheck: () => ref.read(permissionProvider.notifier).check(),
      onRequest: () => ref.read(permissionProvider.notifier).request(),
      onOpenSettings: () => Geolocator.openLocationSettings(),
    );
  }
}

class _PermissionBlockedContent extends StatelessWidget {
  const _PermissionBlockedContent({
    required this.state,
    required this.onCheck,
    required this.onRequest,
    required this.onOpenSettings,
  });

  final PermissionState state;
  final VoidCallback onCheck;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    if (state == PermissionState.checking || state == PermissionState.unknown) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state == PermissionState.serviceDisabled) {
      return _MessageCard(
        icon: Icons.gps_off,
        title: 'GPS is off',
        message: 'Please enable location services in System Settings to track your walk.',
        buttonLabel: 'Open Settings',
        onPressed: onOpenSettings,
        secondaryLabel: 'Retry',
        onSecondaryPressed: onCheck,
      );
    }

    if (state == PermissionState.deniedForever) {
      return _MessageCard(
        icon: Icons.location_off,
        title: 'Location access denied',
        message:
            'Location permission was permanently denied. Open settings to grant access.',
        buttonLabel: 'Open Settings',
        onPressed: onOpenSettings,
      );
    }

    return _MessageCard(
      icon: Icons.location_on_outlined,
      title: 'Location permission needed',
      message: 'WalkTracker Lite needs location access to track your route and distance.',
      buttonLabel: 'Grant Permission',
      onPressed: onRequest,
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (secondaryLabel != null && onSecondaryPressed != null) ...[
                  OutlinedButton(
                    onPressed: onSecondaryPressed,
                    child: Text(secondaryLabel!),
                  ),
                  const SizedBox(width: 12),
                ],
                FilledButton(
                  onPressed: onPressed,
                  child: Text(buttonLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
