import '../data/models.dart';
import 'ranking.dart';

const _stop = {'and', 'the', 'for', 'with', 'of', 'in', 'a', 'an', 'to', '&'};

const searchSuggestions = [
  'radiology',
  'circuit design',
  'literature review',
  'contract review',
  'systems code',
  'forecasting',
  'study & recall',
  'GD&T',
];

int _score(String hay, List<String> words) {
  var n = 0;
  for (final w in words) {
    final stem = w.replaceFirst(RegExp(r'(ing|ed|es|s)$'), '');
    if (hay.contains(w)) {
      n += 2;
    } else if (stem.length > 2 && hay.contains(stem)) {
      n += 1;
    }
  }
  return n;
}

/// Matches a task, field or tool name. Best match first; tier breaks ties.
List<Tool> searchTools(Catalog catalog, String query) {
  final words = query
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty && !_stop.contains(w))
      .toList();
  if (words.isEmpty) return const [];
  final scored = <(Tool, int)>[];
  for (final t in catalog.tools) {
    final hay =
        '${t.name} ${t.sub} ${t.verdict} ${t.keywords} ${catalog.fieldOf(t).name}'
            .toLowerCase();
    final n = _score(hay, words);
    if (n > 0) scored.add((t, n));
  }
  scored.sort((a, b) {
    final d = b.$2 - a.$2;
    return d != 0 ? d : compareByTier(a.$1, b.$1);
  });
  return scored.map((e) => e.$1).toList();
}
