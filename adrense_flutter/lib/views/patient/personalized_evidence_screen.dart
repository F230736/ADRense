part of '../../main.dart';

extension _EvidenceViews on _ADRenseAppState {
  Widget personalized() => Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
    Row(children: [
      InkWell(onTap:()=>go('drugProfile'),child: Container(width:35,height:35,
        decoration: BoxDecoration(color:P.surface2,borderRadius:BorderRadius.circular(9)),
        child:Icon(Icons.chevron_left,size:22))),
      SizedBox(width:8),
      Expanded(child:Text('Personalized Evidence',style:TextStyle(fontSize:19,fontWeight:FontWeight.w800))),
      badge('AI-Matched'),
    ]),
    gap(11),
    Text('Aggregated ADR evidence from 234 anonymized profiles similar to yours. Not individual predictions.',
      style:TextStyle(color:P.muted,fontSize:12,height:1.6)),
    gap(17),
    card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Profile Match',style:TextStyle(fontSize:14,fontWeight:FontWeight.w700)),
          gap(5),
          Text('Based on your health characteristics',style:TextStyle(color:P.muted,fontSize:11)),
        ])),
        donutScore(87),
      ]),
      gap(16),
      Wrap(spacing:8,runSpacing:9,children:[
        for(final v in ['Age 35–50','Type 2 Diabetes','No kidney disease','Female'])
          Container(padding:EdgeInsets.symmetric(horizontal:10,vertical:7),
            decoration:BoxDecoration(color:P.teal.withValues(alpha:.08),
              border:Border.all(color:P.tealDim.withValues(alpha:.55)),
              borderRadius:BorderRadius.circular(7)),
            child:Text('✓  $v',style:TextStyle(color:P.text,fontSize:10,fontWeight:FontWeight.w600))),
      ]),
    ])),
    gap(12),
    card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('Similar Profiles — Metformin',style:TextStyle(fontSize:14,fontWeight:FontWeight.w700)),
      gap(13),
      Row(children:[
        for(final data in [('234','Similar Profiles'),('89%','Tolerated Well'),('11%','Experienced ADRs')])
          Expanded(child:Container(margin:EdgeInsets.only(right:7),
            constraints:BoxConstraints(minHeight:79),padding:EdgeInsets.symmetric(vertical:13,horizontal:3),
            decoration:BoxDecoration(color:P.surface3,borderRadius:BorderRadius.circular(11)),
            child:Column(children:[
              Text(data.$1,style:TextStyle(color:P.teal,fontSize:21,fontWeight:FontWeight.w800)),
              gap(5),
              Text(data.$2,textAlign:TextAlign.center,style:TextStyle(color:P.muted,fontSize:10)),
            ]))),
      ]),
      gap(14),
      Text('Data from Synthea synthetic dataset · Aggregated and anonymized',
        style:TextStyle(color:P.muted,fontSize:11,fontStyle:FontStyle.italic,height:1.5)),
    ])),
    gap(12),
    card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('ADR Patterns in Similar Profiles',style:TextStyle(fontSize:14,fontWeight:FontWeight.w700)),
      gap(14),
      for(final adr in [
        ('Nausea',28.0,'Similar to general population',P.warning),
        ('Diarrhea',19.0,'Lower than average for your profile',P.teal),
        ('Abdominal Pain',12.0,'Within expected range',P.teal),
        ('Lactic Acidosis',0.8,'Rare — similar profiles show low risk',P.teal),
      ]) ...[
        Row(children:[
          Expanded(child:Text(adr.$1,style:TextStyle(fontSize:12,fontWeight:FontWeight.w700))),
          Text('${adr.$2}%',style:TextStyle(color:P.teal,fontSize:12,fontWeight:FontWeight.w800)),
        ]),
        gap(7),
        ClipRRect(borderRadius:BorderRadius.circular(4),
          child:LinearProgressIndicator(value:(adr.$2/40).clamp(0.0,1.0),
            minHeight:5,backgroundColor:P.surface3,valueColor:AlwaysStoppedAnimation(adr.$4))),
        gap(5),
        Text(adr.$3,style:TextStyle(color:P.muted,fontSize:10)),
        gap(16),
      ],
    ])),
    gap(12),
    card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('Important Limitation',style:TextStyle(color:P.warning,fontSize:12,fontWeight:FontWeight.w700)),
      gap(7),
      Text('These results are aggregated historical evidence from similar profiles, not predictions for your individual outcome. Consult your healthcare provider before making any medication decisions.',
        style:TextStyle(color:P.muted,fontSize:11,height:1.6)),
    ])),
  ]);

}
