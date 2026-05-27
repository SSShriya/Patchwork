import 'package:flutter_test/flutter_test.dart';
import 'package:drp/main.dart';

void main() {
  testWidgets('HomeScreen has a title and two sections', (WidgetTester tester) async {
    await tester.pumpWidget(const MainApp());

    // Verify the app bar title
    expect(find.text('Home'), findsOneWidget);

    // Verify the section titles
    expect(find.text('Recommended Events'), findsOneWidget);
    expect(find.text('Matches'), findsOneWidget);
  });
}
