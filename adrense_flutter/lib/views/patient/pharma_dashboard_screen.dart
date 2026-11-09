part of '../../main.dart';

extension _DashboardViews on _ADRenseAppState {
  Widget pharmaDash()=>Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
    Row(children: [
      Expanded(child: Text('Pharma Dashboard',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w800))),
      badge('Analyst View',color: Color(0xFF9B5CFF)),
    ]),
    gap(15),
    Container(width: double.infinity,padding: EdgeInsets.all(14),
      decoration: BoxDecoration(color: P.danger.withValues(alpha: .06),
        border: Border.all(color: P.danger.withValues(alpha: .3)),borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(width: 34,height: 34,
          decoration: BoxDecoration(color: P.danger.withValues(alpha: .14),borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.warning_amber_rounded,color: P.danger,size: 20)),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
          Text('Safety Signal Detected',style: TextStyle(color: P.danger,fontSize: 12,fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Metformin + Lactic Acidosis — 3.2× above threshold',
            style: TextStyle(fontSize: 11,fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Requires analyst review · Detected Aug 24, 2026',
            style: TextStyle(color: P.muted,fontSize: 10)),
        ])),
      ])),
    gap(17),
    Row(children: [
      for(final period in ['1M','3M','6M','1Y']) ...[
        InkWell(onTap: ()=>setState(()=>dashPeriod=period),
          child: Container(width: 48,height: 32,alignment: Alignment.center,
            decoration: BoxDecoration(color: dashPeriod==period?P.teal:P.surface3,
              borderRadius: BorderRadius.circular(18)),
            child: Text(period,style: TextStyle(fontSize: 12,
              color: dashPeriod==period?P.navy:P.muted,
              fontWeight: dashPeriod==period?FontWeight.w700:FontWeight.w400)))),
        SizedBox(width: 6),
      ],
    ]),
    gap(15),
    card(Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
      Row(children: [
        Expanded(child: Text('ADR Frequency by Drug',style: TextStyle(fontWeight: FontWeight.w700,fontSize: 14))),
        Text('reports',style: TextStyle(fontSize: 10,color: P.muted,fontFamily: 'monospace')),
      ]),
      gap(16),
      AdrenseBarChart(values:dashPeriod=='1M'?const [14,10,9,7,5,5,4]:dashPeriod=='3M'?const [35,29,20,17,15,13,11]:dashPeriod=='1Y'?const [110,94,73,61,52,46,40]:const [56,45,32,24,21,18,16],
        labels:const ['Warf','Ibup','Ator','Metf','Lisi','Amox','Aspi'],
        colors:[P.danger,P.warning,P.teal,P.teal,P.teal,P.teal,P.teal]),
    ])),
    gap(12),
    card(Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
      Row(children: [
        Expanded(child: Text('ADR Trend',style: TextStyle(fontSize: 14,fontWeight: FontWeight.w700))),
        badge('+18% vs prev',color: P.danger),
      ]),
      gap(14),
      AdrenseLineChart(values:dashPeriod=='1M'?const [18,23,19,27,25,31]:dashPeriod=='3M'?const [29,34,32,38,41,48]:dashPeriod=='1Y'?const [20,28,35,42,55,68]:const [39,41,38,47,53,61],
        labels:const ['Mar','Apr','May','Jun','Jul','Aug'],color:P.danger),
    ])),
    gap(12),
    card(Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
      Text('Top ADRs by Frequency',style: TextStyle(fontWeight: FontWeight.w700,fontSize: 14)),
      gap(15),
      for(final adr in [
        ('Nausea','847','+12%',P.success),
        ('Headache','621','+5%',P.success),
        ('Fatigue','445','+8%',P.success),
        ('GI Bleeding','234','+22%',P.danger),
        ('Lactic Acidosis','89','+41%',P.danger),
      ]) ...[
        Row(children: [
          Text('#${['Nausea','Headache','Fatigue','GI Bleeding','Lactic Acidosis'].indexOf(adr.$1)+1}',
            style: TextStyle(color: P.muted,fontSize: 11)),
          SizedBox(width: 13),
          Icon(Icons.circle,color: adr.$4,size: 8),
          SizedBox(width: 10),
          Expanded(child: Text(adr.$1,style: TextStyle(fontSize: 12,fontWeight: FontWeight.w600))),
          Text(adr.$2,style: TextStyle(fontWeight: FontWeight.w700,fontSize: 12)),
          SizedBox(width: 9),
          Text(adr.$3,style: TextStyle(color: adr.$4,fontSize: 10,fontWeight: FontWeight.w700)),
        ]),
        gap(10),Divider(color: P.border,height: 1),gap(9),
      ],
    ])),
    gap(12),
    card(Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
      Text('Active Safety Signals',style: TextStyle(fontWeight: FontWeight.w700,fontSize: 14)),
      gap(14),
      for(final signal in [
        ('Metformin → Lactic Acidosis','Investigating',P.danger),
        ('Ibuprofen → GI Bleeding','Confirmed',P.danger),
        ('Warfarin → Hemorrhage','Monitoring',P.warning),
      ]) ...[
        Row(children: [
          Icon(Icons.circle,color: signal.$3,size: 8),SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
            Text(signal.$1,style: TextStyle(fontWeight: FontWeight.w700,fontSize: 12)),
            Text(signal.$2,style: TextStyle(color: P.muted,fontSize: 10)),
          ])),
          smallBtn('Review',()=>go('alerts')),
        ]),
        Divider(color: P.border),
      ],
    ])),
  ]);

}
