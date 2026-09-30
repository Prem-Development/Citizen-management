import 'package:flutter_test/flutter_test.dart';
import 'package:gs_app/main.dart';

void main() {
  testWidgets('App smoke test - renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const GSApp());
    expect(find.byType(GSApp), findsOneWidget);
  });
}
