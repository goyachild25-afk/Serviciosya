import 'package:flutter_test/flutter_test.dart';
import 'package:yalo/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    expect(YALOApp, isNotNull);
  });
}
