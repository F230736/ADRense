part of '../main.dart';

extension _NavigationViews on _ADRenseAppState {
  Widget dashboardThemeControl()=>IconButton(
    tooltip:lightMode?'Switch to dark mode':'Switch to light mode',
    onPressed:toggleTheme,
    icon:AnimatedSwitcher(duration:AdrenseMotion.standard,
      transitionBuilder:(child,animation)=>RotationTransition(
        turns:animation,child:FadeTransition(opacity:animation,child:child)),
      child:Icon(lightMode?Icons.dark_mode_outlined:Icons.light_mode_outlined,
        key:ValueKey(lightMode),color:P.teal,size:21)),
    visualDensity:VisualDensity.compact,
  );
  Widget logoutControl()=>TextButton.icon(
    onPressed:()=>go('splash'),
    style:TextButton.styleFrom(padding:EdgeInsets.symmetric(horizontal:4,vertical:3),minimumSize:Size(0,30)),
    icon:Icon(Icons.logout,size:13,color:P.danger),
    label:Text('Logout',style:TextStyle(fontSize:10,color:P.danger)));

  void selectAnalystTab(String tab, {String? filter}) {
    updateView(() {
      analystTab = tab;
      screen = 'analystDash';
      if (filter != null) reviewFilter = filter;
    });
  }

  Widget analystBottomNav()=>Container(
    padding:EdgeInsets.fromLTRB(0,10,0,17),
    decoration:BoxDecoration(color:P.navy,border:Border(top:BorderSide(color:P.border))),
    child:Row(children:[
      for(final item in [
        ('Verify Queue','Verify Queue',Icons.fact_check_outlined),
        ('Signals','Signals',Icons.warning_amber_outlined),
        ('Drug Search','Drug Search',Icons.search),
        ('Reports','Reports',Icons.bar_chart_outlined),
      ]) Expanded(child:InkWell(onTap:(){HapticFeedback.selectionClick();selectAnalystTab(item.$1);},
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          AnimatedScale(scale:analystTab==item.$1?1.13:1,duration:AdrenseMotion.micro,
            child:Icon(item.$3,color:analystTab==item.$1?P.teal:P.muted,size:22)),
          gap(4),Text(item.$2,textAlign:TextAlign.center,style:TextStyle(fontSize:10,
            fontWeight:analystTab==item.$1?FontWeight.w700:FontWeight.w400,
            color:analystTab==item.$1?P.teal:P.muted)),
          gap(4),Container(width:4,height:4,decoration:BoxDecoration(
            color:analystTab==item.$1?P.teal:Colors.transparent,shape:BoxShape.circle)),
        ]))),
    ]));

  Widget bottomNav() => Container(
    padding: EdgeInsets.fromLTRB(0, 10, 0, 17),
    decoration: BoxDecoration(color: P.navy, border: Border(top: BorderSide(color: P.border))),
    child: Row(children: [
      for (final item in [
        ('home','Home',Icons.home_outlined),
        ('search','Search',Icons.search),
        ('adrAnalysis','Analyze',Icons.psychology_outlined),
        ('pharmaDash','Dashboard',Icons.bar_chart_outlined),
        ('healthProfile','Profile',Icons.person_outline),
      ])
        Expanded(child: InkWell(onTap: () {HapticFeedback.selectionClick();go(item.$1);},
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedScale(scale:screen==item.$1?1.13:1,duration:AdrenseMotion.micro,child:Icon(item.$3, color: screen == item.$1 ? P.teal : P.muted, size: 22)),
            gap(4),
            Text(item.$2, style: TextStyle(fontSize: 10, fontWeight: screen == item.$1 ? FontWeight.w700 : FontWeight.w400,
              color: screen == item.$1 ? P.teal : P.muted)),
            gap(4),
            Container(width: 4, height: 4, decoration: BoxDecoration(
              color: screen == item.$1 ? P.teal : Colors.transparent, shape: BoxShape.circle)),
          ]))),
    ]),
  );
}
