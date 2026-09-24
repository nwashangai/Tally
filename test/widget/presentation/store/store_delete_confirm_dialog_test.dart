import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/domain/store/store.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/presentation/store/widgets/store_delete_confirm_dialog.dart';

void main() {
  final testStore = Store(
    id: const StoreId('store_123'),
    name: 'Apex Supermarket',
    ownerId: 'owner_1',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  group('StoreDeleteConfirmDialog', () {
    testWidgets('renders warning, store name, and disabled delete button initially',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreDeleteConfirmDialog(store: testStore),
          ),
        ),
      );

      expect(find.text('Delete Store'), findsNWidgets(2)); // Title and Button
      expect(
        find.textContaining('Apex Supermarket', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Warning: This action is permanent'),
        findsOneWidget,
      );
      expect(find.text('Type "delete" to confirm:'), findsOneWidget);

      // Find the Delete Store elevated button
      final deleteBtnFinder = find.widgetWithText(ElevatedButton, 'Delete Store');
      expect(deleteBtnFinder, findsOneWidget);

      final deleteBtn = tester.widget<ElevatedButton>(deleteBtnFinder);
      expect(deleteBtn.onPressed, isNull); // Disabled
    });

    testWidgets('keeps button disabled when input does not match "delete"',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreDeleteConfirmDialog(store: testStore),
          ),
        ),
      );

      final deleteBtnFinder = find.widgetWithText(ElevatedButton, 'Delete Store');
      final inputFinder = find.byType(TextField);

      await tester.enterText(inputFinder, 'delet');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(deleteBtnFinder).onPressed, isNull);

      await tester.enterText(inputFinder, 'deleter');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(deleteBtnFinder).onPressed, isNull);

      await tester.enterText(inputFinder, 'cancel');
      await tester.pump();
      expect(tester.widget<ElevatedButton>(deleteBtnFinder).onPressed, isNull);
    });

    testWidgets(
        'enables button when "delete" is entered case-insensitively and returns true on tap',
        (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (_) => StoreDeleteConfirmDialog(store: testStore),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final deleteBtnFinder = find.widgetWithText(ElevatedButton, 'Delete Store');
      final inputFinder = find.byType(TextField);

      // Test uppercase "DELETE"
      await tester.enterText(inputFinder, 'DELETE');
      await tester.pump();
      expect(
        tester.widget<ElevatedButton>(deleteBtnFinder).onPressed,
        isNotNull,
      );

      // Test mixed case "DeLeTe"
      await tester.enterText(inputFinder, 'DeLeTe');
      await tester.pump();
      expect(
        tester.widget<ElevatedButton>(deleteBtnFinder).onPressed,
        isNotNull,
      );

      // Tap Delete Store
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('returns false/null when Cancel is tapped', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (_) => StoreDeleteConfirmDialog(store: testStore),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}
