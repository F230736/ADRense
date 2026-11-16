part of '../../main.dart';

extension _AnalystreviewViews on _ADRenseAppState {
  Widget analystBack(String title,String target)=>Row(children:[
    InkWell(onTap:()=>go(target),child:Container(width:36,height:36,decoration:BoxDecoration(color:P.surface2,borderRadius:BorderRadius.circular(9)),child:Icon(Icons.chevron_left))),
    SizedBox(width:10),Expanded(child:Text(title,style:TextStyle(fontSize:16,fontWeight:FontWeight.w800))),
  ]);
  Widget analystFindingDetail(){
    final f=activeFinding??findings.first;
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      analystBack('Verify ADR Prediction','analystDash'),gap(12),
      Wrap(spacing:7,children:[badge(f['id']??'P001',color:P.muted),badge("${f['confidence']}% confidence",color:P.success),badge(f['severity']??'high',color:P.danger)]),gap(15),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        analystLabel('BIOBERT PREDICTION',color:P.muted),gap(11),
        Text('${f['drug']} → ${f['reaction']}',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800,color:P.teal)),gap(11),
        Text('Source: ${f['source']}',style:TextStyle(color:P.muted,fontSize:11)),gap(11),
        Container(width:double.infinity,padding:EdgeInsets.all(13),decoration:BoxDecoration(color:P.surface3,borderRadius:BorderRadius.circular(11),border:Border(left:BorderSide(color:P.teal,width:3))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Extracted text:',style:TextStyle(color:P.muted,fontSize:11)),gap(8),
          Text('"${f['text']}"',style:TextStyle(fontSize:12,fontStyle:FontStyle.italic,height:1.6,fontWeight:FontWeight.w600)),
        ])),
      ])),gap(14),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('BioBERT Confidence Breakdown',style:TextStyle(fontSize:13,fontWeight:FontWeight.w700)),gap(13),
        for(final item in [('Drug entity (NER)',98,P.success),('ADR entity (NER)',94,P.success),('Causal relationship',85,P.warning)]) ...[
          Row(children:[Expanded(child:Text(item.$1,style:TextStyle(color:P.muted,fontSize:11))),Text('${item.$2}%',style:TextStyle(color:item.$3,fontWeight:FontWeight.w700,fontSize:11))]),gap(6),
          LinearProgressIndicator(value:item.$2/100,minHeight:4,backgroundColor:P.surface3,valueColor:AlwaysStoppedAnimation(item.$3)),gap(13),
        ],
      ])),gap(14),
      card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Your Verification Decision',style:TextStyle(fontSize:13,fontWeight:FontWeight.w700)),gap(13),
        Text('Clinical justification *',style:TextStyle(color:P.muted,fontSize:11)),gap(8),
        TextField(maxLines:4,onChanged:(v){analystReviewReason=v;if(formErrors.containsKey('Clinical justification'))setState(()=>formErrors.remove('Clinical justification'));},
          decoration:InputDecoration(hintText:'Explain the clinical basis for your decision. Reference guidelines, patient context, or literature where applicable...',
            errorText:formErrors['Clinical justification'],errorMaxLines:2)),gap(13),
        Row(children:[
          Expanded(child:smallBtn('✓ Verify',()=>submitAnalystDecision(f,'Verified'),color:P.success)),SizedBox(width:8),
          Expanded(child:smallBtn('✕ Reject',()=>submitAnalystDecision(f,'Rejected'),color:P.danger)),
        ]),gap(8),
        SizedBox(width:double.infinity,child:smallBtn('Correct Finding',()=>submitAnalystDecision(f,'Corrected'),color:_ADRenseAppState.analystPurple)),
      ])),
    ]);
  }
  void submitAnalystDecision(Map<String,String> f,String status){
    if(analystReviewReason.trim().isEmpty){setState(()=>formErrors['Clinical justification']='Clinical justification is required');return;}
    setState(()=>f['status']=status);
    analystReviewReason='';go('analystDash');toast('Decision recorded locally: $status');
  }
  List<Widget> signals()=>[
    Container(padding:EdgeInsets.all(15),decoration:BoxDecoration(color:P.danger.withValues(alpha:.06),border:Border.all(color:P.danger.withValues(alpha:.3)),borderRadius:BorderRadius.circular(14)),
      child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Icon(Icons.warning_amber_rounded,color:P.danger,size:18),SizedBox(width:10),
        Expanded(child:Text('Signals are auto-detected by the system when ADR report frequency significantly exceeds historical baseline. Analyst review is required before any signal is acted upon.',style:TextStyle(color:P.muted,fontSize:11,height:1.7))),
      ])),gap(16),
    for(final signal in safetySignals) ...[
      InkWell(onTap:(){setState(()=>activeSignal=signal.$1);go('analystSignal');},child:card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Expanded(child:Text('${signal.$1} → ${signal.$2}',style:TextStyle(fontSize:13,fontWeight:FontWeight.w800))),badge(signalStatuses[signal.$1]??'⚠ Unreviewed',color:P.warning)]),gap(6),
        Text('+${signal.$5}% increase in reports',style:TextStyle(color:P.danger,fontWeight:FontWeight.w700,fontSize:12)),gap(14),
        Row(children:[
          Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Historical',style:TextStyle(color:P.muted,fontSize:10)),Text('${signal.$3}/mo',style:TextStyle(fontWeight:FontWeight.w800))]),
          SizedBox(width:20),
          Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Current',style:TextStyle(color:P.muted,fontSize:10)),Text('${signal.$4}/mo',style:TextStyle(color:P.danger,fontWeight:FontWeight.w800))]),
        ]),
      ]))),gap(12),
    ],
  ];
}
