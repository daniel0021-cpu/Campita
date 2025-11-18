// Basic Flutter widget tests for Campus Navigation App

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_navigation/main.dart';

void main() {
  testWidgets('App starts and shows splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const CampusNavigationApp());

    // Verify splash screen elements are present
    expect(find.text('Igbinedion University'), findsOneWidget);
    expect(find.text('Campus Navigation'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('App navigates to home screen after splash', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const CampusNavigationApp());

    // Wait for splash screen animation and navigation
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify we're on the home screen (EnhancedCampusMap)
    // The bottom navigation bar should be present
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });

  testWidgets('Home screen has search bar', (WidgetTester tester) async {
    // Build our app and navigate past splash
    await tester.pumpWidget(const CampusNavigationApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify search bar is present
    expect(find.text('Search campus buildings...'), findsOneWidget);
  });
}
