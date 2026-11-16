import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:adrense_flutter/main.dart';
import 'package:adrense_flutter/services/api_service.dart';
import 'package:adrense_flutter/services/session_store.dart';

class MemorySessionStore implements SessionStore {
  String? token;
  @override Future<String?> read() async=>token;
  @override Future<void> write(String value) async{token=value;}
  @override Future<void> clear() async{token=null;}
}
Map<String,dynamic> account(String role)=>{'id':7,'name':'Saved Account','email':'saved@example.com','role':role,'status':'active','created_at':'2026-11-09T00:00:00','profile':null};
http.Response jsonResponse(Object value,[int code=200])=>http.Response(jsonEncode(value),code,headers:{'content-type':'application/json'});
ApiService service(MemorySessionStore store,{String role='patient',Future<http.Response> Function(http.Request)? handler})=>ApiService(sessionStore:store,client:MockClient(handler??(request)async{
  if(request.url.path.endsWith('/login'))return jsonResponse({'access_token':'saved-jwt','role':role});
  if(request.url.path.endsWith('/analysts'))return jsonResponse({'applications':[]});
  if(request.url.path.endsWith('/users'))return jsonResponse({'users':[]});
  if(request.url.path.endsWith('/registrations'))return jsonResponse({'summary':{'total':0,'general_users':0,'analysts':0,'active':0},'buckets':[]});
  return jsonResponse(account(role));
}));
Future<void> disposeApp(WidgetTester tester) async{await tester.pumpWidget(const SizedBox());await tester.pump(const Duration(seconds:5));}
void main(){
 test('Login persists only the token and a fresh instance validates it with the backend',()async{
  final store=MemorySessionStore();await service(store).login('saved@example.com','NeverStored@123');expect(store.token,'saved-jwt');
  final fresh=service(store,handler:(request)async{expect(request.url.path,'/api/auth/me');expect(request.headers['Authorization'],'Bearer saved-jwt');return jsonResponse(account('patient'));});
  expect((await fresh.restoreSession())!['name'],'Saved Account');
 });
 test('Missing saved session makes no backend request',()async{
  final api=service(MemorySessionStore(),handler:(_)async=>throw StateError('Unexpected request'));expect(await api.restoreSession(),isNull);
 });
 for(final status in [401,403]){
  test('Expired or revoked session ($status) is removed',()async{
   final store=MemorySessionStore()..token='old';final api=service(store,handler:(_)async=>jsonResponse({'detail':'Session expired'},status));expect(await api.restoreSession(),isNull);expect(store.token,isNull);
  });
 }
 test('A non-JSON unauthorized response still clears the saved token',()async{
  final store=MemorySessionStore()..token='old';final api=service(store,handler:(_)async=>http.Response('Unauthorized',401));expect(await api.restoreSession(),isNull);expect(store.token,isNull);
 });
 test('Connection failure preserves the saved session for retry',()async{
  final store=MemorySessionStore()..token='saved';final api=service(store,handler:(_)async=>throw http.ClientException('offline'));await expectLater(api.restoreSession(),throwsA(isA<AuthApiException>()));expect(store.token,'saved');
 });
 test('Server outage preserves the saved session',()async{
  final store=MemorySessionStore()..token='saved';await expectLater(service(store,handler:(_)async=>jsonResponse({'detail':'Unavailable'},503)).restoreSession(),throwsA(isA<AuthApiException>()));expect(store.token,'saved');
 });
 test('Logout removes persistence and prevents restoration by a new app instance',()async{
  final store=MemorySessionStore();final api=service(store);await api.login('saved@example.com','Password@123');await api.logout();expect(store.token,isNull);expect(await service(store).restoreSession(),isNull);
 });
 test('Logout during restoration cannot re-open the dashboard',()async{
  final store=MemorySessionStore()..token='old';final requested=Completer<void>(),response=Completer<http.Response>();
  final api=service(store,handler:(_)async{requested.complete();return response.future;});final restore=api.restoreSession();await requested.future;await api.logout();response.complete(jsonResponse(account('patient')));expect(await restore,isNull);expect(store.token,isNull);
 });
 test('Late unauthorized response cannot erase a newer login',()async{
  final store=MemorySessionStore()..token='old';final requested=Completer<void>(),oldResponse=Completer<http.Response>();
  final api=service(store,handler:(request)async{if(request.url.path.endsWith('/login'))return jsonResponse({'access_token':'new','role':'patient'});requested.complete();return oldResponse.future;});
  final restoring=api.restoreSession();await requested.future;await api.login('new@example.com','Password@123');oldResponse.complete(jsonResponse({'detail':'Expired'},401));expect(await restoring,isNull);expect(store.token,'new');
 });
 for(final role in ['patient','analyst','admin']){
  testWidgets('Cold start restores $role to the correct dashboard',(tester)async{
   final store=MemorySessionStore()..token='saved';await tester.pumpWidget(MaterialApp(home:ADRenseApp(api:service(store,role:role))));await tester.pump();await tester.pump(const Duration(seconds:1));
   final dynamic state=tester.state(find.byType(ADRenseApp));expect(state.restoringSession,false);expect(state.screen,role=='patient'?'home':role=='analyst'?'analystDash':'adminDash');expect(state.profile['Full Name'],'Saved Account');await disposeApp(tester);
  });
 }
 testWidgets('Offline startup offers retry and restores after the connection returns',(tester)async{
  final store=MemorySessionStore()..token='saved';var offline=true;
  final api=service(store,handler:(_)async{if(offline)throw http.ClientException('offline');return jsonResponse(account('patient'));});
  await tester.pumpWidget(MaterialApp(home:ADRenseApp(api:api)));await tester.pump();await tester.pump(const Duration(seconds:1));expect(find.text('Retry connection'),findsOneWidget);expect(store.token,'saved');
  offline=false;await tester.tap(find.text('Retry connection'));await tester.pump();await tester.pump(const Duration(seconds:1));final dynamic state=tester.state(find.byType(ADRenseApp));expect(state.screen,'home');await disposeApp(tester);
 });
 testWidgets('Invalid saved session returns to splash',(tester)async{
  final store=MemorySessionStore()..token='expired';await tester.pumpWidget(MaterialApp(home:ADRenseApp(api:service(store,handler:(_)async=>jsonResponse({'detail':'expired'},401)))));await tester.pump();await tester.pump(const Duration(seconds:1));
  final dynamic state=tester.state(find.byType(ADRenseApp));expect(state.screen,'splash');expect(state.restoringSession,false);expect(store.token,isNull);await disposeApp(tester);
 });
}
