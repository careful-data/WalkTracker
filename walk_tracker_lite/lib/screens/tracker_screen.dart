import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/permission_provider.dart';
import '../providers/tracking_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/permission_gate.dart';
import '../widgets/walk_map.dart';
import '../widgets/stats_bar.dart';
import '../widgets/tracking_controls.dart';

class TrackerScreen extends ConsumerStatefulWidget {
  const TrackerScreen({super.key});

  @override
  ConsumerState<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends ConsumerState<TrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(permissionProvider.notifier).check();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TrackingState>(trackingProvider, (prev, next) {
      if (prev?.status != TrackingStatus.idle &&
          next.status == TrackingStatus.idle) {
        ref.read(historyActionsProvider).invalidateHistory();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('WalkTracker Lite'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () => ref.invalidate(currentLocationProvider),
            tooltip: 'Center on my location',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
            tooltip: 'History',
          ),
        ],
      ),
      body: PermissionGate(
        child: Column(
          children: [
            Expanded(
              child: const WalkMap(),
            ),
            const StatsBar(),
            const TrackingControls(),
          ],
        ),
      ),
    );
  }
}
