import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import '../../../core/services/backup_service.dart';
import '../../../widgets/app_components.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  (int, int, int, int, int)? _counts;
  int? _databaseSize;
  bool _busy = false;

  Future<void> _loadInfo() async {
    try {
      final state = AppScope.of(context);
      final values = await Future.wait<Object>([
        state.database.getRecordCounts(),
        state.database.getDatabaseSize(),
      ]);
      if (mounted) {
        setState(() {
          _counts = values[0] as (int, int, int, int, int);
          _databaseSize = values[1] as int;
        });
      }
    } catch (error) {
      if (mounted) {
        showMessage(
          context,
          'Ma’lumotlar bazasi holatini o‘qib bo‘lmadi: $error',
        );
      }
    }
  }

  Future<void> _backup() async {
    setState(() => _busy = true);
    try {
      await BackupService(AppScope.of(context).database).exportAndShare();
      if (mounted) {
        showMessage(context, 'Zaxira fayli ulashish oynasiga tayyorlandi.');
      }
    } catch (error) {
      if (mounted) showMessage(context, 'Zaxira yaratilmadi: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final state = AppScope.of(context);
    setState(() => _busy = true);
    try {
      final imported = await BackupService(state.database).chooseAndImport();
      if (imported == null) return;
      await state.reload();
      if (mounted) {
        showMessage(
          context,
          imported
              ? 'Zaxira ma’lumotlari qo‘shildi.'
              : 'Bu zaxira avval tiklangan.',
        );
        await _loadInfo();
      }
    } catch (error) {
      if (mounted) showMessage(context, 'Zaxirani tiklab bo‘lmadi: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAll() async {
    final state = AppScope.of(context);
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Barcha ma’lumotlarni o‘chirish'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bu amal qaytarilmaydi. Oldin zaxira nusxasini oling.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Tasdiqlash uchun O‘CHIRISH deb yozing',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Bekor qilish'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(context, controller.text == 'O‘CHIRISH'),
                child: const Text('O‘chirish'),
              ),
            ],
          ),
        ) ??
        false;
    controller.dispose();
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await state.database.deleteAllData();
      await state.reload();
      if (mounted) {
        showMessage(context, 'Barcha mahalliy yozuvlar o‘chirildi.');
        await _loadInfo();
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, 'Ma’lumotlarni o‘chirib bo‘lmadi: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_counts == null) {
      _loadInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar va zaxira')),
      body: pageContent(
        title: 'Sozlamalar',
        subtitle: 'Ko‘rinish va ma’lumotlaringizni boshqaring',
        children: [
          SectionCard(
            title: 'Ko‘rinish',
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Tizim rejimi qurilma mavzusiga amal qiladi.'),
                ),
                const SizedBox(height: 10),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto),
                      label: Text('Tizim'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Yorug‘'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Tungi'),
                    ),
                  ],
                  selected: {state.themeMode},
                  onSelectionChanged:
                      _busy ? null : (value) => state.setTheme(value.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Ma’lumotlar va zaxira',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Zaxira JSON formatida. Tiklash mavjud yozuvlarga qo‘shadi va bir xil faylni qayta import qilishdan himoya qiladi.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _backup,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Zaxira nusxasini ulashish'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _restore,
                  icon: const Icon(Icons.restore),
                  label: const Text('Zaxiradan tiklash'),
                ),
                const SizedBox(height: 12),
                Text(
                  _counts == null
                      ? 'Ma’lumotlar bazasi ma’lumoti yuklanmoqda…'
                      : 'Otlar: ${_counts!.$1} · o‘lchovlar: ${_counts!.$2} · qazi: ${_counts!.$3} · '
                          'xarajatlar: ${_counts!.$4} · mahsulotlar: ${_counts!.$5}\n'
                          'Baza hajmi: ${((_databaseSize ?? 0) / 1024).toStringAsFixed(1)} KB',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const SectionCard(
            title: 'Ilova haqida',
            child: Text(
              'Adenalin Calculator · offline ishlab chiqarish qaydlari va tahlil · O‘zbekcha · kg',
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Xavfli amal',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Bu amal ushbu qurilmadagi barcha yozuvlarni butunlay o‘chiradi.',
                ),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : _deleteAll,
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Barcha ma’lumotlarni o‘chirish'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
