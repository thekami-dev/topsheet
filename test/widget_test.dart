import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:topsheet/main.dart';

void main() {
  testWidgets('Home screen renders the form sections', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const TopsheetApp());
    await tester.pumpAndSettle();

    expect(find.text('Topsheet'), findsWidgets);
    expect(find.text('COURSE'), findsOneWidget);
    expect(find.text('EXPERIMENT'), findsOneWidget);
    expect(find.text('Generate PDF'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '1');
    await tester.pump();
  });
}
