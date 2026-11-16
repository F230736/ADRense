import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:adrense_flutter/main.dart';
import 'package:adrense_flutter/services/api_service.dart';
import 'persistent_session_test.dart' as fixtures;

class ProfileApi extends ApiService {
 ProfileApi():super(sessionStore:fixtures.MemorySessionStore());
 Map<String,dynamic> user={...fixtures.account('patient'),'profile':{'age_group':'18–25','gender':'Other','weight_range':'50–70kg','medical_conditions':['Old condition'],'current_medications':['Medicine A'],'allergies':['Penicillin'],'medication_doses':{'Medicine A':'10mg daily'}}};
 final List<Map<String,dynamic>> patches=[];
 String? requestedEmail;
 bool fail=false;
 Map<String,dynamic>? registration;
 Map<String,dynamic> snapshot()=>Map<String,dynamic>.from(jsonDecode(jsonEncode(user)) as Map);
 @override Future<Map<String,dynamic>?> restoreSession() async=>null;
 @override Future<Map<String,dynamic>> updateProfile(Map<String,dynamic> changes) async {
  if(fail)throw const AuthApiException('Save failed. Please retry.');
  patches.add(changes);
  for(final entry in changes.entries){if(entry.key=='name'){user['name']=entry.value;}else{(user['profile'] as Map)[entry.key]=entry.value;}}
  return {'user':snapshot()};
 }
 @override Future<Map<String,dynamic>> requestEmailChange(String email) async{requestedEmail=email;return {'email':email,'retry_after':60};}
 @override Future<Map<String,dynamic>> confirmEmailChange(String email,String code) async {
  if(code!='123456')throw const AuthApiException('Invalid or expired code.');
  user['email']=email;return {'user':snapshot(),'access_token':'rotated'};
 }
 @override Future<Map<String,dynamic>> register(Map<String,dynamic> fields) async{registration=Map<String,dynamic>.from(jsonDecode(jsonEncode(fields)) as Map);return {'message':'Account created'};}
}
Future<dynamic> mountProfile(WidgetTester tester,ProfileApi api)async{
 tester.view.physicalSize=const Size(393,1100);tester.view.devicePixelRatio=1;
 await tester.pumpWidget(MaterialApp(home:ADRenseApp(api:api)));await tester.pump();await tester.pump(const Duration(seconds:1));
 final dynamic state=tester.state(find.byType(ADRenseApp));await state.openAuthenticatedUser(api.snapshot());await state.go('healthProfile');await tester.pumpAndSettle();return state;
}
Future<void> sectionEdit(WidgetTester tester,String label)async{
 final row=find.ancestor(of:find.text(label).first,matching:find.byType(Row)).first;
 final edit=find.descendant(of:row,matching:find.text('Edit')).first;await tester.ensureVisible(edit);await tester.tap(edit);await tester.pumpAndSettle();
}
Future<void> finish(WidgetTester tester)async{await fixtures.disposeApp(tester);tester.view.resetPhysicalSize();tester.view.resetDevicePixelRatio();}
void main(){
 testWidgets('Basic info saves authoritative server data and failed saves do not mutate it',(tester)async{
  final api=ProfileApi();final state=await mountProfile(tester,api);expect(state.profile['Weight Range'],'50–70kg');
  await sectionEdit(tester,'Basic Information');await sectionEdit(tester,'Full Name');await tester.enterText(find.byKey(const ValueKey('basic-Full Name')),'Updated Person');
  await tester.tap(find.text('Save'));await tester.pumpAndSettle();expect(api.patches.last,{'name':'Updated Person'});expect(state.profile['Full Name'],'Updated Person');
  await sectionEdit(tester,'Full Name');api.fail=true;await tester.enterText(find.byKey(const ValueKey('basic-Full Name')),'Unsaved Person');await tester.tap(find.text('Save'));await tester.pumpAndSettle();
  expect(state.profile['Full Name'],'Updated Person');expect(find.text('Save failed. Please retry.'),findsOneWidget);await finish(tester);
 });
 testWidgets('Conditions, medications and allergies persist Add, Save and Remove actions',(tester)async{
  final api=ProfileApi();final state=await mountProfile(tester,api);final previous=List<String>.from(state.profileLists['Previous ADRs']);
  await sectionEdit(tester,'Medical Conditions');await tester.ensureVisible(find.text('Add condition'));await tester.tap(find.text('Add condition'));await tester.pump();
  await tester.enterText(find.byKey(const ValueKey('profile-item-Medical Conditions-null')),'New condition');await tester.tap(find.widgetWithText(TextButton,'Add'));await tester.pumpAndSettle();expect(api.patches.last['medical_conditions'],['Old condition','New condition']);
  await tester.ensureVisible(find.byTooltip('Remove New condition'));await tester.tap(find.byTooltip('Remove New condition'));await tester.pumpAndSettle();expect(api.patches.last['medical_conditions'],['Old condition']);
  await sectionEdit(tester,'Current Medications');final row=find.ancestor(of:find.text('Medicine A').first,matching:find.byType(Row)).first;final edit=find.descendant(of:row,matching:find.text('Edit'));await tester.ensureVisible(edit);await tester.tap(edit);await tester.pump();
  await tester.enterText(find.byKey(const ValueKey('profile-dose-Medicine A')),'20mg daily');await tester.ensureVisible(find.widgetWithText(TextButton,'Save'));await tester.tap(find.widgetWithText(TextButton,'Save'));await tester.pumpAndSettle();expect(api.patches.last['medication_doses'],{'Medicine A':'20mg daily'});
  await sectionEdit(tester,'Allergies');await tester.ensureVisible(find.byTooltip('Remove Penicillin'));await tester.tap(find.byTooltip('Remove Penicillin'));await tester.pumpAndSettle();expect(api.patches.last['allergies'],[]);expect(state.profileLists['Previous ADRs'],previous);await finish(tester);
 });
 testWidgets('Email is unchanged until the new-address OTP succeeds',(tester)async{
  final api=ProfileApi();final state=await mountProfile(tester,api);final original=state.profile['Email'];
  await sectionEdit(tester,'Basic Information');await sectionEdit(tester,'Email');await tester.enterText(find.byKey(const ValueKey('basic-Email')),'new@example.com');await tester.tap(find.text('Save'));await tester.pumpAndSettle();
  expect(api.requestedEmail,'new@example.com');expect(state.profile['Email'],original);expect(api.patches,isEmpty);
  final code=find.byWidgetPredicate((widget)=>widget is TextField&&widget.decoration?.labelText=='6-digit code');
  await tester.enterText(code,'654321');await tester.tap(find.text('Verify & update'));await tester.pumpAndSettle();expect(find.text('Invalid or expired code.'),findsOneWidget);expect(state.profile['Email'],original);
  await tester.enterText(code,'123456');await tester.tap(find.text('Verify & update'));await tester.pumpAndSettle();expect(state.profile['Email'],'new@example.com');expect(find.text('Verify new email'),findsNothing);await finish(tester);
 });
 testWidgets('Registration collects and sends allergies',(tester)async{
  final api=ProfileApi();tester.view.physicalSize=const Size(393,1100);tester.view.devicePixelRatio=1;
  await tester.pumpWidget(MaterialApp(home:ADRenseApp(api:api)));await tester.pump();await tester.pump(const Duration(seconds:1));
  final dynamic state=tester.state(find.byType(ADRenseApp));state.updateView((){state.screen='login';state.register=true;state.regStep=2;});await tester.pumpAndSettle();
  final allergy=find.byKey(const ValueKey('input-Allergies-0'));await tester.ensureVisible(allergy);await tester.enterText(allergy,'Latex');final row=find.ancestor(of:allergy,matching:find.byType(Row)).first;await tester.tap(find.descendant(of:row,matching:find.byType(FilledButton)));await tester.pump();
  state.registrationData.addAll({'Full Name':'Test Person','Email Address':'saved@example.com','Password':'Original@123','Age group':'18–25','Biological sex':'Other'});await state.registerWithBackend();await tester.pump();expect(api.registration!['allergies'],['Latex']);await finish(tester);
 });
 test('Successful email confirmation replaces the persisted access token',()async{
  final store=fixtures.MemorySessionStore()..token='old';
  final api=ApiService(sessionStore:store,client:MockClient((request)async{
   if(request.url.path.endsWith('/confirm'))return fixtures.jsonResponse({'user':fixtures.account('patient'),'access_token':'replacement'});
   expect(request.headers['Authorization'],request.url.path.endsWith('/me')&&store.token=='replacement'?'Bearer replacement':'Bearer old');return fixtures.jsonResponse(fixtures.account('patient'));
  }));
  await api.restoreSession();await api.confirmEmailChange('new@example.com','123456');expect(store.token,'replacement');await api.me();
 });
}
