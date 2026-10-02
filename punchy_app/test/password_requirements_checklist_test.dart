import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:punchy_app/core/widgets/password_requirements_checklist.dart';

void main() {
  testWidgets(
    'checklist reacts to typing, deleting, replacing, and pasted text',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(controller: controller),
                PasswordRequirementsChecklist(controller: controller),
              ],
            ),
          ),
        ),
      );

      expect(find.text('•'), findsNWidgets(4));
      expect(find.text('✓'), findsNothing);

      await tester.enterText(find.byType(TextField), 'password');
      await tester.pumpAndSettle();
      expect(find.text('✓'), findsNWidgets(2));

      await tester.enterText(find.byType(TextField), 'Password1');
      await tester.pumpAndSettle();
      expect(find.text('✓'), findsNWidgets(4));

      await tester.enterText(find.byType(TextField), 'Pass1');
      await tester.pumpAndSettle();
      expect(find.text('✓'), findsNWidgets(3));

      await tester.enterText(find.byType(TextField), 'Pasted123');
      await tester.pumpAndSettle();
      expect(find.text('✓'), findsNWidgets(4));

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.text('•'), findsNWidgets(4));
      expect(find.text('✓'), findsNothing);
    },
  );
}
