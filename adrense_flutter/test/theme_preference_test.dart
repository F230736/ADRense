import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:adrense_flutter/main.dart';
import 'package:adrense_flutter/services/theme_preference_store.dart';
import 'persistent_session_test.dart' as fixtures;

void main(){
 setUp(()=>SharedPreferencesAsyncPlatform.instance=InMemorySharedPreferencesAsync.empty());
 tearDown(()=>P.light=true);
 test('Theme preferences survive a new store instance and rapid toggles retain the last choice',()async{
  final store=LocalThemePreferenceStore();expect(await store.readLightMode(),isNull);
  await store.saveLightMode(false);expect(await LocalThemePreferenceStore().readLightMode(),false);
  await Future.wait([store.saveLightMode(false),store.saveLightMode(true),store.saveLightMode(false)]);
  expect(await LocalThemePreferenceStore().readLightMode(),false);
 });
 testWidgets('Selected dark mode survives logout and a fresh app instance',(tester)async{
  await tester.pumpWidget(MaterialApp(home:ADRenseApp(api:fixtures.service(fixtures.MemorySessionStore()))));await tester.pump();await tester.pump(const Duration(seconds:1));
  dynamic state=tester.state(find.byType(ADRenseApp));expect(state.lightMode,true);
  await state.toggleTheme();await tester.pump();expect(state.lightMode,false);expect(await LocalThemePreferenceStore().readLightMode(),false);
  await state.go('login');await tester.pump();expect(await LocalThemePreferenceStore().readLightMode(),false);
  await fixtures.disposeApp(tester);P.light=true;
  await tester.pumpWidget(MaterialApp(home:ADRenseApp(api:fixtures.service(fixtures.MemorySessionStore()))));await tester.pump();await tester.pump(const Duration(seconds:1));
  state=tester.state(find.byType(ADRenseApp));expect(state.lightMode,false);expect(P.light,false);expect(Theme.of(tester.element(find.byType(Scaffold))).brightness,Brightness.dark);
  await state.toggleTheme();await tester.pump();expect(await LocalThemePreferenceStore().readLightMode(),true);
  await fixtures.disposeApp(tester);
 });
}
