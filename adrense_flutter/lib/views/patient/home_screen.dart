part of '../../main.dart';

extension _HomeViews on _ADRenseAppState {
  Widget home() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(DateTime.now().hour<12?'Good morning':DateTime.now().hour<17?'Good afternoon':'Good evening', style: TextStyle(color: P.muted, fontSize: 13)),
        Text(
  profile['Full Name'] ?? 'User',
  style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
  ),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
),
        gap(6), badge('General User'),
      ])),
      Stack(children: [
        Container(
          decoration: BoxDecoration(color: P.surface2, border: Border.all(color: P.border), borderRadius: BorderRadius.circular(12)),
          child: IconButton(onPressed: () => go('alerts'), icon: Icon(Icons.notifications_outlined, color: P.text)),
        ),
        Positioned(right: 7, top: 6, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: P.danger, shape: BoxShape.circle))),
      ]),
    ]),
    gap(20),
    Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: P.light?[Color(0xFFB5F1E8),Color(0xFFBBDDF9)]:[P.tealDim, Color(0xFF004D8C)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your Safety Score', style: TextStyle(fontSize: 12, color: P.light?P.muted:Color(0xB3FFFFFF))),
            gap(4), Text('87', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, height: 1)),
            gap(4), Text('out of 100 · Updated today', style: TextStyle(fontSize: 12, color: P.light?P.muted:Color(0xB3FFFFFF))),
          ])),
          SizedBox(width: 80, height: 80, child: Stack(alignment: Alignment.center, children: [
            AnimatedSafetyGauge(score:87,size:112),

          ])),
        ]),
        gap(16),
        Row(children: [
          metric('3', 'Active Alerts'), metric('12', 'Drugs Tracked'), metric('94%', 'AI Confidence'),
        ]),
      ]),
    ),
    gap(20),
    section('Quick Actions'),
    GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.52,
      children: [
        sourceAction('Search Drug', Icons.search, 'search', P.teal),
        sourceAction('Analyze Text', Icons.psychology_outlined, 'adrAnalysis', Color(0xFF7C3AED)),
        sourceAction('Dashboard', Icons.bar_chart, 'pharmaDash', Color(0xFF2563EB)),
        sourceAction('Compare Drugs', Icons.shield_outlined, 'compare', P.warning),
      ],
    ),
    gap(20),
    Row(children: [
      Expanded(child: Text('Recent Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      InkWell(onTap: () => go('alerts'), child: Text('See all', style: TextStyle(fontSize: 13, color: P.teal))),
    ]),
    gap(12),
    for (final a in [
      ('Metformin','Lactic Acidosis signal','2h ago',P.danger),
      ('Ibuprofen','GI Bleeding trend','5h ago',P.warning),
      ('Lisinopril','Cough frequency','1d ago',P.success),
    ]) ...[
      card(Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: a.$4.withValues(alpha: .09), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(color: a.$4, shape: BoxShape.circle)))),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.$1, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Text(a.$2, style: TextStyle(fontSize: 12, color: P.muted)),
        ])),
        Text(a.$3, style: TextStyle(fontSize: 11, color: P.muted)),
      ])),
      gap(10),
    ],
    card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('ADR Reports — 6 months', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
        badge('+12%', color: P.success),
      ]),
      gap(10), trendLine([120,145,138,190,175,210]),
      gap(4),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (final m in ['Mar','Apr','May','Jun','Jul','Aug'])
          Text(m, style: TextStyle(fontSize: 10, color: P.muted, fontFamily: 'monospace')),
      ]),
    ])),
    gap(16), section('Monitored Drugs'),
    Wrap(spacing: 8, runSpacing: 8, children: [
      for (final name in ['Metformin','Ibuprofen','Lisinopril','Atorvastatin','+8 more'])
        ActionChip(
          label: Text(name, style: TextStyle(fontSize: 12, color: name == 'Metformin' ? P.navy : P.muted)),
          backgroundColor: name == 'Metformin' ? P.teal : P.surface3,
          side: BorderSide.none,
          onPressed: () { if (name != '+8 more') drug = name; go('drugProfile'); },
        ),
    ]),
  ]);

  Widget sourceAction(String label, IconData icon, String route, Color accent) =>
    InkWell(onTap: () => go(route), borderRadius: BorderRadius.circular(16),
      child: card(Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: accent.withValues(alpha: .09), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: accent, size: 22)),
        gap(10), Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ]), padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12))).animate().fadeIn(duration:350.ms).slideY(begin:.12,end:0);

  Widget quick(String t,IconData icon,String route)=>InkWell(onTap:()=>go(route),child:card(Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,color:P.teal,size:27),gap(12),Text(t,textAlign:TextAlign.center,style:TextStyle(fontSize:13,fontWeight:FontWeight.w700))])));
  Widget quickList(String name,String sub,IconData icon,String route)=>InkWell(onTap:()=>go(route),child:card(Row(children:[Icon(icon,color:P.teal),SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,style:TextStyle(fontWeight:FontWeight.w700)),Text(sub,style:TextStyle(fontSize:11,color:P.muted))])),Icon(Icons.chevron_right,color:P.muted)])));
}
