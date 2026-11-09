part of '../../main.dart';

extension _AlertsViews on _ADRenseAppState {
  Widget alerts() {
    final records=[
      ('Metformin','Lactic Acidosis signal — 3.2× threshold','High','2h ago'),
      ('Ibuprofen','GI Bleeding frequency increase','High','5h ago'),
      ('Warfarin','Hemorrhage risk trend upward','Medium','1d ago'),
      ('Lisinopril','Cough ADR frequency elevated','Medium','2d ago'),
      ('Atorvastatin','Muscle pain reports under monitoring','Low','3d ago'),
    ];
    final visible=records.where((r)=>! (dismissedAlerts[r.$1]??false) &&
      (alertFilter=='All'||alertFilter==r.$3)).toList();
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[
        InkWell(onTap:()=>go('home'),child:Container(width:35,height:35,
          decoration:BoxDecoration(color:P.surface2,borderRadius:BorderRadius.circular(10)),
          child:Icon(Icons.chevron_left))),
        SizedBox(width:9),
        Expanded(child:Text('Safety Alerts',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800))),
        badge('${records.where((r)=>r.$3=="High"||r.$3=="Medium").where((r)=>!(dismissedAlerts[r.$1]??false)).length} Active',
          color:P.danger),
      ]),
      gap(15),
      Row(children:[
        for(final filter in ['All','High','Medium','Low']) ...[
          InkWell(onTap:()=>setState(()=>alertFilter=filter),
            child:Container(padding:EdgeInsets.symmetric(horizontal:16,vertical:8),
              decoration:BoxDecoration(color:alertFilter==filter?P.teal:P.surface3,
                borderRadius:BorderRadius.circular(20)),
              child:Text(filter,style:TextStyle(fontSize:12,
                fontWeight:alertFilter==filter?FontWeight.w700:FontWeight.w400,
                color:alertFilter==filter?P.onAccent:P.muted)))),
          SizedBox(width:6),
        ],
      ]),
      gap(16),
      for(final r in visible) ...[
        Container(width:double.infinity,padding:EdgeInsets.all(15),
          decoration:BoxDecoration(color:P.surface2,borderRadius:BorderRadius.circular(15),
            border:Border.all(color:(r.$3=='High'?P.danger:r.$3=='Medium'?P.warning:P.success)
              .withValues(alpha:.32))),
          child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Container(width:35,height:35,alignment:Alignment.center,
              decoration:BoxDecoration(color:(r.$3=='High'?P.danger:P.warning).withValues(alpha:.1),
                borderRadius:BorderRadius.circular(10)),
              child:Icon(Icons.circle,size:9,color:r.$3=='High'?P.danger:P.warning)),
            SizedBox(width:11),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[
                Expanded(child:Text(r.$1,style:TextStyle(fontSize:14,fontWeight:FontWeight.w800))),
                badge(r.$3=='High'?'Active':'Reviewing',color:r.$3=='High'?P.danger:P.warning),
              ]),
              gap(6),
              Align(alignment:Alignment.centerRight,
                child:Text(r.$4,style:TextStyle(color:P.muted,fontSize:10))),
              gap(8),
              Text(r.$2,style:TextStyle(color:P.muted,fontSize:11,height:1.5)),
              gap(11),
              Row(children:[
                smallBtn('View Details',()=>showDialog<void>(context:context,
                  builder:(context)=>AlertDialog(
                    backgroundColor:P.surface2,title:Text(r.$1),
                    content:Text(r.$2),actions:[
                      TextButton(onPressed:()=>Navigator.pop(context),child:Text('Close')),
                    ]))),
                SizedBox(width:9),
                smallBtn('Dismiss',()=>setState(()=>dismissedAlerts[r.$1]=true),color:P.muted),
              ]),
            ])),
          ])),
        gap(10),
      ],
      if(visible.isEmpty)card(Text('No alerts in this category.',
        style:TextStyle(color:P.muted))),
    ]);
  }
}
