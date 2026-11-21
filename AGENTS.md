# VidyaSetu Agent Guidelines & Architecture Rules

This document establishes the mandatory architectural rules and engineering constraints for any agent or developer contributing to the VidyaSetu project.

---

## 1. Backend Freeze & Single Source of Truth

- **DO NOT modify any files inside `vidyasetu-backend/` unless explicitly instructed by the user.**
- The backend (FastAPI + MongoDB + LangGraph) is already verified and covered with **47 passing tests** (`tests/test_*.py`). It must remain stable and untouched.
- Treat `vidyasetu-backend/app/schemas/*.py` and `vidyasetu-backend/app/api/routes/*.py` as the **sole single source of truth** for all API contracts, data models, validation aliases, and payload structures.

### Backend Contract Quick Reference

| Endpoint | HTTP Method | Request Schema | Response Schema | Source Route |
| :--- | :---: | :--- | :--- | :--- |
| `/api/v1/health` | `GET` | _None_ | `{"status": "healthy"\|"degraded", "database": "connected"\|"disconnected"}` | `app/main.py` |
| `/api/v1/students` | `POST` | `StudentCreateRequest` | `StudentResponse` | `app/api/routes/students.py` |
| `/api/v1/students/{student_id}` | `GET` | _None_ | `StudentResponse` | `app/api/routes/students.py` |
| `/api/v1/students/{student_id}/progress` | `POST` | `ProgressUpdateRequest` | `ProgressResponse` | `app/api/routes/students.py` |
| `/api/v1/students/{student_id}/progress/{chapter_name}` | `GET` | _None_ | `ProgressResponse` | `app/api/routes/students.py` |
| `/api/v1/students/{student_id}/progress-summary` | `GET` | _None_ | `List[ProgressResponse]` | `app/api/routes/students.py` |
| `/api/v1/questions` | `GET` | Query filters (`subject`, `chapter_name`, `concept_name`) | `List[QuestionPublicResponse]` | `app/api/routes/questions.py` |
| `/api/v1/questions/{question_id}` | `GET` | _None_ | `QuestionPublicResponse` | `app/api/routes/questions.py` |
| `/api/v1/diagnostics/attempt` | `POST` | `AttemptRequest` | `AttemptResponse` | `app/api/routes/diagnostics.py` |
| `/api/v1/diagnostics/probe-response` | `POST` | `ProbeResponseRequest` | `ProbeResponseResult` | `app/api/routes/diagnostics.py` |
| `/api/v1/diagnostics/recovery` | `POST` | `RecoverySubmitRequest` | `RecoverySubmitResponse` | `app/api/routes/diagnostics.py` |
| `/api/v1/language/bridge` | `POST` | `LanguageBridgeRequest` | `LanguageBridgeResponse` | `app/api/routes/language.py` |
| `/api/v1/offline-packs` | `POST` | `OfflinePackRequest` | `OfflinePackResponse` | `app/api/routes/sync.py` |
| `/api/v1/sync/offline-analysis` | `POST` | `OfflineSyncBatchRequest` | `OfflineSyncBatchResponse` | `app/api/routes/sync.py` |

---

## 2. Flutter Modular Architecture & Directory Separation

To ensure clean separation of concerns and allow future UI features to plug in seamlessly, all client-side integration and business logic must follow this folder structure:

```
vidyasetu_mobile/
  assets/
    db/
      offline_curriculum.db      # Pre-packaged curriculum SQLite database
  lib/
    core/                        # Infrastructure, networking, and platform services
      constants/                 # Environment configs, endpoint constants, asset paths
      database/                  # Local SQLite manager, schema migrations, asset db loader
      network/                   # ApiClient, HealthChecker, connectivity detection
      slm/                       # LocalSlmEngine interface, LlamaCppDart implementation
    data/                        # Data layer: models, data sources, and repositories
      datasources/
        local/                   # Local SQLite DAO, pending sync queue DAO
        remote/                  # Cloud API clients communicating with FastAPI
      models/                    # Dart DTOs matching backend Pydantic schemas 1:1
      repositories/              # CloudVidyaSetuRepository, OfflineVidyaSetuRepository
      sync/                      # SyncManager for flushing pending_sync_queue
      vidyasetu_repository.dart  # Unified facade interface and HybridVidyaSetuRepository
    features/                    # UI presentation layer (screens, widgets, state management)
      # Future feature modules (e.g. diagnostics, practice, dashboard) plug in exclusively
      # through VidyaSetuRepository / VidyaSetuService facade.
```

### Architectural Invariant
- **No feature screen or widget in `lib/features/` should ever make direct HTTP calls or direct SQLite queries.**
- All UI components interact exclusively with the single `VidyaSetuRepository` (or `VidyaSetuService`) facade.

---

## 3. Strict 1:1 Schema Parity & Field Invariants

The Flutter models must mirror the backend Pydantic schemas with absolute precision:

### 3.1 Identifiers
- `student_id`, `progress_id`, `analysis_id`, and `question_id` must **always be lowercase UUID v4 strings** (e.g., `550e8400-e29b-41d4-a716-446655440000`).
- Never generate integer IDs or uppercase UUIDs on the mobile device.

