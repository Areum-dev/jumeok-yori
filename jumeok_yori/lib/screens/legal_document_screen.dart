import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class LegalDocumentScreen extends StatefulWidget {
  final String title;
  final String assetPath;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  String? _content;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final raw = await rootBundle.loadString(widget.assetPath);
      setState(() {
        _content = raw;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '문서를 불러오지 못했습니다.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(
        backgroundColor: AppColors.ivory,
        title: Text(widget.title),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: AppColors.error)),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: _MarkdownText(content: _content ?? ''),
    );
  }
}

/// flutter_markdown 없이 간단히 마크다운을 렌더링하는 위젯.
/// # 헤딩, **굵게**, 일반 텍스트, 빈 줄 처리.
class _MarkdownText extends StatelessWidget {
  final String content;

  const _MarkdownText({required this.content});

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      if (trimmed.startsWith('### ')) {
        widgets.add(_heading(trimmed.substring(4), 15, FontWeight.w700));
        widgets.add(const SizedBox(height: 4));
      } else if (trimmed.startsWith('## ')) {
        widgets.add(_heading(trimmed.substring(3), 17, FontWeight.w800));
        widgets.add(const SizedBox(height: 4));
      } else if (trimmed.startsWith('# ')) {
        widgets.add(_heading(trimmed.substring(2), 20, FontWeight.w900));
        widgets.add(const SizedBox(height: 8));
      } else if (trimmed.startsWith('---')) {
        widgets.add(const Divider(color: AppColors.softGray));
        widgets.add(const SizedBox(height: 4));
      } else if (trimmed.startsWith('| ')) {
        widgets.add(_tableRow(trimmed));
        widgets.add(const SizedBox(height: 2));
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        widgets.add(_bulletItem(trimmed.substring(2)));
        widgets.add(const SizedBox(height: 2));
      } else if (RegExp(r'^\d+\.').hasMatch(trimmed)) {
        final dot = trimmed.indexOf('.');
        widgets.add(_bulletItem(trimmed.substring(dot + 1).trim(),
            prefix: '${trimmed.substring(0, dot + 1)} '));
        widgets.add(const SizedBox(height: 2));
      } else {
        widgets.add(_paragraph(trimmed));
        widgets.add(const SizedBox(height: 4));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _heading(String text, double size, FontWeight weight) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: size,
            fontWeight: weight,
            color: AppColors.darkInk,
          ),
        ),
      );

  Widget _paragraph(String text) {
    // **bold** 파싱
    final spans = _parseInline(text);
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.darkInk,
          height: 1.6,
        ),
        children: spans,
      ),
    );
  }

  Widget _bulletItem(String text, {String prefix = '• '}) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prefix,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textGray, height: 1.6)),
          Expanded(child: _paragraph(text)),
        ],
      );

  Widget _tableRow(String line) {
    if (line.replaceAll(RegExp(r'[-| ]'), '').isEmpty) {
      return const SizedBox.shrink();
    }
    final cells = line
        .split('|')
        .where((c) => c.trim().isNotEmpty)
        .map((c) => c.trim())
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: cells
            .map(
              (c) => Expanded(
                child: Text(
                  c,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkInk,
                    height: 1.5,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  List<TextSpan> _parseInline(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int last = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return spans;
  }
}
