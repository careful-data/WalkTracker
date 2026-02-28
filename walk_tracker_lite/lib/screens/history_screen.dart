import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/walk_session.dart';
import '../models/route_point.dart';
import '../providers/history_provider.dart';
import '../providers/tracking_provider.dart';
import '../widgets/stats_bar.dart';
import '../widgets/walk_map.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: historyAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_walk,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No walks yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a walk to see your history here.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _HistoryTile(
                session: session,
                onTap: () => _showSessionRoute(context, ref, session),
                onDelete: () =>
                    ref.read(historyActionsProvider).deleteSession(session),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text('Failed to load history: $err'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSessionRoute(
    BuildContext context,
    WidgetRef ref,
    WalkSession session,
  ) async {
    final db = ref.read(databaseProvider);
    final points = await db.getRoutePoints(session.id!);

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => _RouteDetailScreen(
          session: session,
          routePoints: points,
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  final WalkSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y • HH:mm');
    final dateStr = dateFormat.format(session.startTime);
    final distanceStr = formatDistance(session.distanceMeters);
    final durationStr = formatDuration(session.duration);

    return Dismissible(
      key: Key('session-${session.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete walk?'),
            content: const Text(
              'This walk will be permanently deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.directions_walk,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(dateStr),
        subtitle: Text('$distanceStr • $durationStr'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _RouteDetailScreen extends StatelessWidget {
  const _RouteDetailScreen({
    required this.session,
    required this.routePoints,
  });

  final WalkSession session;
  final List<RoutePoint> routePoints;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y • HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: Text(dateFormat.format(session.startTime)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DetailStat(
                  label: 'Distance',
                  value: formatDistance(session.distanceMeters),
                ),
                _DetailStat(
                  label: 'Duration',
                  value: formatDuration(session.duration),
                ),
              ],
            ),
          ),
          Expanded(
            child: WalkMap(
              routePoints: routePoints,
              readOnly: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
