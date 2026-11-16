part of '../../main.dart';

extension _AnalystdashViews on _ADRenseAppState {
  Widget analystLabel(String s,{Color? color})=>Text(s,style:TextStyle(color:color??_ADRenseAppState.analystPurple,fontSize:10,letterSpacing:1,fontFamily:'monospace'));
  Widget analystTopBar()=>Container(
    padding:EdgeInsets.fromLTRB(0,1,0,13),
    child:Row(children:[
      SizedBox(width:36,height:36,child:SvgPicture.asset('assets/logo.svg')),
      SizedBox(width:9),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Analyst Dashboard',style:TextStyle(fontWeight:FontWeight.w800,fontSize:16,color:P.text)),
        Text('Human-in-the-Loop · ADRense',style:TextStyle(color:P.muted,fontSize:10)),
      ])),
      Column(mainAxisSize:MainAxisSize.min,children:[
      dashboardThemeControl(),
      logoutControl(),
    ]),
    ]));
  Widget analystCounters()=>Row(children:[
    for(final item in [
      ('Pending',P.warning),('Verified',P.success),('Rejected',P.danger),('Corrected',P.warning)
    ]) Expanded(child:InkWell(onTap:()=>selectAnalystTab('Verify Queue',filter:item.$1),child:Container(margin:EdgeInsets.only(right:7),padding:EdgeInsets.symmetric(vertical:13,horizontal:3),
      decoration:BoxDecoration(color:P.surface2,border:Border.all(color:P.border),borderRadius:BorderRadius.circular(12)),
      child:Column(children:[
        AnimatedCounter(value:findings.where((f)=>f['status']==item.$1).length,style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:item.$2)),
        gap(5),Text(item.$1,style:TextStyle(fontSize:9,color:P.muted)),
      ]))))]);
  Widget analystTabs()=>Container(
    
    decoration:BoxDecoration(color:P.light?Color(0xFFF0F3FC):Color(0xFF0D1120),border:Border(bottom:BorderSide(color:P.border))),
    child:Row(children:[
      for(final tab in ['Verify Queue','Signals','Drug Search','Reports'])
        Expanded(child:InkWell(onTap:()=>selectAnalystTab(tab),child:Container(
          height:45,alignment:Alignment.center,
          decoration:BoxDecoration(border:Border(bottom:BorderSide(color:analystTab==tab?_ADRenseAppState.analystPurple:Colors.transparent,width:2))),
          child:Text(tab,style:TextStyle(fontSize:11,color:analystTab==tab?_ADRenseAppState.analystPurple:P.muted,fontWeight:analystTab==tab?FontWeight.w700:FontWeight.w400))))),
    ]));
  Widget analystDash()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    analystTopBar(),gap(9),analystCounters(),gap(15),
    AnimatedSwitcher(
      duration:MediaQuery.disableAnimationsOf(context)?Duration.zero:AdrenseMotion.standard,
      switchInCurve:Curves.easeOutCubic,
      child:Column(key:ValueKey(analystTab),crossAxisAlignment:CrossAxisAlignment.start,children:
        analystTab=='Verify Queue'?analystQueue():
        analystTab=='Signals'?signals():
        analystTab=='Drug Search'?analystDrugSearch():reports()),
    ),
  ]);
  List<Widget> analystQueue()=>[
    SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
      for(final status in ['All','Pending','Verified','Rejected','Corrected']) ...[
        InkWell(onTap:()=>setState(()=>reviewFilter=status),child:Container(
          padding:EdgeInsets.symmetric(horizontal:17,vertical:9),
          decoration:BoxDecoration(color:reviewFilter==status?P.teal:P.surface3,borderRadius:BorderRadius.circular(24)),
          child:Text(status,style:TextStyle(color:reviewFilter==status?P.onAccent:P.muted,fontSize:12,fontWeight:FontWeight.w600)))),
        SizedBox(width:6),
      ],
    ])),gap(15),
    for(final f in findings.where((f)=>reviewFilter=='All'||f['status']==reviewFilter)) ...[
      InkWell(onTap:(){setState(()=>activeFinding=f);go('analystFinding');},child:card(Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Container(width:36,height:36,alignment:Alignment.center,decoration:BoxDecoration(color:P.danger.withValues(alpha:.12),borderRadius:BorderRadius.circular(9)),child:Icon(Icons.circle,color:P.danger,size:9)),
        SizedBox(width:11),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[Expanded(child:Text('${f['drug']} → ${f['reaction']}',style:TextStyle(fontWeight:FontWeight.w800,fontSize:13))),badge(f['status']!,color:f['status']=='Pending'?P.warning:P.success)]),
          gap(6),Text(f['source']??'',style:TextStyle(color:P.muted,fontSize:11)),gap(14),
          TweenAnimationBuilder<double>(tween:Tween(begin:0,end:(double.tryParse(f['confidence']??'0')??0)/100),duration:const Duration(milliseconds:850),curve:Curves.easeOutCubic,builder:(context,v,_)=>ClipRRect(borderRadius:BorderRadius.circular(4),child:LinearProgressIndicator(value:v,minHeight:5,backgroundColor:P.surface3,valueColor:AlwaysStoppedAnimation((double.tryParse(f['confidence']??'0')??0)>=90?P.success:((double.tryParse(f['confidence']??'0')??0)>=70?P.warning:P.danger))))),
          gap(5),Align(alignment:Alignment.centerRight,child:Text("${f['confidence']}% conf",style:TextStyle(color:P.muted,fontSize:10))),
        ])),
      ]))),gap(10),
    ],
  ];
}
