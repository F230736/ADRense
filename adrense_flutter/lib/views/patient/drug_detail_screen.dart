part of '../../main.dart';

extension _DrugViews on _ADRenseAppState {
  Widget drugInformation() {
    final id = selectedMedicine?['id'] as String?;
    return _DrugInformation(
      key: ValueKey(id ?? drug),
      api: authApi,
      id: id,
      name: drug,
    );
  }

  Widget drugProfile() => Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
    Row(children: [
      InkWell(onTap: ()=>go('search'),child: Container(width: 38,height: 38,
        decoration: BoxDecoration(color: P.surface2,borderRadius: BorderRadius.circular(11)),
        child: Icon(Icons.chevron_left,color: P.text))),
      SizedBox(width: 10),
      Expanded(child: Text('Drug Search',style: TextStyle(color: P.muted,fontSize: 13))),
      badge('Sample safety data', color: P.muted),
    ]),
    gap(18),
    Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
        Text(drug,style: TextStyle(fontSize: 28,fontWeight: FontWeight.w800)),
        gap(2),
        Text(selectedMedicine?['action_class'] as String? ??
            selectedMedicine?['therapeutic_class'] as String? ?? 'Medicine profile',
          style: TextStyle(color: P.muted,fontSize: 12)),
        gap(11),
        Wrap(spacing: 7,runSpacing: 6,children: [badge('FDA Approved',color: P.success),badge('Class B')]),
      ])),
      donutScore(87),
    ]),
    gap(18),
    Divider(color: P.border,height: 1),
    gap(15),
    Row(children: [metric('1,247','Total ADR Reports'),metric('34%','Top ADR Rate'),metric('2.1%','Severe Rate')]),
    gap(18),
    Container(height: 48,decoration: BoxDecoration(
      color: P.surface,border: Border(bottom: BorderSide(color: P.border))),
      child: Row(children: [
        for (final tab in ['Overview','ADRs','Trends'])
          Expanded(child: InkWell(onTap: ()=>setState(()=>drugTab=tab),
            child: Container(alignment: Alignment.center,
              decoration: BoxDecoration(border: Border(bottom: BorderSide(
                color: drugTab==tab?P.teal:Colors.transparent,width: 2))),
              child: Text(tab,style: TextStyle(color: drugTab==tab?P.teal:P.muted,
                fontWeight: drugTab==tab?FontWeight.w700:FontWeight.w400,fontSize: 13))))),
      ])),
    gap(16),
    if(drugTab=='Overview') ...[
      drugInformation(),
      gap(12),
      Row(children: [
        Expanded(child: actionTile('View\nPersonalized',P.teal,'personalized')),
        SizedBox(width: 9),
        Expanded(child: actionTile('Compare',P.warning,'compare')),
        SizedBox(width: 9),
        Expanded(child: actionTile('View\nAlerts',P.danger,'alerts')),
      ]),
      gap(12),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
        Text('AI Analysis',style: TextStyle(fontWeight: FontWeight.w700)),
        gap(10),
        Text('BioBERT identified Metformin in 1,247 unstructured reports with 94.3% confidence. Top co-occurring adverse reactions include nausea, diarrhea and abdominal pain.',
          style: TextStyle(fontSize: 12,color: P.muted,height: 1.7)),
      ])),
    ],
    if(drugTab=='ADRs') ...[
      Text('Reported ADRs by frequency — BioBERT extracted',
        style: TextStyle(fontSize: 14,fontWeight: FontWeight.w800,color: P.text)),
      gap(15),
      for(final adr in [
        ('Nausea',423,34,'low',P.success),
        ('Diarrhea',348,28,'low',P.success),
        ('Abdominal Pain',262,21,'low',P.success),
        ('Vomiting',187,15,'medium',P.warning),
        ('Lactic Acidosis',25,2,'high',P.danger),
        ('Hypoglycemia',100,8,'medium',P.warning),
      ]) ...[
        Row(children: [
          Container(width: 8,height: 8,decoration: BoxDecoration(color: adr.$5,shape: BoxShape.circle)),
          SizedBox(width: 9),
          Expanded(child: Text(adr.$1,style: TextStyle(fontSize: 13,fontWeight: FontWeight.w700))),
          SizedBox(width: 8),
          badge(adr.$4,color: adr.$5),
          SizedBox(width: 8),
          Text('${adr.$2} reports',style: TextStyle(color: P.muted,fontSize: 11)),
        ]),
        gap(7),
        ClipRRect(borderRadius: BorderRadius.circular(3),child: LinearProgressIndicator(
          value: adr.$3/100,minHeight: 6,backgroundColor: P.surface3,valueColor: AlwaysStoppedAnimation(adr.$5))),
        gap(5),
        Align(alignment: Alignment.centerRight,child: Text('${adr.$3}%',
          style: TextStyle(color: P.muted,fontSize: 10))),
        gap(14),
      ],
      gap(8),
      _GeneralAdrs(
        key: ValueKey(selectedMedicine?['id'] ?? drug),
        api: authApi,
        name: drug,
        medicineId: selectedMedicine?['id'] as String?,
      ),
    ],
    if(drugTab=='Trends') ...[
      card(Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
        Text('ADR Reports — 12 Months',style: TextStyle(fontWeight: FontWeight.w700,fontSize: 14)),
        gap(20),trendLine([40,41,46,51,55,49,61,64,59,69,75,80]),
        gap(6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
          for(final month in ['S','O','N','D','J','F','M','A','M','J','J','A'])
            Expanded(child: FittedBox(fit: BoxFit.scaleDown,
              child: Text(month,style: TextStyle(color: P.muted,fontSize: 9,fontFamily: 'monospace')))),
        ]),
      ])),
      gap(12),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
        Text('ADR Severity Distribution',style: TextStyle(fontWeight: FontWeight.w700,fontSize: 14)),
        gap(20),
        barChart([49,42,33,24,16,8]),
        gap(9),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
          for(final label in ['Nausea','Diarr.','Abdom.','Vomit.','Hypogly.','Lactic'])
            Expanded(child: FittedBox(fit: BoxFit.scaleDown,
              child: Text(label,style: TextStyle(color: P.muted,fontSize: 9,fontFamily: 'monospace')))),
        ]),
      ])),
    ],
  ]);
  Widget actionTile(String label,Color accent,String destination) => InkWell(
    onTap: ()=>go(destination),
    child: Container(height: 54,alignment: Alignment.center,
      decoration: BoxDecoration(color: accent.withValues(alpha: .09),borderRadius: BorderRadius.circular(10)),
      child: Text(label,textAlign: TextAlign.center,style: TextStyle(
        color: accent,fontWeight: FontWeight.w700,fontSize: 12))));
  Widget donutScore(int value, {Color? color}) => SizedBox(
    width: 104, height: 104,
    child: Stack(alignment: Alignment.center, children: [
      CustomPaint(size: Size(104, 104), painter: ScoreRingPainter(value / 100, color??P.teal)),
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text('$value', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
        Text('SCORE', style: TextStyle(color: P.muted, fontSize: 9, letterSpacing: 1)),
      ]),
    ]),
  );

  Widget trendLine(List<double> values) => SizedBox(
    height: 95,
    width: double.infinity,
    child: TweenAnimationBuilder<double>(tween:Tween(begin:0,end:1),
      duration:Duration(milliseconds:1100),curve:Curves.easeOutCubic,
      builder:(context,t,child)=>CustomPaint(painter:TrendPainter(
        values.map((v)=>v*t).toList()))),
  );

  Widget barChart(List<double> heights) => TweenAnimationBuilder<double>(
    tween:Tween(begin:0,end:1),duration:Duration(milliseconds:950),
    curve:Curves.easeOutCubic,
    builder:(context,progress,child)=>SizedBox(height:100,child:Row(
      crossAxisAlignment:CrossAxisAlignment.end,children:heights.map<Widget>((h)=>
        Expanded(child:Padding(padding:EdgeInsets.symmetric(horizontal:5),
          child:Container(height:h*progress,
            decoration:BoxDecoration(color:P.teal.withValues(alpha:.9),
              borderRadius:BorderRadius.circular(4)))))).toList())));
}


