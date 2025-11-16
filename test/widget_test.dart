import 'package:flutter_test/flutter_test.dart';
import 'package:campus_navigation/main.dart';

void main() {
  testWidgets('App boots in testMode and shows title immediately', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusNavigationApp(testMode: true));
    expect(find.text('CampusNav'), findsOneWidget);
  });

  testWidgets('No pending timers or frames in testMode', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusNavigationApp(testMode: true));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(find.text('CampusNav'), findsOneWidget);
  });
}