### 3.2 Student Parameters Snapshot Categorical Labels
The `student_parameters_snapshot` must strictly use categorical string literals (matching `StudentParametersSnapshot` in `diagnostic_schema.py`):

```dart
class StudentParametersSnapshot {
  final String timeTaken;             // 'High' | 'Normal' | 'Low'
  final String confidenceLevel;       // 'High' | 'Normal' | 'Low'
  final String answerChanges;         // 'Frequent' | 'Occasional' | 'None'
  final String languagePreference;    // 'Odia' | 'English'
  final String conceptUnderstanding;  // 'Understood' | 'Weak'
  final String previousPerformance;   // 'Strong' | 'Weak'
  final String englishComprehension;  // 'Strong' | 'Weak'
}
```

### 3.3 Dual Metric Exposure (`english_comprehension` / `language_understanding`)
- Backend `ProgressResponse` exposes both `english_comprehension` (canonical) and `language_understanding` (`@computed_field` alias) as identical float values (`0.0` to `100.0`).
- The Flutter `ProgressModel` must expose both fields so that chart widgets and analytics widgets consume `language_understanding` without breaking canonical `english_comprehension` serialization.

### 3.4 UTC ISO-8601 Timestamps & Offline Creation Separation
- All timestamps must be serialized in **UTC ISO-8601** format (`YYYY-MM-DDTHH:MM:SS.mmmmmmZ` or `...Z`).
- Mobile-originated offline diagnostic events must preserve:
  - `offline_created_at`: The exact UTC timestamp recorded on-device when the student completed the attempt/probe in offline mode.
  - Server-managed timestamps like `created_at` or `batch_timestamp` represent sync or ingestion time and must **never overwrite** `offline_created_at`.

---

## 4. Offline-First Dynamic Routing & Engine Architecture

VidyaSetu is built for low-connectivity and rural 2G/3G environments. The app must operate fully without internet access and synchronize seamlessly when connected.

```
                         [ UI / Features Layer ]
                                   │
                                   ▼
                       [ VidyaSetuRepository ] (Facade)
                                   │
             ┌─────────────────────┴─────────────────────┐
             ▼ (Health Check: OK)                        ▼ (Health Check: Failed / Offline)
  [ CloudVidyaSetuRepository ]               [ OfflineVidyaSetuRepository ]
             │                                           │
      FastAPI Endpoints                         ┌────────┴────────┐
   (MongoDB + LangGraph WHY)                    ▼                 ▼
                                         [ SQLite DB ]    [ LocalSlmEngine ]
                                        (Curriculum +       (Edge SLM +
                                         Sync Queue)       Deterministic WHY)
```

### 4.1 Health Check & Connectivity Routing
- Automatic connectivity detection is performed via `GET /api/v1/health` with a fast timeout (2–3 seconds).
- When the health check succeeds (`status: "healthy"` or `"degraded"`), the facade routes requests through `CloudVidyaSetuRepository`.
- If the request fails, times out, or the device is in airplane mode, the facade transparently routes through `OfflineVidyaSetuRepository`.

### 4.2 Offline Repository Components
1. **Pre-packaged SQLite Database (`assets/db/offline_curriculum.db`)**:
   - On first run, copied to the device application support directory.
   - Contains offline question bank, 5 diagnostic probes per question, recovery questions, and FTS5 full-text search virtual tables for textbook RAG.
2. **Pure Dart Deterministic Mastery & Diagnostics**:
   - Implements the 7-parameter behavioral analyzer, root-cause hypothesis ranking (`careless_mistake`, `time_pressure`, `language_barrier`, `prerequisite_gap`, `conceptual_misunderstanding`), and mastery updating when offline.
3. **Pluggable `LocalSlmEngine` Interface**:
   - Clean abstraction (`Future<String> generate({required String prompt})`) allowing edge SLM inference via `llama_cpp_dart` or fallback mock engines during unit tests.
4. **`pending_sync_queue`**:
   - SQLite table storing un-synced `OfflineSyncEvent` records.
   - When connectivity is restored, `SyncManager` batches queued events and dispatches them via `POST /api/v1/sync/offline-analysis`.
   - Successful event IDs (`synced_ids` and `duplicate_ids`) are cleared from `pending_sync_queue`. Failed events are retained with backoff retry.

---

## 5. Environment Base URLs & Network Configuration

The Flutter app must dynamically resolve the backend API base URL depending on the runtime platform and compile-time configuration:

| Target Platform | Default API Base URL | Notes |
| :--- | :--- | :--- |
| **Android Emulator** | `http://10.0.2.2:8000/api/v1` | Maps to host machine's loopback interface |
| **Windows Desktop / Web** | `http://localhost:8000/api/v1` | Direct host localhost access |
| **Physical Android Device** | Configured via `--dart-define` | e.g. `http://<PC_LAN_IP>:8000/api/v1` |

### Configuration Pattern in Dart

```dart
class AppConfig {
  static const String _defaultUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_defaultUrl.isNotEmpty) {
      return _defaultUrl;
    }
    // Fallback based on runtime environment
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }
}
```

When running on a physical Android phone connected over local Wi-Fi:
```bash
flutter run --dart-define=API_BASE_URL=http://<PC_LAN_IP>:8000/api/v1
```