class _GeneralAdrs extends StatefulWidget {
  const _GeneralAdrs({
    super.key,
    required this.api,
    required this.name,
    required this.medicineId,
  });

  final ApiService api;
  final String name;
  final String? medicineId;

  @override
  State<_GeneralAdrs> createState() => _GeneralAdrsState();
}

class _GeneralAdrsState extends State<_GeneralAdrs> {
  static const pageSize = 20;
  int visibleRows = pageSize;
  late Future<List<Map<String, dynamic>>> request = load();

  Future<List<Map<String, dynamic>>> load() async {
    final result = await widget.api.generalAdrs(widget.name, medicineId: widget.medicineId);
    return (result['reactions'] as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('General ADRs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: P.text)),
      const SizedBox(height: 5),
      Text('From the imported side-effect dataset', style: TextStyle(fontSize: 12, color: P.muted)),
      const SizedBox(height: 10),
      FutureBuilder(
        future: request,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LinearProgressIndicator();
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(error is AuthApiException ? error.message : 'Could not load general ADRs.'),
                TextButton(
                  onPressed: () => setState(() => request = load()),
                  child: const Text('Retry'),
                ),
              ],
            );
          }
          final rows = snapshot.requireData;
          if (rows.isEmpty) {
            return Text('No general ADRs found for this medicine in the dataset.',
              style: TextStyle(color: P.muted));
          }
          return GradientCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final row in rows.take(visibleRows))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 7, color: P.teal),
                        const SizedBox(width: 9),
                        Expanded(child: Text(row['reaction'].toString(),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                        const SizedBox(width: 9),
                        Flexible(child: Text(row['drug_name'].toString(), textAlign: TextAlign.end,
                          style: TextStyle(fontSize: 11, color: P.muted))),
                      ],
                    ),
                  ),
                if (rows.length > visibleRows)
                  TextButton(
                    onPressed: () => setState(() => visibleRows += pageSize),
                    child: Text('Show more (${rows.length - visibleRows} remaining)'),
                  ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

class _DrugInformation extends StatefulWidget {
  const _DrugInformation({super.key, required this.api, required this.name, this.id});

  final ApiService api;
  final String name;
  final String? id;

  @override
  State<_DrugInformation> createState() => _DrugInformationState();
}

class _DrugInformationState extends State<_DrugInformation> {
  late Future<Map<String, dynamic>?> request = load();

  Future<Map<String, dynamic>?> load() async {
    if (widget.id case final String id) return widget.api.medicineDetails(id);

    // Home shortcuts have a name, while search results already have a catalog ID.
    final response = await widget.api.searchMedicines(widget.name);
    final results = (response['medicines'] as List).cast<Map<String, dynamic>>();
    final name = widget.name.trim().toLowerCase();
    for (final result in results) {
      if ((result['name'] as String).trim().toLowerCase() == name) {
        return widget.api.medicineDetails(result['id'] as String);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => GradientCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Drug Information',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 10),
        FutureBuilder(
          future: request,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LinearProgressIndicator();
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(error is AuthApiException
                      ? error.message
                      : 'Could not load medicine details.'),
                  TextButton(
                    onPressed: () => setState(() => request = load()),
                    child: const Text('Retry'),
                  ),
                ],
              );
            }
            final medicine = snapshot.data;
            if (medicine == null) {
              return const Text('No catalog entry is available for this medicine.');
            }
            const fields = {
              'Active Ingredients': 'ingredients',
              'Drug Class': 'therapeutic_class',
              'Action Class': 'action_class',
              'Chemical Class': 'chemical_class',
              'Primary Use': 'uses',
              'CAS Number': 'cas_number',
              'Status in Source Dataset': 'source_status',
              'Data Source': 'source',
            };
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final field in fields.entries)
                  if (medicine[field.value] case final String value) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(
                        children: [
                          Expanded(child: Text(field.key,
                            style: TextStyle(fontSize: 12, color: P.muted))),
                          Expanded(child: Text(value,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                        ],
                      ),
                    ),
                    Divider(color: P.border, height: 1),
                  ],
              ],
            );
          },
        ),
      ],
    ),
  );
}
