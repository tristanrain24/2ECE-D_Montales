import '../data/models.dart';

/// Tools are only ever ordered against others in the same field:
/// tier first, accuracy as the tie-break.
int compareByTier(Tool a, Tool b) {
  final t = b.tier.rank - a.tier.rank;
  return t != 0 ? t : b.accuracy - a.accuracy;
}

List<Tool> rankField(Catalog catalog, String fieldId) =>
    catalog.toolsIn(fieldId)..sort(compareByTier);

enum TierFilter {
  any('Any'),
  bAndUp('B and up'),
  aOnly('A only');

  const TierFilter(this.label);
  final String label;
}

enum PriceFilter {
  any('Any'),
  under40('Under \$40'),
  freeOrStudent('Free or student');

  const PriceFilter(this.label);
  final String label;
}

enum SortOrder {
  tier('By tier'),
  accuracy('By accuracy'),
  price('By price');

  const SortOrder(this.label);
  final String label;
  SortOrder get next => values[(index + 1) % values.length];
}

List<Tool> filterField(
  Catalog catalog,
  String fieldId, {
  String? sub,
  TierFilter tier = TierFilter.any,
  PriceFilter price = PriceFilter.any,
  SortOrder sort = SortOrder.tier,
}) {
  var list = catalog.toolsIn(fieldId);
  if (sub != null) list = list.where((t) => t.sub == sub).toList();
  switch (tier) {
    case TierFilter.aOnly:
      list = list.where((t) => t.tier == Tier.a).toList();
    case TierFilter.bAndUp:
      list = list.where((t) => t.tier != Tier.c).toList();
    case TierFilter.any:
  }
  switch (price) {
    case PriceFilter.under40:
      list = list.where((t) => t.priceDollars < 40).toList();
    case PriceFilter.freeOrStudent:
      list = list
          .where((t) => t.plans.any((p) => p.isFree || p.requiresStudent))
          .toList();
    case PriceFilter.any:
  }
  switch (sort) {
    case SortOrder.accuracy:
      list.sort((a, b) => b.accuracy - a.accuracy);
    case SortOrder.price:
      list.sort((a, b) => a.priceDollars - b.priceDollars);
    case SortOrder.tier:
      list.sort(compareByTier);
  }
  return list;
}

/// The price we lead with depends on who is asking. It never changes a tier.
String leadPrice(Tool t, Role? role) {
  if (role == Role.student) {
    final p = t.plans
        .where(
          (p) => p.requiresStudent || p.name.toLowerCase().contains('cohort'),
        )
        .firstOrNull;
    if (p != null) {
      return p.requiresStudent ? '${p.price} for students' : p.price;
    }
  }
  if (role == Role.team) {
    final p = t.plans.where((p) => p.isTeamPlan).firstOrNull;
    if (p != null) return '${p.price} · team';
  }
  return 'From ${t.plans.first.price}';
}

class CompareRow {
  const CompareRow(this.label, this.values, this.best);
  final String label;
  final List<String> values;

  /// Indexes of the winning cells. Empty when fewer than two tools compare.
  final Set<int> best;
}

List<CompareRow> compareRows(List<Tool> tools) {
  CompareRow row(
    String label,
    String Function(Tool) show,
    num Function(Tool) n,
  ) {
    final raw = tools.map(n).toList();
    final best = <int>{};
    if (tools.length > 1) {
      final top = raw.reduce((a, b) => a > b ? a : b);
      for (var i = 0; i < raw.length; i++) {
        if (raw[i] == top) best.add(i);
      }
    }
    return CompareRow(label, tools.map(show).toList(), best);
  }

  int evidenceCount(Tool t) =>
      int.tryParse(t.evidence.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  return [
    row('Vertex tier', (t) => t.tier.label, (t) => t.tier.rank),
    row(
      'Accuracy',
      (t) => t.metrics[Metric.accuracy]!.display.replaceAll('/100', ''),
      (t) => t.accuracy,
    ),
    row(
      'Speed',
      (t) => t.metrics[Metric.speed]!.display.replaceAll(' median', ''),
      (t) => t.metrics[Metric.speed]!.score,
    ),
    row('Price', (t) => t.price, (t) => -t.priceDollars),
    row(
      'Integrations',
      (t) => t.metrics[Metric.integrations]!.display.replaceAll(' native', ''),
      (t) => t.metrics[Metric.integrations]!.score,
    ),
    row('Evidence', (t) => t.evidence, evidenceCount),
  ];
}

Tool? compareWinner(List<Tool> tools) {
  if (tools.isEmpty) return null;
  return (tools.toList()..sort(compareByTier)).first;
}

String compareVerdict(List<Tool> tools) {
  if (tools.isEmpty) return '';
  if (tools.length == 1) return 'Add a second tool and we’ll call a winner.';
  final w = compareWinner(tools)!;
  final lead = w.verdict.split('.').first;
  return '${w.name} takes it. $lead. '
      'The others are only right if that trade-off does not suit you.';
}
