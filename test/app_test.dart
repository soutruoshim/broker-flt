import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ebroker/main.dart' as app;

///Testing eBroker application for version v1.0.3
void main() {
  group("Login test", () {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

    testWidgets("Login test", (widgetTester) async {
      app.main();

      await widgetTester.pumpAndSettle();

      // Finder onboardinText = find.byKey(const Key("onboarding_title"));

      final logo = find.byKey(const Key("onboarding_title"));
      await widgetTester.pumpAndSettle(const Duration(seconds: 10));
      expect(logo, findsOneWidget);

      await widgetTester.pumpAndSettle(const Duration(seconds: 1));
      final button = find.byKey(const ValueKey("next_screen"));
      await widgetTester.pumpAndSettle(const Duration(seconds: 1));

      await widgetTester.tap(button);

      // expect(find.text("Welcome To eBroker"), findsOneWidget);
      // await widgetTester.tap(find.byKey(const Key("next_screen")));
      // await widgetTester.pumpAndSettle();

      // expect(find.textContaining("Find your").first, findsOneWidget);
      // await widgetTester.pumpAndSettle();

      // expect(onboardinText,);
    });
    // testWidgets("Login", (widgetTester) {});
  });
}
