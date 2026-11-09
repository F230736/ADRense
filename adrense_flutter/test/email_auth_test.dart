import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adrense_flutter/main.dart';
import 'package:adrense_flutter/services/api_service.dart';

class FakeAuthApi extends ApiService {
  int sends=0, verifications=0, resets=0;
  @override Future<Map<String,dynamic>> requestCode(String email,{required bool reset}) async {sends++;return {'message':'If an account exists with this email, a code has been sent.'};}
  @override Future<Map<String,dynamic>> verifyEmail(String email,String code) async {verifications++;return {'message':'Email verified. Sign in to continue.'};}
  @override Future<Map<String,dynamic>> resetPassword(String email,String code,String password,String confirmation) async {resets++;return {'message':'Password updated. Please sign in.'};}
}
void main(){
  setUp(()=>FlutterSecureStorage.setMockInitialValues({}));
  testWidgets('Registration accepts its already-sent code and completes verification',(tester) async {
    final api=FakeAuthApi();
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:EmailAuthScreen(api:api,reset:false,initialEmail:'person@example.com',initiallySent:true,onBack:(){}))));
    expect(find.text('Six-digit email code'),findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1),'123456');
    await tester.ensureVisible(find.widgetWithText(FilledButton,'Verify email'));
    await tester.tap(find.widgetWithText(FilledButton,'Verify email'));await tester.pump();
    expect(api.verifications,1);expect(find.text('Email verified'),findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Recovery uses generic response and rejects mismatched passwords',(tester) async {
    final api=FakeAuthApi();
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:EmailAuthScreen(api:api,reset:true,initialEmail:'person@example.com',onBack:(){}))));
    await tester.tap(find.widgetWithText(FilledButton,'Send code'));await tester.pump();
    expect(api.sends,1);expect(find.textContaining('If an account exists'),findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1),'123456');
    await tester.enterText(find.byType(TextFormField).at(2),'Replacement@123');
    await tester.enterText(find.byType(TextFormField).at(3),'Different@123');
    await tester.ensureVisible(find.widgetWithText(FilledButton,'Update password'));
    await tester.tap(find.widgetWithText(FilledButton,'Update password'));await tester.pump();
    expect(api.resets,0);expect(find.text('Passwords do not match'),findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(3),'Replacement@123');
    await tester.ensureVisible(find.widgetWithText(FilledButton,'Update password'));
    await tester.tap(find.widgetWithText(FilledButton,'Update password'));await tester.pump();
    expect(api.resets,1);expect(find.text('Password updated'),findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
