import 'package:material_ui/material_ui.dart';

import '../../data/models.dart';
import '../../logic/format.dart';
import '../../logic/ranking.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../widgets/widgets.dart';
import 'browse.dart';
import 'checkout.dart';
import 'review.dart';
import 'you.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.tool});
  final Tool tool;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.vx;
    final t = tool;
    final field = s.catalog.fieldOf(t);
    final isA = t.tier == Tier.a;
    final myReviews = s.reviewsFor(t.id);
    final inCompare = s.inCompare(t.id);

    Widget section(String label) => Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 10),
      child: Kicker(label),
    );

    Widget bullet(IconData icon, String text, Color color) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, height: 1.45, color: c.text),
            ),
          ),
        ],
      ),
    );

    return ListView(
      padding: pagePadding,
      children: [
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            VxTag(field.name),
            VxTag(t.sub, kind: VxTagKind.outline),
          ],
        ),
        const SizedBox(height: 14),
        VxCard(
          padding: const EdgeInsets.all(16),
          gradient: isA ? heroGradient(context) : null,
          borderColor: isA ? c.accentSoftBorder : null,
          onTap: () => s.push(const MethodPage()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    TierBadge(t.tier, big: true),
                    const Kicker('Vertex tier', muted: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(t.tier.why, style: VxText.secondary(context, size: 13.5)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'How tiers are set',
                      style: TextStyle(fontSize: 12.5, color: c.accentFg),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Ph.caretRight, size: 12, color: c.accentFg),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          t.verdict,
          style: TextStyle(fontSize: 16, height: 1.5, color: c.text),
        ),
        const SizedBox(height: 8),
        Text(
          'Vertex desk · tested ${t.tested} on ${t.evidence}',
          style: VxText.muted(context),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 26, bottom: 14),
          child: Row(
            children: [
              Expanded(child: Kicker('Measured in ${field.name}')),
              Container(width: 2, height: 12, color: c.neutralFg),
              const SizedBox(width: 6),
              Text('field median', style: VxText.muted(context, size: 11.5)),
            ],
          ),
        ),
        for (final m in Metric.values)
          _MetricBlock(
            metric: m,
            value: t.metrics[m]!,
            median: field.median[m]!,
            note: switch (m) {
              Metric.accuracy => 'Benchmarked on ${t.evidence}',
              Metric.speed => 'Time to a usable answer',
              Metric.value => 'Cost against output quality',
              Metric.integrations => 'Tools it plugs into natively',
            },
          ),

        section('Where it wins'),
        for (final w in t.wins) bullet(Ph.check, w, c.accentFg),
        section('Where it doesn’t'),
        for (final w in t.losses) bullet(Ph.minus, w, c.textMuted),

        section('Connects to'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final i in t.integrations) VxTag(i),
            if (t.integrationsMore.isNotEmpty)
              VxTag(t.integrationsMore, kind: VxTagKind.outline),
          ],
        ),

        section('Plans'),
        VxGroup(
          children: [
            for (final p in t.plans)
              VxRow(
                title: p.name,
                subtitle: p.requiresStudent && !p.note.contains('verification')
                    ? '${p.note.isEmpty ? '' : '${p.note} · '}student email required'
                    : p.note,
                trailing: Text(p.price, style: VxText.title(context)),
              ),
          ],
        ),

        section('Reviews'),
        if (myReviews.isEmpty)
          Text(
            'Used ${t.name}? Tell the desk how it went. Every review is read '
            'by a person before it is published.',
            style: VxText.secondary(context),
          )
        else
          VxGroup(children: [for (final r in myReviews) ReviewRow(review: r)]),
        const SizedBox(height: 12),
        VxButton(
          myReviews.isEmpty ? 'Write a review' : 'Write another review',
          icon: Ph.pencilSimple,
          block: true,
          onTap: () => showReviewSheet(context, t),
        ),
        const SizedBox(height: 8),
        VxButton(
          inCompare ? 'In compare — view head to head' : 'Add to compare',
          icon: Ph.columns,
          block: true,
          onTap: () =>
              inCompare ? s.setTab(VxTab.compare) : s.toggleCompare(t.id),
        ),
      ],
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.metric,
    required this.value,
    required this.median,
    required this.note,
  });
  final Metric metric;
  final MetricValue value;
  final int median;
  final String note;

  @override
  Widget build(BuildContext context) {
    final c = context.vx;
    final diff = value.score - median;
    final delta = '${diff >= 0 ? '+' : ''}$diff vs field median';
    return Semantics(
      label: '${metric.label}: ${value.display}. $delta.',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    metric.label,
                    style: VxText.title(context, size: 14),
                  ),
                ),
                Text(value.display, style: VxText.secondary(context)),
              ],
            ),
            const SizedBox(height: 5),
            MetricBar(
              value: value.score,
              median: median,
              strong: metric == Metric.accuracy,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(note, style: VxText.muted(context, size: 11.5)),
                ),
                Text(
                  delta,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: diff >= 0 ? c.accentFg : c.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pinned call to action under the detail page.
class DetailFooter extends StatelessWidget {
  const DetailFooter({super.key, required this.tool});
  final Tool tool;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final owned = s.purchaseFor(tool.id);
    final active = owned != null && owned.isActive;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active)
            VxButton(
              'Manage plan · ${owned.planName}',
              icon: Ph.checkCircle,
              kind: VxButtonKind.primary,
              block: true,
              onTap: () => showPurchaseSheet(context, owned),
            )
          else
            VxButton(
              'Get ${tool.name} · ${leadPrice(tool, s.role).replaceFirst('From', 'from')}',
              icon: Ph.shoppingBagOpen,
              kind: VxButtonKind.primary,
              block: true,
              onTap: () => showCheckout(context, tool),
            ),
          const SizedBox(height: 6),
          Semantics(
            button: true,
            child: InkWell(
              onTap: () => s.push(const MethodPage()),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Text(
                  active
                      ? 'Renews ${fmtDate(owned.renewsAt)} · cancel any time'
                      : 'We earn a commission on plans bought here · tier unaffected',
                  textAlign: TextAlign.center,
                  style: VxText.muted(context, size: 11.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
