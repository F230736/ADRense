part of '../../main.dart';

extension _SearchViews on _ADRenseAppState {
  Widget search() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Drug Search',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          medicineSearch(searchController),
        ],
      );

  Widget medicineSearch(TextEditingController controller) => _MedicineSearch(
        api: authApi,
        historyKey: activeAccountId == null
            ? null
            : 'adrense.search.${authApi.baseUrl}.$activeAccountId',
        controller: controller,
        onSelected: (medicine) {
          selectedMedicine = medicine;
          drug = medicine['name'] as String;
          drugTab = 'Overview';
          go(role == 'analyst' ? 'analystDrug' : 'drugProfile');
        },
      );
}

class _MedicineSearch extends StatefulWidget {
  const _MedicineSearch(
      {required this.api,
      required this.controller,
      required this.onSelected,
      this.historyKey});

  final ApiService api;
  final String? historyKey;
  final TextEditingController controller;
  final ValueChanged<Map<String, dynamic>> onSelected;

  @override
  State<_MedicineSearch> createState() => _MedicineSearchState();
}

class _MedicineSearchState extends State<_MedicineSearch> {
  static const popular = [
    'Metformin',
    'Ibuprofen',
    'Aspirin',
    'Atorvastatin',
    'Lisinopril',
    'Omeprazole',
    'Amoxicillin'
  ];
  final results = <Map<String, dynamic>>[];
  Timer? debounce;
  late final preferences = SharedPreferencesAsync();
  List<String> history = [];

  Future<void> loadHistory() async {
    final key = widget.historyKey;
    if (key == null) return;
    try {
      final saved = await preferences.getStringList(key);
      if (mounted && history.isEmpty) setState(() => history = saved ?? []);
    } catch (_) {}
  }

  Future<void> remember(String query) async {
    final key = widget.historyKey;
    if (key == null || query.isEmpty) return;
    final updated = [
      query,
      ...history.where((term) => term.toLowerCase() != query.toLowerCase())
    ].take(10).toList();
    setState(() => history = updated);
    try {
      await preferences.setStringList(key, updated);
    } catch (_) {}
  }

  void searchFor(String query) {
    widget.controller.text = query;
    updateQuery(query);
  }

  int generation = 0;
  bool loading = true;
  bool hasMore = false;
  String? error;

  @override
  void initState() {
    super.initState();
    loadHistory();
    fetch();
  }

  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  void updateQuery(String value) {
    generation++;
    debounce?.cancel();
    setState(() {
      results.clear();
      loading = true;
      hasMore = false;
      error = null;
    });
    debounce = Timer(const Duration(milliseconds: 280), fetch);
  }

  Future<void> fetch() async {
    final request = ++generation;
    final query = widget.controller.text.trim();
    if (query.isEmpty) {
      if (mounted && loading) setState(() => loading = false);
      return;
    }
    final offset = results.length;
    try {
      final response = await widget.api.searchMedicines(query, offset: offset);
      final page = (response['medicines'] as List).cast<Map<String, dynamic>>();
      if (!mounted || request != generation) return;
      setState(() {
        results.addAll(page);
        hasMore = response['has_more'] == true;
        loading = false;
      });
    } catch (failure) {
      if (!mounted || request != generation) return;
      setState(() {
        error = failure is AuthApiException
            ? failure.message
            : 'Could not load medicines.';
        loading = false;
      });
    }
  }

  void loadPage() {
    setState(() {
      loading = true;
      error = null;
    });
    fetch();
  }

  @override
  Widget build(BuildContext context) {
    final searching = widget.controller.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSearchField(
          controller: widget.controller,
          onChanged: updateQuery,
          onSubmitted: (value) => remember(value.trim()),
          hintText: 'Search by name, ingredient, or class...',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final name in popular)
              ActionChip(
                label: Text(name),
                onPressed: () {
                  searchFor(name);
                  remember(name);
                },
              ),
          ],
        ),
        if (!searching) ...[
          const SizedBox(height: 16),
          const Text('Search History',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          if (history.isNotEmpty) const SizedBox(height: 4),
          if (history.isEmpty) const Text('No searches yet.'),
          for (final query in history) ...[
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => searchFor(query),
              child: GradientCard(
                child: Row(children: [
                  Icon(Icons.history, color: P.teal),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(query,
                          style: const TextStyle(fontWeight: FontWeight.w700))),
                  Icon(Icons.chevron_right, color: P.muted),
                ]),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ] else ...[
          const SizedBox(height: 18),
          Text('Search Results',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final medicine in results) ...[
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                final query = widget.controller.text.trim();
                remember(query.isEmpty ? medicine['name'] as String : query);
                widget.onSelected(medicine);
              },
              child: GradientCard(
                  child: Row(children: [
                Icon(Icons.medication_outlined, color: P.teal),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(medicine['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (medicine['ingredients'] case final String ingredients)
                        Text(ingredients,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: P.muted, fontSize: 12)),
                      Text(
                        [
                          medicine['action_class'] ??
                              medicine['therapeutic_class'],
                          medicine['source']
                        ].whereType<String>().join(' · '),
                        style: TextStyle(color: P.muted, fontSize: 11),
                      ),
                    ])),
                Icon(Icons.chevron_right, color: P.muted),
              ])),
            ),
            const SizedBox(height: 8),
          ],
          if (loading) const LinearProgressIndicator(),
          if (error != null) ...[
            Text(error!, style: TextStyle(color: P.danger)),
            TextButton(onPressed: loadPage, child: const Text('Retry')),
          ] else if (!loading && results.isEmpty)
            Text('No matching medicines found.',
                style: TextStyle(color: P.muted)),
          if (!loading && error == null && hasMore)
            OutlinedButton(
                onPressed: loadPage, child: const Text('Load more medicines')),
        ],
      ],
    );
  }
}
