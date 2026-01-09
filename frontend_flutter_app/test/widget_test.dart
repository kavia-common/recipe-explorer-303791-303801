import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter_app/main.dart';

void main() {
  testWidgets('Shows Home tab by default with bottom navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // App bar title for the default tab.
    expect(find.text('Home'), findsOneWidget);

    // Bottom navigation items exist.
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.search_outlined), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);

    // Placeholder content is visible.
    expect(find.text('Featured Recipes'), findsOneWidget);
  });

  testWidgets('Switching tabs updates the app bar title and content',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Go to Search tab.
    await tester.tap(find.byIcon(Icons.search_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Search Recipes'), findsOneWidget);

    // Go to Favorites tab.
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Your Favorites'), findsOneWidget);
  });
}
