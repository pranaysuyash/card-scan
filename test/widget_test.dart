import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:card_scan/main.dart';
import 'package:card_scan/models/contact.dart';
import 'package:card_scan/providers/contact_provider.dart';

void main() {
  late Isar isar;

  setUp(() async {
    // Initialize Isar for testing
    isar = await Isar.open(
      [ContactSchema],
      directory: '',
      name: 'test_db',
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  testWidgets('App initializes and shows home screen', (WidgetTester tester) async {
    // Build our app with test database
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(isar),
        ],
        child: const QuantumCardScannerApp(),
      ),
    );

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that the app loaded successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Home screen displays empty state when no contacts', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(isar),
        ],
        child: const QuantumCardScannerApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Should show empty state message
    expect(find.textContaining('No contacts'), findsWidgets);
  });
}
