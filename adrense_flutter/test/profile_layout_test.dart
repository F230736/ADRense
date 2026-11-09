import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'profile_persistence_test.dart' as fixtures;

void main(){
 for(final width in [320.0,393.0]){
  testWidgets('Basic profile controls align and email stays on one line at $width pixels',(tester)async{
   final api=fixtures.ProfileApi();api.user['email']='raahimishtiaq2@gmail.com';
   final state=await fixtures.mountProfile(tester,api);
   tester.view.physicalSize=Size(width,1100);await tester.pumpAndSettle();
   final email=find.byKey(const ValueKey('profile-value-Email'));
   expect(tester.widget<Text>(email).maxLines,1);expect(tester.widget<Text>(email).softWrap,false);expect(tester.getSize(email).height,lessThan(25));
   await fixtures.sectionEdit(tester,'Basic Information');
   for(final name in ['Full Name','Email','Age Group','Biological Sex','Weight Range']){expect(find.byKey(ValueKey('profile-cancel-$name')),findsOneWidget);}
   final centers=[for(final name in ['Full Name','Email','Age Group','Biological Sex','Weight Range'])tester.getCenter(find.byKey(ValueKey('profile-action-$name'))).dx];
   for(final x in centers){expect(x,centers.first);}
   await tester.tap(find.byKey(const ValueKey('profile-action-Full Name')));await tester.pumpAndSettle();
   await tester.enterText(find.byKey(const ValueKey('basic-Full Name')),'Unsaved Person');
   await tester.tap(find.byTooltip('Cancel editing Full Name'));await tester.pumpAndSettle();
   expect(state.profile['Full Name'],'Saved Account');expect(api.patches,isEmpty);
   expect(tester.getSize(email).height,lessThan(25));expect(tester.takeException(),isNull);
   await fixtures.finish(tester);
  });
 }
}
