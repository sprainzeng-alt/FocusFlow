import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/local_store.dart';
import '../../../core/utils/id_generator.dart';
import '../../../shared/widgets/app_shell.dart';

enum SearchSource {
  google('Google', Icons.public, 'https://www.google.com/search?q='),
  bing('Bing', Icons.travel_explore, 'https://www.bing.com/search?q='),
  baidu('百度', Icons.search, 'https://www.baidu.com/s?wd='),
  bilibili('Bilibili', Icons.ondemand_video,
      'https://search.bilibili.com/all?keyword='),
  zhihu('知乎', Icons.forum_outlined, 'https://www.zhihu.com/search?q='),
  wikipedia('Wikipedia', Icons.menu_book_outlined,
      'https://zh.wikipedia.org/w/index.php?search=');

  const SearchSource(this.label, this.icon, this.prefix);

  final String label;
  final IconData icon;
  final String prefix;
}

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  SearchSource _source = SearchSource.google;
  bool _hasQuery = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncQueryState);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_syncQueryState)
      ..dispose();
    super.dispose();
  }

  void _syncQueryState() {
    final hasQuery = _controller.text.trim().isNotEmpty;
    if (hasQuery != _hasQuery) {
      setState(() => _hasQuery = hasQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(localStoreProvider).settings;
    final recentSearches = settings.recentSearches;
    final shortcuts = settings.studyShortcuts;

    return AppShell(
      currentIndex: 4,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Focus Search',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('直接去查需要的内容，不经过信息流。'),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: '你想查什么？',
              prefixIcon: Icon(Icons.search),
            ).copyWith(
              suffixIcon: _hasQuery
                  ? IconButton(
                      tooltip: '清空',
                      onPressed: _controller.clear,
                      icon: const Icon(Icons.close),
                    )
                  : null,
            ),
            onSubmitted: (_) => _launch(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final source in SearchSource.values)
                FilterChip(
                  avatar: Icon(source.icon, size: 18),
                  label: Text(source.label),
                  selected: _source == source,
                  onSelected: (_) => setState(() => _source = source),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  '学习捷径',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: '添加捷径',
                onPressed: () => _showShortcutSheet(context),
                icon: const Icon(Icons.add_link),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (shortcuts.isEmpty)
            const _HintText('把常用网课、资料页、题库链接保存成按钮。')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final shortcut in shortcuts)
                  InputChip(
                    avatar: const Icon(Icons.link, size: 18),
                    label: Text(shortcut.label),
                    onPressed: () => _openShortcut(shortcut),
                    onDeleted: () {
                      ref
                          .read(localStoreProvider.notifier)
                          .deleteStudyShortcut(shortcut.id);
                    },
                  ),
              ],
            ),
          if (recentSearches.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '最近搜索',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(localStoreProvider.notifier).clearRecentSearches();
                  },
                  child: const Text('清空'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final query in recentSearches)
                  ActionChip(
                    label: Text(query),
                    onPressed: () {
                      _controller.text = query;
                      _controller.selection = TextSelection.collapsed(
                        offset: _controller.text.length,
                      );
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _hasQuery ? _launch : null,
            icon: const Icon(Icons.open_in_new),
            label: Text('用 ${_source.label} 搜索'),
          ),
        ],
      ),
    );
  }

  void _showShortcutSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ShortcutForm(
        onSave: (shortcut) {
          ref.read(localStoreProvider.notifier).upsertStudyShortcut(shortcut);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _launch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先输入要搜索的内容。')),
      );
      return;
    }
    final encoded = Uri.encodeQueryComponent(query);
    final uri = Uri.parse('${_source.prefix}$encoded');
    final didLaunch =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (didLaunch) {
      ref.read(localStoreProvider.notifier).recordSearchQuery(query);
    }
    if (!didLaunch && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法打开 ${_source.label}，请稍后再试。')),
      );
    }
  }

  Future<void> _openShortcut(StudyShortcut shortcut) async {
    final uri = Uri.tryParse(shortcut.url);
    if (uri == null) {
      _showMessage('这个链接格式不正确。');
      return;
    }
    final didLaunch =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!didLaunch && mounted) {
      _showMessage('无法打开 ${shortcut.label}，请检查链接。');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ShortcutForm extends StatefulWidget {
  const _ShortcutForm({required this.onSave});

  final ValueChanged<StudyShortcut> onSave;

  @override
  State<_ShortcutForm> createState() => _ShortcutFormState();
}

class _ShortcutFormState extends State<_ShortcutForm> {
  final _label = TextEditingController();
  final _url = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('添加学习捷径', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _label,
            decoration: const InputDecoration(
              labelText: '按钮名称',
              prefixIcon: Icon(Icons.drive_file_rename_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: '网页链接',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.add),
            label: const Text('保存捷径'),
          ),
        ],
      ),
    );
  }

  void _save() {
    final label = _label.text.trim();
    final normalizedUrl = _normalizeUrl(_url.text.trim());
    final uri = Uri.tryParse(normalizedUrl);
    final isValidUrl =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    if (label.isEmpty || !isValidUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写名称和有效网页链接。')),
      );
      return;
    }

    widget.onSave(
      StudyShortcut(
        id: createId(),
        label: label,
        url: normalizedUrl,
        createdAt: DateTime.now(),
      ),
    );
  }

  String _normalizeUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return 'https://$value';
  }
}

class _HintText extends StatelessWidget {
  const _HintText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
