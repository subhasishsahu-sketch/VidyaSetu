import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/offline/local_database.dart';
import '../data/repositories/hybrid_vidyasetu_repository.dart';
import 'repository_provider.dart';

class HealthState {
  final bool isOnline;
  final bool isSyncing;
  final int pendingQueueCount;
  final String status;

  const HealthState({
    this.isOnline = false,
    this.isSyncing = false,
    this.pendingQueueCount = 0,
    this.status = 'offline',
  });

  HealthState copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingQueueCount,
    String? status,
  }) {
    return HealthState(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingQueueCount: pendingQueueCount ?? this.pendingQueueCount,
      status: status ?? this.status,
    );
  }
}

class HealthNotifier extends StateNotifier<HealthState> {
  final HybridVidyaSetuRepository _repo;
  final LocalDatabase _localDb;

  HealthNotifier(this._repo, this._localDb) : super(const HealthState()) {
    checkHealth();
  }

  Future<void> checkHealth() async {
    final online = await _repo.isOnline();
    int queueCount = 0;
    try {
      queueCount = _localDb.getPendingQueueCount();
    } catch (_) {}

    state = state.copyWith(
      isOnline: online,
      pendingQueueCount: queueCount,
      status: online ? 'online' : 'offline',
    );
  }

  Future<void> syncQueue() async {
    if (state.isSyncing) return;
    state = state.copyWith(isSyncing: true);
    try {
      await _repo.syncPendingOfflineEvents();
    } catch (_) {}

    int queueCount = 0;
    try {
      queueCount = _localDb.getPendingQueueCount();
    } catch (_) {}

    final online = await _repo.isOnline();
    state = state.copyWith(
      isSyncing: false,
      isOnline: online,
      pendingQueueCount: queueCount,
    );
  }
}

final healthStateProvider =
    StateNotifierProvider<HealthNotifier, HealthState>((ref) {
  final repo = ref.watch(hybridVidyaSetuRepositoryProvider);
  final localDb = ref.watch(localDatabaseProvider);
  return HealthNotifier(repo, localDb);
});

final isOnlineProvider = FutureProvider<bool>((ref) async {
  return ref.watch(healthStateProvider).isOnline;
});
