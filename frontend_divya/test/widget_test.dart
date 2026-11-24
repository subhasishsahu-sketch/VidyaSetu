import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidyasetu/app/app.dart';

void main() {
  testWidgets('VidyaSetu Home Screen renders and language toggles cleanly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: VidyaSetuApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify app bar / header items exist
    expect(find.textContaining('Sunita'), findsOneWidget);
    expect(find.textContaining('Class 10'), findsWidgets);

    // Verify Language toggle pill exists
    final odiaButton = find.text('ଓଡ଼ିଆ');
    final englishButton = find.text('English');
    expect(odiaButton, findsOneWidget);
    expect(englishButton, findsOneWidget);

    // Tap English button
    await tester.tap(englishButton);
    await tester.pumpAndSettle();

    // Verify English text is active
    expect(find.textContaining('Good Afternoon'), findsOneWidget);

    // Tap Odia button
    await tester.tap(odiaButton);
    await tester.pumpAndSettle();

    // Verify Odia greeting
    expect(find.textContaining('ନମସ୍କାର'), findsOneWidget);
  });
}
