import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/entries.dart';
import 'support/harness.dart';

void main() {
  testWidgets('Settings shows a Ko-fi support row and a beta version line', (
    tester,
  ) async {
    await pumpPinbox(tester, seed: [entry()]);
    await tapPin(tester, testPin);
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);

    // The Support/About section sits below the fold in the settings list.
    await tester.scrollUntilVisible(
      find.text('SUPPORT'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await settle(tester);

    expect(find.text('SUPPORT'), findsOneWidget);
    expect(find.text('Support Pinbox'), findsOneWidget);
    expect(find.text('Buy me a coffee on Ko-fi'), findsOneWidget);

    // The mocked package_info values from the test harness, with the beta tag.
    expect(find.text('Pinbox 1.0.0 (Beta) · Build 1'), findsOneWidget);
  });
}
