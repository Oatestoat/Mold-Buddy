import 'package:flutter_test/flutter_test.dart';
import 'package:mold_awareness_app/main.dart';

void main() {
  testWidgets('App opens', (WidgetTester tester) async {
    await tester.pumpWidget(const MoldCoachApp());

    expect(
      find.text('Here is how your home is doing today.'),
      findsOneWidget,
    );
  });
}