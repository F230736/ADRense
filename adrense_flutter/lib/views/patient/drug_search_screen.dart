part of '../../main.dart';

extension _SearchViews on _ADRenseAppState {
  Widget search() {
    final entries = <(String, String, int, int, Color)>[
      ('Metformin', 'Biguanide · Antidiabetic', 234, 87, P.success),
      ('Ibuprofen', 'NSAID · Analgesic', 412, 72, P.warning),
      ('Lisinopril', 'ACE Inhibitor', 189, 79, P.success),
      ('Atorvastatin', 'Statin · Lipid-lowering', 298, 81, P.success),
      ('Warfarin', 'Anticoagulant', 521, 58, P.danger),
    ];
    final filtered = entries.where((d) => d.$1.toLowerCase().contains(searchController.text.toLowerCase()) ||
      d.$2.toLowerCase().contains(searchController.text.toLowerCase())).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('Drug Search', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
        badge('847 drugs'),
      ]),
      gap(20),
      AnimatedSearchField(
        controller: searchController,
        onChanged: (_) => setState(() {}),
        hintText: 'Search by drug name, class or ADR...',
      ),
      gap(20), section('Popular Drugs'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final name in ['Metformin','Ibuprofen','Aspirin','Atorvastatin','Lisinopril','Omeprazole','Amoxicillin'])
          ActionChip(
            label: Text(name, style: TextStyle(color: P.muted, fontSize: 12)),
            backgroundColor: P.surface3, side: BorderSide(color:P.teal.withValues(alpha:.18)),
            onPressed: () { setState(() => searchController.text=name); },
          ),
      ]),
      gap(20), section('Search Results'),
      for (final d in filtered) ...[
        InkWell(onTap: () { drug = d.$1; go('drugProfile'); },
          borderRadius: BorderRadius.circular(16),
          child: card(Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(
              color: P.teal.withValues(alpha: .09), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.medical_information_outlined, color: P.teal, size: 22)),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.$1, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text(d.$2, style: TextStyle(fontSize: 12, color: P.muted)),
              gap(6),
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: d.$5, shape: BoxShape.circle)),
                SizedBox(width: 8),
                Text('${d.$3} ADR reports', style: TextStyle(fontSize: 11, color: P.muted)),
              ]),
            ])),
            AnimatedSafetyGauge(score:d.$4,size:57),
          ]), padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14))).animate().fadeIn(duration:350.ms).slideY(begin:.07,end:0),
        gap(10),
      ],
      if (filtered.isEmpty) card(Text('No matching medicines found.', style: TextStyle(color: P.muted))),
    ]);
  }
}
