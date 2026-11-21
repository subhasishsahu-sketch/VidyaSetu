import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vidyasetu_mobile/main.dart';

void main() {
  testWidgets('OfflineRagSlmTestScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OfflineRagSlmTestScreen()));
    expect(find.text('VidyaSetu Offline RAG + SLM'), findsOneWidget);
    expect(find.text('Generate Questions'), findsOneWidget);
    expect(find.text('Explain Concept'), findsOneWidget);
  });
}
