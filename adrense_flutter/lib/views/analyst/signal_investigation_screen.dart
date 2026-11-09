part of '../../main.dart';

extension _SignalViews on _ADRenseAppState {
  Widget analystSignalDetail(){
    final signal=safetySignals.firstWhere((s)=>s.$1==activeSignal,orElse:()=>safetySignals.first);
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      analystBack('Signal Investigation','analystDash'),gap(15),
      Container(width:double.infinity,padding:EdgeInsets.all(16),decoration:BoxDecoration(color:P.danger.withValues(alpha:.06),border:Border.all(color:P.danger.withValues(alpha:.35)),borderRadius:BorderRadius.circular(15)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        analystLabel('⚠ POTENTIAL SAFETY SIGNAL',color:P.danger),gap(10),
        Text('${signal.$1} → ${signal.$2}',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800)),gap(16),
        Row(children:[metric('${signal.$3}/mo','Historical',color:P.muted),metric('${signal.$4}/mo','Current',color:P.danger),metric('+${signal.$5}%','Increase',color:P.warning)]),
      ])),gap(14),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Supporting Reports',style:TextStyle(fontWeight:FontWeight.w700,fontSize:13)),gap(15),
        for(final r in [
          ('FAERS #2847','Jun 2026','Patient reported GI haemorrhage after 3 months of treatment.'),
          ('Social media #SM-4291','Jul 2026','Confirmed case with lab evidence. Clinical picture consistent.'),
          ('CADEC #1103','Aug 2026','Third report in 30 days — pattern noted by treating physician.'),
        ]) ...[
          Row(children:[Expanded(child:Text(r.$1,style:TextStyle(color:P.teal,fontSize:12,fontWeight:FontWeight.w700))),Text(r.$2,style:TextStyle(color:P.muted,fontSize:10))]),gap(7),
          Text(r.$3,style:TextStyle(fontSize:11,fontStyle:FontStyle.italic,height:1.5)),gap(11),Divider(height:1,color:P.border),gap(12),
        ],
      ])),gap(14),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Signal Assessment',style:TextStyle(fontWeight:FontWeight.w700,fontSize:13)),gap(13),
        TextField(maxLines:4,onChanged:(v)=>signalAssessment=v,decoration:InputDecoration(hintText:'Provide your evidence assessment. Consider reporting bias, confounders, pharmacological plausibility...')),gap(12),
        Row(children:[
          for(final decision in [('Confirm',P.success),('Investigate',P.warning),('Reject',P.danger)])
            Expanded(child:Padding(padding:EdgeInsets.only(right:5),child:smallBtn(decision.$1,(){
              if(signalAssessment.trim().isEmpty){toast('Provide a signal assessment first');return;}
              setState(()=>signalStatuses[signal.$1]=decision.$1);
              signalAssessment='';go('analystDash');toast('Signal decision saved locally');
            },color:decision.$2))),
        ]),
      ])),
    ]);
  }
  List<Widget> analystDrugSearch()=>[
    TextField(onChanged:(v)=>setState(()=>analystDrugQuery=v),decoration:InputDecoration(prefixIcon:Icon(Icons.search,color:_ADRenseAppState.analystPurple),hintText:'Search by drug name, class, or ADR...',enabledBorder:OutlineInputBorder(borderSide:BorderSide(color:_ADRenseAppState.analystPurple.withValues(alpha:.35)),borderRadius:BorderRadius.circular(12)))),gap(16),
    Text('Quick access',style:TextStyle(color:P.muted,fontSize:11)),gap(10),
    Wrap(spacing:7,runSpacing:8,children:[for(final d in analystDrugs)InkWell(onTap:(){drug=d.$1;go('analystDrug');},child:Container(padding:EdgeInsets.symmetric(horizontal:12,vertical:8),decoration:BoxDecoration(color:P.surface3,borderRadius:BorderRadius.circular(18)),child:Text(d.$1,style:TextStyle(color:P.muted,fontSize:11))))]),gap(19),
    for(final d in analystDrugs.where((d)=>d.$1.toLowerCase().contains(analystDrugQuery.toLowerCase())||d.$2.toLowerCase().contains(analystDrugQuery.toLowerCase()))) ...[
      InkWell(onTap:(){drug=d.$1;go('analystDrug');},child:card(Row(children:[
        Container(width:39,height:39,decoration:BoxDecoration(color:_ADRenseAppState.analystPurple.withValues(alpha:.12),borderRadius:BorderRadius.circular(10)),child:Icon(Icons.medication_outlined,color:_ADRenseAppState.analystPurple,size:20)),
        SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(d.$1,style:TextStyle(fontWeight:FontWeight.w700,fontSize:13)),Text(d.$2,style:TextStyle(color:P.muted,fontSize:10)),gap(6),Text('${d.$3} ADR reports',style:TextStyle(color:P.muted,fontSize:10))])),
        Column(children:[Text('${d.$4}',style:TextStyle(color:d.$4>=80?P.success:P.warning,fontWeight:FontWeight.w800,fontSize:19)),Text('Safety',style:TextStyle(color:P.muted,fontSize:10))]),
      ]))),gap(10),
    ],
  ];
}
