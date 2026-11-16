part of '../../main.dart';

class _DatasetImportPanel extends StatefulWidget {
  const _DatasetImportPanel(
      {required this.api, required this.onOpen, required this.onCount});

  final ValueChanged<Map<String, dynamic>> onOpen;
  final ValueChanged<int> onCount;

  final ApiService api;

  @override
  State<_DatasetImportPanel> createState() => _DatasetImportPanelState();
}

class _DatasetImportPanelState extends State<_DatasetImportPanel> {
  static const maxBytes = 1024 * 1024;

  (String, Uint8List)? draft;
  Map<String, dynamic>? preview;
  String? error;
  String? success;
  bool busy = false;
  late Future<Map<String, dynamic>> history = loadHistory();

  Future<Map<String, dynamic>> loadHistory() async {
    final result = await widget.api.datasetHistory();
    if (result['imports'] case final List rows when mounted) {
      widget.onCount(rows.length);
    }
    return result;
  }

  Future<void> selectCsv() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
      success = null;
    });
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        dialogTitle: 'Select dataset CSV',
      );
      if (!mounted || file == null) return;
      setState(() {
        draft = null;
        preview = null;
      });
      if (!file.name.toLowerCase().endsWith('.csv')) {
        throw const AuthApiException('Choose a .csv file.');
      }
      if ((await file.length() ?? 0) > maxBytes) {
        throw const AuthApiException('CSV must be 1 MB or smaller.');
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > maxBytes) {
        throw const AuthApiException('CSV must be 1 MB or smaller.');
      }
      if (!mounted) return;
      final result = await widget.api.previewDataset(file.name, bytes);
      if (!mounted) return;
      setState(() {
        draft = (file.name, bytes);
        preview = result;
      });
    } on AuthApiException catch (failure) {
      if (mounted) setState(() => error = failure.message);
    } catch (_) {
      if (mounted) setState(() => error = 'Could not read the CSV file.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> importCsv() async {
    final file = draft;
    if (file == null || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.api.importDataset(file.$1, file.$2);
      if (!mounted) return;
      setState(() {
        draft = null;
        preview = null;
        success = "Imported ${file.$1} (${result['new_rows']} added).";
        history = loadHistory();
      });
    } on AuthApiException catch (failure) {
      if (mounted) setState(() => error = failure.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget previewCard(Map<String, dynamic> summary) {
    final canImport = (summary['new_rows'] as num? ?? 0) > 0;
    return GradientCard(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CSV Preview',
            style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(draft!.$1),
        const SizedBox(height: 8),
        Text("${summary['total_rows']} rows · ${summary['new_rows']} new · "
            "${summary['duplicate_rows']} duplicate · ${summary['invalid_rows']} invalid"),
        for (final issue in (summary['errors'] as List? ?? const []))
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text("Line ${issue['line']} · ${issue['message']}",
                style: TextStyle(color: P.danger, fontSize: 11)),
          ),
        const SizedBox(height: 8),
        Text(
          canImport
              ? 'Only new, valid rows will be imported.'
              : 'This file has no new valid rows to import.',
          style: TextStyle(color: P.muted, fontSize: 12),
        ),
        Wrap(spacing: 8, children: [
          TextButton(
            onPressed: busy
                ? null
                : () => setState(() {
                      draft = null;
                      preview = null;
                      error = null;
                    }),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: busy || !canImport ? null : importCsv,
            child: const Text('Import CSV'),
          ),
        ]),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 46,
            child: OutlinedButton(
              onPressed: busy ? null : selectCsv,
              style: OutlinedButton.styleFrom(
                backgroundColor: P.teal,
                foregroundColor: P.onAccent,
                side: BorderSide(color: P.teal.withValues(alpha: .7)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: const Text('＋ Add Dataset',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
              'CSV up to 1 MB. Required columns are drug_name, drug_class, and adverse_reaction.',
              style: TextStyle(color: P.muted, fontSize: 11)),
          if (busy)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(),
            ),
          if (error case final String message)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(message, style: TextStyle(color: P.danger))),
          if (success case final String message)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(message, style: TextStyle(color: P.success))),
          if (preview case final summary?) ...[
            const SizedBox(height: 10),
            previewCard(summary),
          ],
          const SizedBox(height: 13),
          const Text('Import History',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          FutureBuilder(
            future: history,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LinearProgressIndicator();
              }
              if (snapshot.hasError) {
                return TextButton(
                  onPressed: () => setState(() => history = loadHistory()),
                  child: const Text('Could not load import history. Retry'),
                );
              }
              final rows = snapshot.requireData['imports'];
              if (rows is! List || rows.isEmpty) {
                return Text('No CSV imports yet.',
                    style: TextStyle(color: P.muted));
              }
              return Column(children: [
                for (final dataset in rows.cast<Map<String, dynamic>>()) ...[
                  InkWell(
                    onTap: () => widget.onOpen(dataset),
                    borderRadius: BorderRadius.circular(20),
                    child: GradientCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(dataset['filename'].toString(),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800))),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: P.success.withValues(alpha: .12),
                                border: Border.all(
                                    color: P.success.withValues(alpha: .3)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('Imported',
                                  style: TextStyle(
                                      color: P.success, fontSize: 11)),
                            ),
                          ]),
                          const SizedBox(height: 5),
                          Text(
                              "CSV · ${dataset['created_at'].toString().split('T').first}",
                              style: TextStyle(color: P.muted, fontSize: 10)),
                          const SizedBox(height: 11),
                          Text(
                              "${dataset['added_rows']} added · ${dataset['duplicate_rows']} duplicate · "
                              "${dataset['invalid_rows']} invalid",
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 14),
                          Text('View / Manage →',
                              style: TextStyle(
                                  color: P.teal,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ]);
            },
          ),
        ],
      );
}
