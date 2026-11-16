import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adrense_flutter/main.dart';
import 'persistent_session_test.dart' as fixtures;

void main(){
  for (final role in ['patient', 'analyst']) {
    testWidgets('$role medicine search opens catalog details', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 1000);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      const medicine = {
        'id': 'andol',
        'name': 'Andol 0.5mg Tablet',
        'ingredients': 'Haloperidol (0.5mg)',
        'source': 'MID',
      };
      final queries = <String>[];
      final api = fixtures.service(
        fixtures.MemorySessionStore()..token = 'valid',
        handler: (request) async {
          if (request.url.path == '/api/medicines') {
            final query = request.url.queryParameters['q']!;
            queries.add(query);
            expect(request.headers['Authorization'], 'Bearer valid');
            return fixtures.jsonResponse({
              'medicines': [if (query == 'Haloperidol') medicine],
              'has_more': false,
            });
          }
          if (request.url.path == '/api/medicines/general-adrs') {
            expect(request.url.queryParameters['medicine_id'], 'andol');
            return fixtures.jsonResponse({'reactions': [
              {'drug_name': 'Haloperidol', 'reaction': 'Dry mouth'},
            ]});
          }
          if (request.url.path == '/api/medicines/andol') {
            return fixtures.jsonResponse({...medicine, 'uses': 'Schizophrenia'});
          }
          return fixtures.jsonResponse(fixtures.account(role));
        },
      );
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(.95)),
          child: child!,
        ),
        home: ADRenseApp(api: api),
      ));
      await tester.pumpAndSettle();
      final nav = find.byKey(const ValueKey('app-bottom-navigation'));
      await tester.tap(find.descendant(of: nav, matching: find.text(role == 'patient' ? 'Search' : 'Drug Search')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Haloperidol');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(queries, ['Haloperidol']);
      await tester.tap(find.text('Andol 0.5mg Tablet'));
      await tester.pumpAndSettle();
      expect(find.text('Drug Information'), findsOneWidget);
      if (role == 'patient') {
        expect(find.text('Overview'), findsOneWidget);
        expect(find.text('ADRs'), findsOneWidget);
        expect(find.text('Trends'), findsOneWidget);
        expect(find.text('Compare'), findsOneWidget);
        expect(find.text('View\nPersonalized'), findsOneWidget);
        expect(find.text('View\nAlerts'), findsOneWidget);
        await tester.tap(find.text('ADRs'));
        await tester.pumpAndSettle();
        expect(find.text('Reported ADRs by frequency — BioBERT extracted'), findsOneWidget);
        expect(find.text('General ADRs'), findsOneWidget);
        expect(find.text('Dry mouth'), findsOneWidget);
        await tester.tap(find.text('Trends'));
        await tester.pumpAndSettle();
        expect(find.text('ADR Reports — 12 Months'), findsOneWidget);
        await tester.tap(find.text('Overview'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Compare'));
        await tester.tap(find.text('Compare'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Back to medicine details'));
        await tester.pumpAndSettle();
      } else {
        expect(find.text('ADR Distribution (234 total reports)'), findsOneWidget);
        expect(find.text('Active Safety Signals'), findsOneWidget);
      }
      expect(find.text('Schizophrenia'), findsOneWidget);
      expect(find.text('Haloperidol (0.5mg)'), findsOneWidget);
      expect(find.text('MID'), findsOneWidget);
      await fixtures.disposeApp(tester);
    });
  }



  testWidgets('Dataset header stays at the top as its content scrolls', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final api = fixtures.service(fixtures.MemorySessionStore()..token = 'valid', handler: (request) async {
      if (request.url.path.endsWith('/datasets/history')) {
        return fixtures.jsonResponse({'imports': [{
          'id': 1, 'filename': 'actual.csv', 'created_at': '2026-11-10T00:00:00Z',
          'total_rows': 3, 'added_rows': 2, 'duplicate_rows': 1, 'invalid_rows': 0,
        }]});
      }
      if (request.url.path.endsWith('/analysts')) return fixtures.jsonResponse({'applications': []});
      if (request.url.path.endsWith('/users')) return fixtures.jsonResponse({'users': []});
      if (request.url.path.endsWith('/registrations')) {
        return fixtures.jsonResponse({'summary': {}, 'buckets': []});
      }
      return fixtures.jsonResponse(fixtures.account('admin'));
    });
    await tester.pumpWidget(MaterialApp(home: ADRenseApp(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Datasets'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.tap(find.text('actual.csv'));
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
    expect(find.text('Imported'), findsOneWidget);
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
      ('Drug Search', 'Search by name, ingredient, or class...'),
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
