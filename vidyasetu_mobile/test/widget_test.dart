import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidyasetu_mobile/app/app.dart';
import 'package:vidyasetu_mobile/data/models/student_model.dart';
import 'package:vidyasetu_mobile/features/dev/integration_smoke_screen.dart';
import 'package:vidyasetu_mobile/features/home/screens/home_screen.dart';
import 'package:vidyasetu_mobile/features/home/widgets/goal_ring.dart';
import 'package:vidyasetu_mobile/models/subject.dart';
import 'package:vidyasetu_mobile/state/roadmap_provider.dart';
import 'package:vidyasetu_mobile/state/student_profile_provider.dart';

class _FakeStudentProfileNotifier extends StateNotifier<StudentProfileState>
    implements StudentProfileNotifier {
  _FakeStudentProfileNotifier(StudentProfileState state) : super(state);

  @override
  Future<void> loadProfile() async {}

  @override
  Future<void> addStudyTime(int minutes) async {}
}

class _FakeRoadmapNotifier extends StateNotifier<RoadmapState>
    implements RoadmapNotifier {
  _FakeRoadmapNotifier(RoadmapState state) : super(state);

  @override
  Future<void> loadRoadmap() async {}

  @override
  Future<void> selectSubject(String subjectId) async {}

  @override
  void toggleChapterExpanded(String chapterId) {}
}

void main() {
  testWidgets('VidyaSetuApp initial pump smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: VidyaSetuApp(),
      ),
    );
    await tester.pump();

    // Verify key UI text renders without error
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('IntegrationSmokeScreen widget smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: IntegrationSmokeScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('VidyaSetu Integration Smoke Screen'), findsOneWidget);
    expect(find.text('1. Check Backend Health'), findsOneWidget);
    expect(find.text('2. Register Demo Student & Load Questions'), findsOneWidget);
    expect(find.text('3. Download History Offline Pack'), findsOneWidget);
    expect(find.text('4. Run Offline Autopsy (Attempt -> Probe -> Recovery)'), findsOneWidget);
    expect(find.text('5. Sync Offline Queue to MongoDB'), findsOneWidget);
  });

  testWidgets('HomeScreen pumps cleanly with real StudentModel instance without NoSuchMethodError',
      (WidgetTester tester) async {
    final realStudent = StudentModel(
      studentId: '550e8400-e29b-41d4-a716-446655440000',
      name: 'Sunita Majhi',
      classGrade: 10,
      preferredLanguage: 'Odia',
      englishExposureLevel: 1,
      subject: 'History',
      completedChapters: 2,
      createdAt: DateTime.utc(2026, 11, 24),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentProfileProvider.overrideWith(
            (ref) => _FakeStudentProfileNotifier(
              StudentProfileState(
                student: realStudent,
                isLoading: false,
              ),
            ),
          ),
          roadmapProvider.overrideWith(
            (ref) => _FakeRoadmapNotifier(
              const RoadmapState(
                isLoading: false,
                subjects: [
                  Subject(
                    id: 'hist',
                    nameEn: 'History',
                    nameOr: 'ଇତିହାସ',
                    code: 'HIS',
                    icon: 'history_edu',
                    totalChapters: 4,
                    completedChapters: 1,
                    masteryPercent: 42,
                    isCached: true,
                  ),
                ],
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    // Verify HomeScreen renders with real StudentModel without crashing on goalPercentage
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(GoalRing), findsOneWidget);
    expect(find.text('Sunita Majhi | Class 10'), findsOneWidget);
  });
}
