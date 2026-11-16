import 'dart:convert';
import 'dart:typed_data';

// The platform interface lets this test replace the native file chooser.
// ignore: depend_on_referenced_packages
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adrense_flutter/main.dart';

import 'persistent_session_test.dart' as fixtures;

const csv = 'drug_name,drug_class,adverse_reaction\nSample,Example,Nausea\n';

final class _CsvFile extends PlatformFile {
  @override
  String get name => 'sample.csv';

  @override
  Uri get uri => Uri.file(name);

  @override
  Never get xFile => throw UnimplementedError();

  @override
  int lengthSync() => utf8.encode(csv).length;

  @override
  Future<int> length() async => lengthSync();

  @override
  Future<Uint8List> readAsBytes() async => Uint8List.fromList(utf8.encode(csv));

  @override
  Stream<Uint8List> readAsByteStream() async* {
    yield await readAsBytes();
  }
}

class _CsvPicker extends FilePickerPlatform {
  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    expect(allowedExtensions, ['csv']);
    return _CsvFile();
  }
}

void main() {
  testWidgets(
      'Add Dataset previews a CSV before importing and refreshes history',
      (tester) async {
    final platform = FilePickerPlatform.instance;
    FilePickerPlatform.instance = _CsvPicker();
    addTearDown(() => FilePickerPlatform.instance = platform);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final calls = <String>[];
    var imported = false;
    const summary = {
      'total_rows': 2,
      'new_rows': 1,
      'duplicate_rows': 1,
      'invalid_rows': 0,
      'errors': [],
    };
    final api = fixtures.service(
      fixtures.MemorySessionStore()..token = 'valid',
      handler: (request) async {
        final path = request.url.path;
        if (path.startsWith('/api/admin/datasets/')) {
          calls.add(path.split('/').last);
          expect(request.headers['Authorization'], 'Bearer valid');
          if (path.endsWith('/history')) {
            return fixtures.jsonResponse({
              'imports': [
                if (imported)
                  {
                    'id': 42,
                    'filename': 'sample.csv',
                    'total_rows': 2,
                    'created_at': '2026-11-10T12:00:00Z',
                    'added_rows': 1,
                    'duplicate_rows': 1,
                    'invalid_rows': 0,
                  },
              ],
            });
          }
          if (path.endsWith('/42/preview')) {
            expect(request.method, 'GET');
            return fixtures.jsonResponse({
              'added_rows': 1,
              'rows': [
                {
                  'drug_name': 'Sample',
                  'drug_class': 'Example',
                  'adverse_reaction': 'Nausea'
                },
              ]
            });
          }
          expect(request.method, 'POST');
          expect(request.headers['Content-Type'],
              startsWith('multipart/form-data;'));
          expect(request.body, contains('name="file"; filename="sample.csv"'));
          expect(request.body, contains(csv));
          if (path.endsWith('/import')) imported = true;
          return fixtures.jsonResponse(summary, imported ? 201 : 200);
        }
        if (path.endsWith('/analysts'))
          return fixtures.jsonResponse({'applications': []});
        if (path.endsWith('/users'))
          return fixtures.jsonResponse({'users': []});
        if (path.endsWith('/registrations')) {
          return fixtures.jsonResponse({'summary': {}, 'buckets': []});
        }
        return fixtures.jsonResponse(fixtures.account('admin'));
      },
    );
    await tester.pumpWidget(MaterialApp(home: ADRenseApp(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Datasets'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('＋ Add Dataset'));
    await tester.pumpAndSettle();
    expect(find.text('CSV Preview'), findsOneWidget);
    expect(
        find.text('2 rows · 1 new · 1 duplicate · 0 invalid'), findsOneWidget);
    expect(imported, isFalse);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Import CSV'), findsNothing);

    await tester.tap(find.text('＋ Add Dataset'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Import CSV'));
    await tester.tap(find.text('Import CSV'));
    await tester.pumpAndSettle();
    expect(find.text('Imported sample.csv (1 added).'), findsOneWidget);
    expect(calls, ['history', 'preview', 'preview', 'import', 'history']);
    await tester.ensureVisible(find.text('Import History'));
    await tester.pumpAndSettle();
    expect(find.text('sample.csv'), findsOneWidget);
    expect(find.text('SMM4H Dataset'), findsNothing);
    await tester.tap(find.text('sample.csv'));
    await tester.pumpAndSettle();
    expect(find.text('Dataset Details'), findsOneWidget);
    expect(find.text('Update Dataset'), findsOneWidget);
    expect(find.text('Remove Dataset'), findsOneWidget);
    await tester.tap(find.text('Preview Dataset'));
    await tester.pumpAndSettle();
    expect(find.text('Dataset Preview'), findsOneWidget);
    expect(find.text('Showing 1 of 1 imported rows'), findsOneWidget);
    expect(find.text('Nausea'), findsOneWidget);
    await fixtures.disposeApp(tester);
  });
}
