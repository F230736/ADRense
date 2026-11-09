part of '../../main.dart';

extension _AnalystdrugViews on _ADRenseAppState {
  Widget analystDrugDetail(){
    final header = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children:[Expanded(child:analystBack(drug,'analystDash')),Column(children:[Text('87',style:TextStyle(color:P.success,fontSize:23,fontWeight:FontWeight.w800)),Text('Safety Score',style:TextStyle(color:P.muted,fontSize:10))])]),gap(4),
      Text('Biguanide · Antidiabetic',style:TextStyle(color:P.muted,fontSize:11)),
    ]);
    return _pinnedHeaderPage(header, Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[analystLabel('MECHANISM OF ACTION',color:P.muted),gap(9),Text('Biguanide — inhibits mitochondrial complex I, reducing hepatic glucose output.',style:TextStyle(fontSize:12,height:1.6,fontWeight:FontWeight.w600))])),gap(12),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('ADR Distribution (234 total reports)',style:TextStyle(fontWeight:FontWeight.w700,fontSize:13)),gap(16),
        for(final a in [('Nausea',84,36,P.success),('Lactic Acidosis',54,23,P.danger),('GI Discomfort',51,22,P.success),('Vitamin B12 Deficiency',45,19,P.warning)]) ...[
          Row(children:[Icon(Icons.circle,color:a.$4,size:8),SizedBox(width:7),Expanded(child:Text(a.$1,style:TextStyle(fontSize:12,fontWeight:FontWeight.w700))),Text('${a.$2} (${a.$3}%)',style:TextStyle(color:P.muted,fontSize:11))]),gap(7),
          LinearProgressIndicator(value:a.$3/100,minHeight:5,backgroundColor:P.surface3,valueColor:AlwaysStoppedAnimation(a.$4)),gap(13),
        ],
      ])),gap(12),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Active Safety Signals',style:TextStyle(fontWeight:FontWeight.w700)),gap(14),rowKV('Lactic Acidosis','Unreviewed'),Text('+128% increase',style:TextStyle(color:P.muted,fontSize:10))])),gap(12),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[analystLabel('MONITORING GUIDANCE',color:P.muted),gap(10),Text('Monitor renal function; hold if eGFR <30. Lactic acidosis risk in renal/hepatic impairment.',style:TextStyle(fontSize:12,height:1.6))])),
    ]));
  }
  List<Widget> reports()=>[
    analystLabel('GENERATE ADR MONITORING REPORT',color:P.muted),gap(12),
    TextField(onChanged:(v)=>setState(()=>reportQuery=v),decoration:InputDecoration(prefixIcon:Icon(Icons.search,color:_ADRenseAppState.analystPurple),hintText:'Search drug name to generate report...',enabledBorder:OutlineInputBorder(borderSide:BorderSide(color:_ADRenseAppState.analystPurple.withValues(alpha:.4)),borderRadius:BorderRadius.circular(12)))),gap(15),
    for(final d in [('Metformin','Biguanide · Antidiabetic','1,234','1 signal'),('Ibuprofen','NSAID · Analgesic','1,890','2 signals')].where((d)=>d.$1.toLowerCase().contains(reportQuery.toLowerCase()))) ...[
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Container(width:39,height:39,decoration:BoxDecoration(color:_ADRenseAppState.analystPurple.withValues(alpha:.12),borderRadius:BorderRadius.circular(10)),child:Icon(Icons.description_outlined,color:_ADRenseAppState.analystPurple)),SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(d.$1,style:TextStyle(fontSize:14,fontWeight:FontWeight.w800)),Text(d.$2,style:TextStyle(color:P.muted,fontSize:10))]))]),gap(9),
        Wrap(spacing:6,children:[badge('${d.$3} ADR reports',color:P.warning),badge('Jan–Aug 2026',color:P.muted),badge(d.$4,color:P.danger)]),gap(14),
        Container(padding:EdgeInsets.all(12),decoration:BoxDecoration(color:P.surface3,borderRadius:BorderRadius.circular(10)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[analystLabel('TOP ADRS PREVIEW',color:P.muted),gap(10),for(final a in [('Nausea','31%'),('GI Discomfort','22%'),('Lactic Acidosis','18%')]) ...[Row(children:[Icon(Icons.circle,color:P.success,size:8),SizedBox(width:8),Expanded(child:Text(a.$1,style:TextStyle(fontSize:11,fontWeight:FontWeight.w700))),Text(a.$2,style:TextStyle(color:P.muted,fontSize:10))]),gap(9)]])),gap(10),
        SizedBox(width:double.infinity,child:OutlinedButton.icon(onPressed:(){selectedReportDrug=d.$1;go('analystReport');},icon:Icon(Icons.insert_drive_file_outlined,size:16),label:Text('Generate Report'),style:OutlinedButton.styleFrom(foregroundColor:P.text,side:BorderSide(color:P.border)))),
      ])),gap(12),
    ],
  ];
}
