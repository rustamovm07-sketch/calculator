import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/database_backup.dart';
import 'database_service.dart';

class BackupService {
  BackupService(this.database);

  final DatabaseService database;

  Future<void> exportAndShare() async {
    final backup = await database.createBackup();
    final directory = await getTemporaryDirectory();
    final file = File(
      path.join(
        directory.path,
        'adenalin-backup-${DateTime.now().millisecondsSinceEpoch}.json',
      ),
    );
    await file.writeAsString(jsonEncode(backup.toMap()), flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Adenalin Calculator zaxirasi',
      ),
    );
  }

  Future<bool?> chooseAndImport() async {
    final selected = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (selected == null) {
      return null;
    }
    final reportedSize = selected.lengthSync();
    if (reportedSize != null && reportedSize > DatabaseService.maxBackupBytes) {
      throw const FormatException(
        'Zaxira fayli 50 MB dan katta bo‘lishi mumkin emas.',
      );
    }
    final bytes = BytesBuilder(copy: false);
    var totalBytes = 0;
    await for (final chunk in selected.readAsByteStream()) {
      totalBytes += chunk.length;
      if (totalBytes > DatabaseService.maxBackupBytes) {
        throw const FormatException(
          'Zaxira fayli 50 MB dan katta bo‘lishi mumkin emas.',
        );
      }
      bytes.add(chunk);
    }
    final decoded = jsonDecode(utf8.decode(bytes.takeBytes()));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Zaxira faylining formati noto‘g‘ri.');
    }
    return database.importBackup(DatabaseBackup.fromMap(decoded));
  }
}
