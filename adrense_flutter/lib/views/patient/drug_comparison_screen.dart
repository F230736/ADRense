part of '../../main.dart';

extension _ComparisonViews on _ADRenseAppState {
  Widget compare() => Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[
      Tooltip(message:'Back to medicine details',child:InkWell(onTap:()=>go('drugProfile'),borderRadius:BorderRadius.circular(9),
        child:Container(width:35,height:35,decoration:BoxDecoration(color:P.surface2,borderRadius:BorderRadius.circular(9)),
          child:const Icon(Icons.chevron_left,size:22)))),
      const SizedBox(width:8),
      Expanded(child:Text('Drug Comparison',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800))),
      smallBtn('+ Add Drug',(){
        showModalBottomSheet<void>(context:context,backgroundColor:P.surface2,
          builder:(context)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
            for(final name in ['Ibuprofen','Aspirin','Lisinopril','Atorvastatin'])
              ListTile(title:Text(name),onTap:(){
                Navigator.pop(context);
                setState(()=>comparisonDrug=name);
              }),
          ])));
      }),
    ]),
    gap(13),
    Row(children:[
      Expanded(child:comparisonCard('Metformin','Antidiabetic',87,P.teal)),
      SizedBox(width:9),
      Expanded(child:comparisonCard(comparisonDrug,'NSAID',72,P.warning)),
    ]),
    gap(15),
    card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('Safety Comparison',style:TextStyle(fontWeight:FontWeight.w700,fontSize:14)),
      gap(13),
      for(final row in [
        ('Safety Score','87/100','72/100'),
        ('Total ADRs','1,247','2,089'),
        ('Severe ADRs','25','187'),
        ('Common ADR','Nausea 34%','GI Pain 41%'),
        ('Safety Signal','Lactic Acid.','GI Bleeding'),
      ]) ...[
        Row(children:[
          Expanded(flex:4,child:Text(row.$1,style:TextStyle(color:P.muted,fontSize:11))),
          Expanded(flex:3,child:Text(row.$2,textAlign:TextAlign.center,
            style:TextStyle(color:P.teal,fontWeight:FontWeight.w700,fontSize:11))),
          Expanded(flex:3,child:Text(row.$3,textAlign:TextAlign.center,
            style:TextStyle(fontWeight:FontWeight.w700,fontSize:11))),
        ]),
        gap(10),Divider(height:1,color:P.border),gap(10),
      ],
    ])),
    gap(13),
    card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('ADR Frequency Comparison',style:TextStyle(fontSize:14,fontWeight:FontWeight.w700)),
      gap(11),
      Row(children:[
        Container(width:9,height:9,color:P.teal),SizedBox(width:5),
        Text('Metformin',style:TextStyle(color:P.muted,fontSize:10)),
        SizedBox(width:16),
        Container(width:9,height:9,color:P.warning),SizedBox(width:5),
        Text(comparisonDrug,style:TextStyle(color:P.muted,fontSize:10)),
      ]),
      gap(14),
      for(final item in [('GI Effects',34.0,41.0),('Headache',12.0,18.0),
        ('Fatigue',15.0,10.0),('Severe ADR',2.0,9.0)]) ...[
        Row(children:[
          Expanded(child:Text(item.$1,style:TextStyle(color:P.muted,fontSize:11))),
          Text('${item.$2.toInt()}% / ${item.$3.toInt()}%',style:TextStyle(color:P.muted,fontSize:10)),
        ]),
        gap(8),
        FractionallySizedBox(widthFactor:1,alignment:Alignment.centerLeft,
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Container(width:item.$2*3,height:5,decoration:BoxDecoration(color:P.teal,borderRadius:BorderRadius.circular(3))),
            SizedBox(height:3),
            Container(width:item.$3*3,height:5,decoration:BoxDecoration(color:P.warning,borderRadius:BorderRadius.circular(3))),
          ])),
        gap(14),
      ],
    ])),
  ]);
  Widget comparisonCard(String name,String category,int score,Color accent) =>
    Container(padding:EdgeInsets.symmetric(vertical:16,horizontal:8),
      decoration:BoxDecoration(color:P.surface2,borderRadius:BorderRadius.circular(15),
        border:Border.all(color:accent.withValues(alpha:.32))),
      child:Column(children:[
        Container(padding:EdgeInsets.all(9),
          decoration:BoxDecoration(color:accent.withValues(alpha:.1),borderRadius:BorderRadius.circular(9)),
          child:Text('$score',style:TextStyle(color:accent,fontSize:20,fontWeight:FontWeight.w800))),
        gap(8),
        Text(name,textAlign:TextAlign.center,style:TextStyle(fontWeight:FontWeight.w800,fontSize:14)),
        gap(3),
        Text(category,style:TextStyle(color:P.muted,fontSize:11)),
        gap(7),badge('Safety: $score',color:accent),
      ]));

}
