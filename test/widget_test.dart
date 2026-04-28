import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_produk/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SurveyProdukApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
