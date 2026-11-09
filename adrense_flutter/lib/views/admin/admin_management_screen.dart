part of '../../main.dart';

extension _AdminmanageViews on _ADRenseAppState {
  Widget adminFilter(List<String> options,String value,ValueChanged<String> update)=>
    SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
      for(final item in options)...[
        InkWell(onTap:()=>setState(()=>update(item)),child:Container(
          padding:EdgeInsets.symmetric(horizontal:16,vertical:9),
          decoration:BoxDecoration(color:item==value?P.teal:P.surface3,borderRadius:BorderRadius.circular(24)),
          child:Text(item,style:TextStyle(color:item==value?P.onAccent:P.muted,
            fontWeight:FontWeight.w700,fontSize:12)))),SizedBox(width:7),
      ],
    ]));
  List<Widget> adminVerification()=>[
    adminIntro('Analyst Verification',
      'Review professional credentials and documents submitted by healthcare professionals requesting analyst access.'),
    Row(children:[Expanded(child:Text('Saved applications',style:TextStyle(color:P.muted,fontSize:12))),TextButton.icon(onPressed:applicationsBusy?null:loadAnalystApplications,icon:Icon(Icons.refresh,size:18),label:Text('Refresh'))]),
    if(applicationsBusy)LinearProgressIndicator(),
    if(applicationsError!=null)Text(applicationsError!,style:TextStyle(color:P.danger)),
    adminFilter(['Pending','Verified','Rejected'],verificationFilter,(v)=>verificationFilter=v),gap(15),
    if(!applicationsBusy&&applicationsError==null&&applicants.where((a)=>a['status']==verificationFilter).isEmpty)
      Text('No applications in this category.',style:TextStyle(color:P.muted)),
    for(final a in applicants.where((a)=>a['status']==verificationFilter))...[
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(a['name']!,style:TextStyle(fontSize:14,fontWeight:FontWeight.w800)),gap(5),
            Text(a['role']!,style:TextStyle(color:P.muted,fontSize:11)),
          ])),badge(a['status']=='Pending'?'Pending Verification':a['status']!,
            color:a['status']=='Pending'?P.warning:a['status']=='Verified'?P.success:P.danger),
        ]),gap(8),Text('Submitted: ${a['submitted']}',style:TextStyle(color:P.muted,fontSize:10)),gap(15),
        InkWell(onTap:()=>setState((){selectedApplicant=a;screen='adminApplicant';}),
          child:Text('Review Application →',style:TextStyle(color:a['status']=='Pending'?P.warning:P.teal,
            fontSize:12,fontWeight:FontWeight.w800))),
      ])),gap(10),
    ],
  ];
  Widget adminDetailHeading(String name,String back,String status,Color accent)=>Row(children:[
    InkWell(onTap:()=>go(back),child:Container(width:36,height:36,
      decoration:BoxDecoration(color:P.surface2,borderRadius:BorderRadius.circular(10)),
      child:Icon(Icons.chevron_left))),SizedBox(width:9),
    Expanded(child:Text(name,style:TextStyle(fontSize:19,fontWeight:FontWeight.w800))),
    badge(status,color:accent),
  ]);
  Widget adminDataCard(String titleText,List<(String,String)> rows)=>card(Column(
    crossAxisAlignment:CrossAxisAlignment.start,children:[
      if(titleText.isNotEmpty)...[Text(titleText,style:TextStyle(fontSize:13,fontWeight:FontWeight.w800)),gap(13)],
      for(final row in rows)...[
        rowKV(row.$1,row.$2),Divider(height:1,color:P.border),
      ],
    ]));
}
