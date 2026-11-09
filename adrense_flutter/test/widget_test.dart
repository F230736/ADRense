import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adrense_flutter/main.dart';

void main(){
  setUp(()=>FlutterSecureStorage.setMockInitialValues({}));
  testWidgets('ADRense opens its splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ADRense());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(ADRenseApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}

