import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/walk_session.dart';
import 'tracking_provider.dart'; // provides databaseProvider

final historyProvider = FutureProvider<List<WalkSession>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllSessions();
});

/// Provider for history actions (invalidate, delete). Use this instead of
/// passing Ref/WidgetRef to avoid type mismatch between Ref and WidgetRef.
final historyActionsProvider = Provider<HistoryActions>((ref) {
  return HistoryActions(ref);
});

class HistoryActions {
  HistoryActions(this._ref);
  final Ref _ref;

  void invalidateHistory() => _ref.invalidate(historyProvider);

  Future<void> deleteSession(WalkSession session) async {
    final db = _ref.read(databaseProvider);
    await db.deleteSession(session);
    _ref.invalidate(historyProvider);
  }
}
