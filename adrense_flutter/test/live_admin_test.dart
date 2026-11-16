import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:adrense_flutter/main.dart';
import 'package:adrense_flutter/services/api_service.dart';
import 'package:adrense_flutter/views/admin/registration_chart.dart';
import 'package:adrense_flutter/core/theme/adrense_theme.dart';

class LiveAdminApi extends ApiService {
 final List<int> ranges=[];
 @override Future<Map<String,dynamic>> registrationStatistics(int days) async {
  ranges.add(days);
  return {'summary':{'total':3,'general_users':2,'analysts':1,'active':2},'buckets':[
   {'date':'2026-11-07','general_users':2,'analysts':0},
   {'date':'2026-11-08','general_users':0,'analysts':1},
  ]};
 }
 @override Future<Map<String,dynamic>> adminUsers() async => {'users':[
  {'id':10,'name':'Real General','email':'real@example.com','role':'patient','status':'active','email_verified':true,'created_at':'2026-11-07T00:00:00'},
  {'id':11,'name':'Real Analyst','email':'analyst@example.com','role':'analyst','status':'pending','email_verified':true,'created_at':'2026-11-08T00:00:00'},
 ]};
}
void main(){
  setUp(()=>FlutterSecureStorage.setMockInitialValues({}));
 testWidgets('Registration chart switches range, colors and series visibility',(tester) async {
  tester.view.physicalSize=const Size(393,1000);tester.view.devicePixelRatio=1;
  final api=LiveAdminApi();Map<String,dynamic>? summary;
  await tester.pumpWidget(MaterialApp(theme:AdrenseTheme.build(true),home:Scaffold(body:SingleChildScrollView(child:RegistrationChart(api:api,onSummary:(value)=>summary=value)))));
  await tester.pumpAndSettle();expect(summary!['total'],3);expect(api.ranges,[30]);expect(find.byType(LineChart),findsOneWidget);
  var chart=tester.widget<LineChart>(find.byType(LineChart));expect(chart.data.lineBarsData.length,2);expect(chart.data.lineBarsData[0].color,isNot(chart.data.lineBarsData[1].color));
  await tester.tap(find.text('7D'));await tester.pumpAndSettle();expect(api.ranges,[30,7]);
  await tester.tap(find.text('General users  2'));await tester.pumpAndSettle();chart=tester.widget<LineChart>(find.byType(LineChart));expect(chart.data.lineBarsData.length,1);
  expect(tester.takeException(),isNull);await tester.pumpWidget(const SizedBox());tester.view.resetPhysicalSize();tester.view.resetDevicePixelRatio();
 });
 testWidgets('User management loads database accounts and filters by search and role',(tester) async {
  tester.view.physicalSize=const Size(393,1000);tester.view.devicePixelRatio=1;
  await tester.pumpWidget(MaterialApp(home:ADRenseApp(api:LiveAdminApi())));await tester.pump(const Duration(seconds:5));
  final dynamic state=tester.state(find.byType(ADRenseApp));state.updateView((){state.role='admin';state.screen='adminDash';state.adminTab='Users';});
  await tester.pumpAndSettle();await tester.tap(find.text('Refresh'));await tester.pumpAndSettle();
  expect(find.text('Real General'),findsOneWidget);expect(find.text('Real Analyst'),findsOneWidget);expect(find.text('Sara Ahmed'),findsNothing);
  final search=find.byWidgetPredicate((widget)=>widget is TextField&&widget.decoration?.hintText=='Search by name or email...');
  await tester.enterText(search,'real@example.com');await tester.pump();expect(find.text('Real General'),findsOneWidget);expect(find.text('Real Analyst'),findsNothing);
  await tester.enterText(search,'');await tester.tap(find.text('Analysts'));await tester.pump();expect(find.text('Real Analyst'),findsOneWidget);expect(find.text('Real General'),findsNothing);
  expect(tester.takeException(),isNull);await tester.pumpWidget(const SizedBox());await tester.pump(const Duration(seconds:5));tester.view.resetPhysicalSize();tester.view.resetDevicePixelRatio();
 });
 testWidgets('Overview renders chart and summary cards without border paint errors',(tester) async {
  await tester.pumpWidget(MaterialApp(home:ADRenseApp(api:LiveAdminApi())));await tester.pump(const Duration(seconds:5));
  final dynamic state=tester.state(find.byType(ADRenseApp));state.updateView((){state.role='admin';state.screen='adminDash';state.adminTab='Overview';});
  await tester.pumpAndSettle();expect(find.text('User registrations'),findsOneWidget);expect(find.text('Registered Accounts'),findsOneWidget);expect(tester.takeException(),isNull);
  await tester.pumpWidget(const SizedBox());await tester.pump(const Duration(seconds:5));
 });
}
