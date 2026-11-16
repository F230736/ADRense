part of '../../main.dart';

extension _AdmindatasetViews on _ADRenseAppState {
  Widget adminDatasetDetail() {
    final dataset = selectedDataset;
    if (dataset == null) return _scroll(const Text('No dataset selected'));
    final filename = dataset['filename'].toString();
    return _pinnedHeaderPage(
      adminDetailHeading('Dataset Details', 'adminDash', 'Imported', P.success),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        adminDataCard('', [
          ('Dataset Name', filename),
          ('Upload Date', dataset['created_at'].toString().split('T').first),
          ('Total CSV Rows', dataset['total_rows'].toString()),
          ('Rows Imported', dataset['added_rows'].toString()),
          ('Duplicate Rows', dataset['duplicate_rows'].toString()),
          ('Invalid Rows', dataset['invalid_rows'].toString()),
        ]),
        gap(12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => showDatasetPreview(dataset['id'] as int, filename),
            icon: const Icon(Icons.preview_outlined),
            label: const Text('Preview Dataset'),
          ),
        ),
        gap(12),
        card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add or Update Data',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          gap(6),
          Text(
              'Imported datasets are read-only here. Use Add Dataset to import another CSV.',
              style: TextStyle(color: P.muted, fontSize: 11, height: 1.5)),
          gap(8),
          const SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: null,
                child: Text('Select Dataset File'),
              )),
        ])),
        gap(12),
        Row(children: [
          Expanded(child: adminAction('Update Dataset', P.teal, null)),
          const SizedBox(width: 8),
          Expanded(
              child:
                  adminAction('Remove Dataset', P.danger, null, outline: true)),
        ]),
      ]),
    );
  }

  Future<void> showDatasetPreview(int id, String filename) async {
    final preview = authApi.datasetImportPreview(id);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dataset Preview'),
        content: SizedBox(
          width: 420,
          child: FutureBuilder(
            future: preview,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LinearProgressIndicator();
              }
              if (snapshot.hasError) {
                final error = snapshot.error;
                return Text(error is AuthApiException
                    ? error.message
                    : 'Could not load the preview.');
              }
              final data = snapshot.requireData;
              final rows = data['rows'] as List?;
              if (rows == null) {
                return const Text(
                    'This dataset was imported before row previews were saved.');
              }
              if (rows.isEmpty)
                return const Text('This import added no new rows.');
              return SingleChildScrollView(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(filename,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                      "Showing ${rows.length} of ${data['added_rows']} imported rows"),
                  for (final row in rows) ...[
                    const Divider(),
                    Text(row['drug_name'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (row['drug_class'] case final String drugClass
                        when drugClass.isNotEmpty)
                      Text(drugClass),
                    Text(row['adverse_reaction'].toString()),
                  ],
                ],
              ));
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }
}
