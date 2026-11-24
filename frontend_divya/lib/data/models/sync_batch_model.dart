import 'package:flutter/foundation.dart';
import 'diagnostic_model.dart';

/// Single diagnostic analysis event recorded on-device by edge SLM.
@immutable
class OfflineSyncEvent {
  final String analysisId;
  final String studentId;
  final String questionId;
  final Map<String, dynamic> attemptData;
  final List<Map<String, dynamic>> probeLoopEvidence;
  final StudentParametersSnapshot studentParametersSnapshot;
  final Map<String, dynamic>? interventionAndLanguageOutput;
  final Map<String, dynamic>? recoveryAssessment;
  final String executionSource; // 'edge_slm_offline_sync'
  final DateTime offlineCreatedAt;

  const OfflineSyncEvent({
    required this.analysisId,
    required this.studentId,
    required this.questionId,
    required this.attemptData,
    this.probeLoopEvidence = const [],
    required this.studentParametersSnapshot,
    this.interventionAndLanguageOutput,
    this.recoveryAssessment,
    this.executionSource = 'edge_slm_offline_sync',
    required this.offlineCreatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'analysis_id': analysisId.toLowerCase(),
      'student_id': studentId.toLowerCase(),
      'question_id': questionId.toLowerCase(),
      'attempt_data': attemptData,
      'probe_loop_evidence': probeLoopEvidence,
      'student_parameters_snapshot': studentParametersSnapshot.toJson(),
      'intervention_and_language_output': interventionAndLanguageOutput,
      'recovery_assessment': recoveryAssessment,
      'execution_source': executionSource,
      'offline_created_at': offlineCreatedAt.toUtc().toIso8601String(),
    };
  }

  factory OfflineSyncEvent.fromJson(Map<String, dynamic> json) {
    final rawSnapshot = (json['student_parameters_snapshot'] as Map?) ?? {};
    final snapshot = StudentParametersSnapshot.fromJson(
      Map<String, dynamic>.from(rawSnapshot),
    );
    final evidence = (json['probe_loop_evidence'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final offCreated = json['offline_created_at'] != null
        ? DateTime.parse(json['offline_created_at'] as String)
        : DateTime.now().toUtc();

    return OfflineSyncEvent(
      analysisId: (json['analysis_id'] ?? '').toString().toLowerCase(),
      studentId: (json['student_id'] ?? '').toString().toLowerCase(),
      questionId: (json['question_id'] ?? '').toString().toLowerCase(),
      attemptData: Map<String, dynamic>.from((json['attempt_data'] as Map?) ?? {}),
      probeLoopEvidence: evidence,
      studentParametersSnapshot: snapshot,
      interventionAndLanguageOutput: json['intervention_and_language_output'] != null
          ? Map<String, dynamic>.from(json['intervention_and_language_output'] as Map)
          : null,
      recoveryAssessment: json['recovery_assessment'] != null
          ? Map<String, dynamic>.from(json['recovery_assessment'] as Map)
          : null,
      executionSource: (json['execution_source'] ?? 'edge_slm_offline_sync').toString(),
      offlineCreatedAt: offCreated,
    );
  }
}

/// Details of an event that failed validation during batch synchronization.
@immutable
class OfflineSyncFailedEvent {
  final String analysisId;
  final String reason;

  const OfflineSyncFailedEvent({
    required this.analysisId,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'analysis_id': analysisId,
        'reason': reason,
      };

  factory OfflineSyncFailedEvent.fromJson(Map<String, dynamic> json) {
    return OfflineSyncFailedEvent(
      analysisId: (json['analysis_id'] ?? '').toString().toLowerCase(),
      reason: (json['reason'] ?? '').toString(),
    );
  }
}

/// Batch payload containing offline events queued on mobile device.
@immutable
class OfflineSyncBatchRequest {
  final String studentId;
  final DateTime batchTimestamp;
  final List<OfflineSyncEvent> events;

  const OfflineSyncBatchRequest({
    required this.studentId,
    required this.batchTimestamp,
    this.events = const [],
  });

  Map<String, dynamic> toJson() => {
        'student_id': studentId.toLowerCase(),
        'batch_timestamp': batchTimestamp.toUtc().toIso8601String(),
        'events': events.map((e) => e.toJson()).toList(),
      };

  factory OfflineSyncBatchRequest.fromJson(Map<String, dynamic> json) {
    final evs = (json['events'] as List?)
            ?.map((e) => OfflineSyncEvent.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];
    final ts = json['batch_timestamp'] != null
        ? DateTime.parse(json['batch_timestamp'] as String)
        : DateTime.now().toUtc();

    return OfflineSyncBatchRequest(
      studentId: (json['student_id'] ?? '').toString().toLowerCase(),
      batchTimestamp: ts,
      events: evs,
    );
  }
}

/// Response returned after processing offline batch synchronization.
@immutable
class OfflineSyncBatchResponse {
  final List<String> syncedIds;
  final List<String> duplicateIds;
  final List<OfflineSyncFailedEvent> failedEvents;

  const OfflineSyncBatchResponse({
    this.syncedIds = const [],
    this.duplicateIds = const [],
    this.failedEvents = const [],
  });

  Map<String, dynamic> toJson() => {
        'synced_ids': syncedIds,
        'duplicate_ids': duplicateIds,
        'failed_events': failedEvents.map((f) => f.toJson()).toList(),
      };

  factory OfflineSyncBatchResponse.fromJson(Map<String, dynamic> json) {
    final synced = (json['synced_ids'] as List?)?.map((id) => id.toString().toLowerCase()).toList() ?? [];
    final duplicates = (json['duplicate_ids'] as List?)?.map((id) => id.toString().toLowerCase()).toList() ?? [];
    final failed = (json['failed_events'] as List?)
            ?.map((f) => OfflineSyncFailedEvent.fromJson(Map<String, dynamic>.from(f as Map)))
            .toList() ??
        [];

    return OfflineSyncBatchResponse(
      syncedIds: synced,
      duplicateIds: duplicates,
      failedEvents: failed,
    );
  }
}
