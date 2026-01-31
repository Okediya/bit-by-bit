// Basic test for Bit by Bit app
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bit_by_bit/main.dart';

void main() {
  testWidgets('App should render without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BitByBitApp()));
    await tester.pumpAndSettle();
    
    // Verify app title is present
    expect(find.text('Bit by Bit'), findsWidgets);
  });
}
