import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tracking_provider.dart';

class TrackingControls extends ConsumerWidget {
  const TrackingControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackingProvider);
    final notifier = ref.read(trackingProvider.notifier);

    if (state.status == TrackingStatus.idle) {
      return _buildIdleControls(context, notifier);
    }
    if (state.status == TrackingStatus.paused) {
      return _buildPausedControls(context, notifier);
    }
    return _buildTrackingControls(context, notifier);
  }

  Widget _buildIdleControls(BuildContext context, TrackingNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => notifier.start(),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Walk'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildPausedControls(BuildContext context, TrackingNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => notifier.resume(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => notifier.stop(),
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingControls(BuildContext context, TrackingNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => notifier.pause(),
              icon: const Icon(Icons.pause),
              label: const Text('Pause'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => notifier.stop(),
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
