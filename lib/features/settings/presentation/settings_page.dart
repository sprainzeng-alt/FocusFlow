import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local_store.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/app_shell.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(localStoreProvider);
    final settings = state.settings;

    return AppShell(
      currentIndex: 0,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('设置', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          Text('每日目标', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _MinuteStepper(
            value: settings.dailyGoalMinutes,
            min: 30,
            max: 480,
            onChanged: (value) {
              ref
                  .read(localStoreProvider.notifier)
                  .updateSettings(settings.copyWith(dailyGoalMinutes: value));
            },
          ),
          const SizedBox(height: 24),
          Text('本地数据', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.checklist),
            title: const Text('任务'),
            trailing: Text('${state.tasks.length}'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.timer_outlined),
            title: const Text('专注记录'),
            trailing: Text('${state.focusRecords.length}'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showExportDialog(context, ref),
            icon: const Icon(Icons.ios_share),
            label: const Text('导出数据'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => _confirmReset(context, ref),
            icon: const Icon(Icons.restart_alt),
            label: const Text('清空本地数据'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, WidgetRef ref) {
    final exportText = ref.read(localStoreProvider.notifier).exportJson();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出数据'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(exportText),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: exportText));
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制到剪贴板。')),
                );
              }
            },
            child: const Text('复制'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空本地数据？'),
        content: const Text('任务和专注记录会被清空，每日目标会保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(localStoreProvider.notifier).resetLocalData();
              Navigator.of(context).pop();
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}

class _MinuteStepper extends StatelessWidget {
  const _MinuteStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: '减少',
          onPressed: value <= min ? null : () => onChanged(value - 15),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Expanded(
          child: Center(
            child: Text(
              formatMinutes(value),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        IconButton(
          tooltip: '增加',
          onPressed: value >= max ? null : () => onChanged(value + 15),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
