import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adrense_flutter/main.dart';

Future<dynamic> showStep(WidgetTester tester,int step,{bool light=true}) async {
 tester.view.physicalSize=const Size(393,1000);tester.view.devicePixelRatio=1;
 await tester.pumpWidget(const ADRense());await tester.pump(const Duration(seconds:5));
 final dynamic state=tester.state(find.byType(ADRenseApp));
 state.updateView((){state.screen='login';state.register=true;state.role='analyst';state.regStep=step;state.lightMode=light;P.light=light;});
 await tester.pumpAndSettle();return state;
}
Future<void> disposeApp(WidgetTester tester) async {
 await tester.pumpWidget(const SizedBox());await tester.pump(const Duration(seconds:5));
 tester.view.resetPhysicalSize();tester.view.resetDevicePixelRatio();P.light=true;
}
void main(){
  setUp(()=>FlutterSecureStorage.setMockInitialValues({}));
 for(final light in [true,false]){
  testWidgets('Country and calling-code selectors work in ${light?'light':'dark'} theme',(tester) async {
   final state=await showStep(tester,1,light:light);
   expect(find.text('+92'),findsOneWidget);
   await tester.ensureVisible(find.text('Select country'));await tester.tap(find.text('Select country'));await tester.pumpAndSettle();
   final search=find.byWidgetPredicate((widget)=>widget is TextField&&widget.decoration?.hintText=='Search by name or code');
   await tester.enterText(search,'Canada');await tester.pumpAndSettle();
   await tester.tap(find.descendant(of:find.byType(BottomSheet),matching:find.byWidgetPredicate((widget)=>widget is Text&&widget.data=='Canada')));await tester.pumpAndSettle();
   expect(state.registrationData['Country'],'Canada');expect(state.registrationData['Country Code'],'CA');
   await tester.ensureVisible(find.text('+92'));await tester.tap(find.text('+92'));await tester.pumpAndSettle();
   await tester.enterText(search,'Canada');await tester.pumpAndSettle();
   await tester.tap(find.descendant(of:find.byType(BottomSheet),matching:find.byWidgetPredicate((widget)=>widget is Text&&widget.data=='Canada')));await tester.pumpAndSettle();
   expect(find.text('+1'),findsOneWidget);expect(state.phoneCountry.countryCode,'CA');expect(tester.takeException(),isNull);
   await disposeApp(tester);
  });
 }
 testWidgets('Upload step blocks continuation without license and degree',(tester) async {
  final state=await showStep(tester,4);
  expect(find.text('Upload from device'),findsNWidgets(3));
  await tester.ensureVisible(find.text('Continue →'));await tester.tap(find.text('Continue →'));await tester.pump();
  expect(state.regStep,4);expect(find.text('Upload both your professional license and degree certificate.'),findsOneWidget);
  await disposeApp(tester);
 });
}
