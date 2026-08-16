import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/app_shell.dart';

enum SearchSource {
  google('Google', 'https://www.google.com/search?q='),
  bing('Bing', 'https://www.bing.com/search?q='),
  baidu('百度', 'https://www.baidu.com/s?wd='),
  bilibili('Bilibili', 'https://search.bilibili.com/all?keyword='),
  zhihu('知乎', 'https://www.zhihu.com/search?q='),
  wikipedia('Wikipedia', 'https://en.wikipedia.org/w/index.php?search=');

  const SearchSource(this.label, this.prefix);

  final String label;
  final String prefix;
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  SearchSource _source = SearchSource.google;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 4,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Focus Search', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('直接去查需要的内容，不经过信息流。'),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: '你想查什么？',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) => _launch(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final source in SearchSource.values)
                ChoiceChip(
                  label: Text(source.label),
                  selected: _source == source,
                  onSelected: (_) => setState(() => _source = source),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _launch,
            icon: const Icon(Icons.open_in_new),
            label: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  Future<void> _launch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      return;
    }
    final encoded = Uri.encodeQueryComponent(query);
    final uri = Uri.parse('${_source.prefix}$encoded');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
