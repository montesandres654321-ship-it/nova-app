// test/widget_test.dart
// ✅ VERSIÓN CORREGIDA

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_dashboard/main.dart';

void main() {
  testWidgets('Dashboard app starts correctly', (WidgetTester tester) async {
    // ✅ CORREGIDO: MyApp (no NovaDashboardApp)
    await tester.pumpWidget(const MyApp());

    // Wait for animations
    await tester.pumpAndSettle();

    // ✅ CORREGIDO: Buscar elementos del LoginPage
    // Ajusta estos según tu LoginPage real
    expect(find.byType(TextField), findsWidgets);
    expect(find.byType(ElevatedButton), findsWidgets);
  });

  testWidgets('Login form validation works', (WidgetTester tester) async {
    // ✅ CORREGIDO: MyApp
    await tester.pumpWidget(const MyApp());

    await tester.pumpAndSettle();

    // Find login button (ajusta según tu UI)
    final loginButton = find.byType(ElevatedButton).first;

    // Try to login without credentials
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Should stay on login page or show error
    expect(find.byType(TextField), findsWidgets);
  });
}