import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/offline/local_database.dart';
import '../data/repositories/cloud_vidyasetu_repository.dart';
import '../data/repositories/offline_vidyasetu_repository.dart';
import '../data/repositories/hybrid_vidyasetu_repository.dart';
import '../data/repositories/vidyasetu_repository.dart';

/// Singleton LocalDatabase instance provider.
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final db = LocalDatabase();
  return db;
});

/// Singleton HybridVidyaSetuRepository instance provider.
final hybridVidyaSetuRepositoryProvider = Provider<HybridVidyaSetuRepository>((ref) {
  final localDb = ref.watch(localDatabaseProvider);
  final cloud = CloudVidyaSetuRepository();
  final offline = OfflineVidyaSetuRepository(localDb: localDb);
  return HybridVidyaSetuRepository(
    cloudRepo: cloud,
    offlineRepo: offline,
    localDb: localDb,
    connectivity: Connectivity(),
  );
});

/// Unified VidyaSetuRepository facade interface provider.
final vidyasetuRepositoryProvider = Provider<VidyaSetuRepository>((ref) {
  return ref.watch(hybridVidyaSetuRepositoryProvider);
});
