import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adrense_flutter/main.dart';
import 'package:adrense_flutter/core/theme/adrense_theme.dart';
import 'package:adrense_flutter/views/patient/medication_analysis_panel.dart';
import 'persistent_session_test.dart' as fixtures;

void main(){
 for(final light in [true,false]){
  testWidgets('Analysis examples, results and reset work in ${light?'light':'dark'} mode',(tester)async{
   tester.view.physicalSize=const Size(393,950);tester.view.devicePixelRatio=1;
   final controller=TextEditingController();
   await tester.pumpWidget(MaterialApp(theme:AdrenseTheme.build(light),home:Scaffold(body:SingleChildScrollView(padding:const EdgeInsets.all(20),child:MedicationAnalysisPanel(controller:controller)))));
   expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,isNull);
   expect(find.textContaining('BioBERT'),findsNothing);
   await tester.tap(find.text('Stomach discomfort'));await tester.pump();expect(controller.text,contains('Metformin'));
   await tester.ensureVisible(find.widgetWithText(FilledButton,'Analyze'));await tester.tap(find.widgetWithText(FilledButton,'Analyze'));await tester.pumpAndSettle();
   expect(find.byKey(const ValueKey('analysis-results')),findsOneWidget);expect(find.text('Detected Drugs'),findsOneWidget);expect(find.text('Detected ADRs'),findsOneWidget);expect(find.text('Analysis complete · 94.3% confidence'),findsOneWidget);expect(find.text('Drug-ADR Relationships'),findsOneWidget);
   await tester.ensureVisible(find.text('Dizziness'));await tester.tap(find.text('Dizziness'));await tester.pumpAndSettle();expect(find.byKey(const ValueKey('analysis-results')),findsNothing);
   await tester.ensureVisible(find.widgetWithText(FilledButton,'Analyze'));await tester.tap(find.widgetWithText(FilledButton,'Analyze'));await tester.pumpAndSettle();
   expect(find.text('500mg · Daily · 96.2%'),findsOneWidget);expect(find.text('Confidence: 94%'),findsOneWidget);
   await tester.ensureVisible(find.text('Submit ADR'));await tester.tap(find.text('Submit ADR'));await tester.pumpAndSettle();expect(find.text('Report saved for this session (demo).'),findsOneWidget);
   final description=controller.text;await tester.ensureVisible(find.text('Reset Analysis'));await tester.tap(find.text('Reset Analysis'));await tester.pumpAndSettle();expect(controller.text,description);expect(find.byKey(const ValueKey('analysis-results')),findsNothing);expect(find.widgetWithText(FilledButton,'Analyze'),findsOneWidget);
   expect(tester.takeException(),isNull);await tester.pumpWidget(const SizedBox());controller.dispose();tester.view.resetPhysicalSize();tester.view.resetDevicePixelRatio();
  });
 }
 testWidgets('Analysis validates short text and clears stale results after edits',(tester)async{
  final controller=TextEditingController();await tester.pumpWidget(MaterialApp(theme:AdrenseTheme.build(true),home:Scaffold(body:SingleChildScrollView(child:MedicationAnalysisPanel(controller:controller)))));
  await tester.enterText(find.byType(TextField),'hello');await tester.pump();await tester.ensureVisible(find.widgetWithText(FilledButton,'Analyze'));await tester.tap(find.widgetWithText(FilledButton,'Analyze'));await tester.pumpAndSettle();
  expect(find.text('Please add a little more detail (at least 20 characters).'),findsOneWidget);
  await tester.enterText(find.byType(TextField),'I took Ibuprofen yesterday and noticed a headache.');await tester.ensureVisible(find.widgetWithText(FilledButton,'Analyze'));await tester.tap(find.widgetWithText(FilledButton,'Analyze'));await tester.pumpAndSettle();
  expect(find.text('Detected Drugs'),findsOneWidget);
  await tester.enterText(find.byType(TextField),'I took Ibuprofen this morning and have a headache.');await tester.pumpAndSettle();expect(find.byKey(const ValueKey('analysis-results')),findsNothing);expect(controller.text,contains('Ibuprofen'));
  await tester.pumpWidget(const SizedBox());controller.dispose();
 });
 testWidgets('Drug comparison back button returns to medicine details',(tester)async{
  await tester.pumpWidget(MaterialApp(home:ADRenseApp(api:fixtures.service(fixtures.MemorySessionStore()))));await tester.pump();await tester.pump(const Duration(seconds:1));
  final dynamic state=tester.state(find.byType(ADRenseApp));state.updateView((){state.screen='compare';});await tester.pump(const Duration(milliseconds:400));
  expect(find.byTooltip('Back to medicine details'),findsOneWidget);await tester.tap(find.byTooltip('Back to medicine details'));await tester.pump(const Duration(milliseconds:400));expect(state.screen,'drugProfile');
  await fixtures.disposeApp(tester);
 });
}
