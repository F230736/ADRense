import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adrense_flutter/main.dart';
import 'persistent_session_test.dart' as fixtures;

void main(){
  testWidgets('Dataset header stays at the top as its content scrolls', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final api = fixtures.service(fixtures.MemorySessionStore()..token = 'valid', role: 'admin');
    await tester.pumpWidget(MaterialApp(home: ADRenseApp(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Datasets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View / Manage →').first);
    await tester.pumpAndSettle();
    final title = find.text('Dataset Details');
    final initialTop = tester.getTopLeft(title).dy;
    expect(initialTop, lessThan(60));

    tester.view.physicalSize = const Size(393, 420);
    await tester.pumpAndSettle();
    final scroll = find.byType(SingleChildScrollView);
    await tester.drag(scroll, const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels, greaterThan(0));
    expect(tester.getTopLeft(title).dy, initialTop);
    expect(find.text('Active'), findsOneWidget);
    await fixtures.disposeApp(tester);
  });

  testWidgets('Analyst tabs leave the generated report and open their content', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final api = fixtures.service(fixtures.MemorySessionStore()..token = 'valid', role: 'analyst');
    await tester.pumpWidget(MaterialApp(home: ADRenseApp(api: api)));
    await tester.pumpAndSettle();
    final nav = find.byKey(const ValueKey('app-bottom-navigation'));

    for (final (tab, expected) in [
      ('Drug Search', 'Search by drug name, class, or ADR...'),
      ('Reports', 'GENERATE ADR MONITORING REPORT'),
    ]) {
      await tester.tap(find.descendant(of: nav, matching: find.text('Reports')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Generate Report').first);
      await tester.pumpAndSettle();
      expect(find.text('ADR MONITORING REPORT'), findsOneWidget);

      await tester.tap(find.descendant(of: nav, matching: find.text(tab)));
      await tester.pumpAndSettle();
      expect(find.text('ADR MONITORING REPORT'), findsNothing);
      expect(find.text(expected), findsOneWidget);
    }
    await fixtures.disposeApp(tester);
  });

  for(final role in ['patient','analyst','admin']){
    for(final width in [393.0,412.0,480.0,600.0,844.0,1280.0,1920.0]){
      testWidgets('$role navigation fills the $width-pixel screen',(tester)async{
        tester.view.physicalSize=Size(width,1000);tester.view.devicePixelRatio=1;
        await tester.pumpWidget(MaterialApp(home:ADRenseApp(api:fixtures.service(fixtures.MemorySessionStore()..token='valid',role:role))));
        await tester.pump();await tester.pump(const Duration(seconds:1));
        final bar=find.byKey(const ValueKey('app-bottom-navigation'));
        expect(bar,findsOneWidget);
        final rect=tester.getRect(bar);
        expect(rect.left,0);expect(rect.width,width);expect(rect.right,width);
        final controls=tester.getRect(find.byKey(const ValueKey('navigation-controls')));
        expect(controls.width,width<=600?width:393);
        expect(controls.center.dx,width/2);
        expect(tester.takeException(),isNull);
        await fixtures.disposeApp(tester);tester.view.resetPhysicalSize();tester.view.resetDevicePixelRatio();
      });
    }
  }
  testWidgets('Navigation background spans landscape safe-area insets',(tester)async{
    tester.view.physicalSize=const Size(844,500);tester.view.devicePixelRatio=1;
    tester.view.padding=FakeViewPadding(left:30,right:30,bottom:24);
    await tester.pumpWidget(MaterialApp(home:ADRenseApp(api:fixtures.service(fixtures.MemorySessionStore()..token='valid'))));
    await tester.pump();await tester.pump(const Duration(seconds:1));
    final rect=tester.getRect(find.byKey(const ValueKey('app-bottom-navigation')));
    expect(rect.left,0);expect(rect.right,844);expect(rect.bottom,500);
    await fixtures.disposeApp(tester);tester.view.resetPadding();tester.view.resetPhysicalSize();tester.view.resetDevicePixelRatio();
  });
}
