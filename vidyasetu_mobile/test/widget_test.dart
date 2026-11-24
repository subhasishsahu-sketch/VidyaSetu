import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidyasetu_mobile/app/app.dart';
import 'package:vidyasetu_mobile/features/dev/integration_smoke_screen.dart';

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
}
