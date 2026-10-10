import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/app.dart';

void main() {
  testWidgets('given the app starts, it shows the placeholder home screen', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: HostelHiveApp()));
    await tester.pumpAndSettle();

    expect(find.text('HostelHive'), findsOneWidget);
  });
}
