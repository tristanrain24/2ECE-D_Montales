import 'package:material_ui/material_ui.dart';

import '../../data/models.dart';
import '../../logic/format.dart';
import '../../logic/ranking.dart';
import '../../logic/search.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../sheets.dart';
import '../widgets/widgets.dart';

const pagePadding = EdgeInsets.fromLTRB(18, 6, 18, 28);

LinearGradient heroGradient(BuildContext context) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: const [0, 0.78],
  colors: [context.vx.accentSoft, context.vx.surface],
);

/// Tier, name, sub-discipline and a chevron — the standard way a tool is
/// listed.
class ToolRow extends StatelessWidget {
  const ToolRow(this.tool, {super.key, this.subtitle, this.trailing});
  final Tool tool;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => VxRow(
    leading: SizedBox(
      width: 30,
      child: Align(
        alignment: Alignment.centerLeft,
        child: TierBadge(tool.tier, word: false),
      ),
    ),
    title: tool.name,
    subtitle: subtitle ?? tool.sub,
    trailing: trailing,
    chevron: true,
    onTap: () => AppScope.read(context).openTool(tool.id),
  );
}

// ───────── home ─────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.vx;
    final ranked = s.ranked;
    final hero = ranked.first;
    final runners = ranked.skip(1).take(3).toList();
    final isA = hero.tier == Tier.a;
    return ListView(
      padding: pagePadding,
      children: [
        const SizedBox(height: 8),
        Kicker(
          s.role == null ? s.field.name : '${s.field.name} · ${s.role!.label}',
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                s.role == null ? 'Here’s the call.' : 'Here’s your call.',
                style: VxText.display(context, size: 25),
              ),
            ),
            VxButton(
              'Change',
              dense: true,
              onTap: () => s.setTab(VxTab.fields),
            ),
          ],
        ),
        const SizedBox(height: 16),
        VxCard(
          padding: const EdgeInsets.all(18),
          gradient: isA ? heroGradient(context) : null,
          borderColor: isA ? c.accentSoftBorder : null,
          onTap: () => s.openTool(hero.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TierBadge(hero.tier, big: true),
              const SizedBox(height: 14),
              Text(hero.name, style: VxText.display(context, size: 30)),
              const SizedBox(height: 2),
              Text(hero.sub, style: VxText.secondary(context)),
              const SizedBox(height: 14),
              Text(
                hero.verdict,
                style: TextStyle(fontSize: 14.5, height: 1.5, color: c.text),
              ),
              const SizedBox(height: 16),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 6,
                children: [
                  Text(
                    leadPrice(hero, s.role),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: c.accentFg,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: 'See the full report ',
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            Ph.arrowRight,
                            size: 14,
                            color: c.accentFg,
                          ),
                        ),
                      ],
                    ),
                    style: TextStyle(fontSize: 13, color: c.accentFg),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(child: Kicker('Runners-up')),
            VxButton(
              'All ${ranked.length}',
              kind: VxButtonKind.ghost,
              dense: true,
              onTap: () => s.openField(s.field.id),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (runners.isEmpty)
          Text(
            '${hero.name} is the only ${s.field.name} tool that has cleared '
            'our bar so far. More are in testing.',
            style: VxText.secondary(context),
          )
        else
          VxGroup(children: [for (final t in runners) ToolRow(t)]),
        const SizedBox(height: 18),
        VxGroup(
          children: [
            VxRow(
              leading: Icon(Ph.sealCheck, size: 22, color: c.accentFg),
              title: 'How a tier gets decided',
              subtitle:
                  '${s.catalog.tools.length} tools · ${s.catalog.fields.length} fields · re-scored monthly',
              chevron: true,
              onTap: () => s.push(const MethodPage()),
            ),
          ],
        ),
      ],
    );
  }
}

// ───────── fields ─────────

class FieldsScreen extends StatelessWidget {
  const FieldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.vx;
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 620 ? 2 : 1;
        const gap = 10.0;
        final w = (box.maxWidth - 36 - gap * (cols - 1)) / cols;
        return ListView(
          padding: pagePadding,
          children: [
            const SizedBox(height: 4),
            Text(
              'Every tool is ranked against its own field. Pick yours.',
              style: VxText.secondary(context, size: 14),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final f in s.catalog.fields)
                  SizedBox(
                    width: w,
                    child: Builder(
                      builder: (context) {
                        final list = s.catalog.toolsIn(f.id);
                        final a = list.where((t) => t.tier == Tier.a).length;
                        final current = f.id == s.field.id;
                        return VxCard(
                          onTap: () => s.openField(f.id),
                          borderColor: current ? c.accent : null,
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: current ? c.accentSoft : c.neutralSoft,
                                  borderRadius: BorderRadius.circular(vxRadius),
                                ),
                                child: Icon(
                                  fieldIcon(f.icon),
                                  size: 22,
                                  color: current ? c.accentFg : c.neutralFg,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      f.name,
                                      style: VxText.title(context, size: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      f.subs,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: VxText.muted(context),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        VxTag(
                                          a > 0 ? '$a at A-tier' : 'No A-tier',
                                          kind: a > 0
                                              ? VxTagKind.accent
                                              : VxTagKind.neutral,
                                        ),
                                        Text(
                                          '${list.length} ${list.length == 1 ? 'tool' : 'tools'}',
                                          style: VxText.muted(
                                            context,
                                            size: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Ph.caretRight, size: 15, color: c.textMuted),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ───────── category ─────────

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.field});
  final Field field;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final all = s.catalog.toolsIn(field.id);
    final subs = <String>[];
    for (final t in all) {
      if (!subs.contains(t.sub)) subs.add(t.sub);
    }
    final results = filterField(
      s.catalog,
      field.id,
      sub: s.sub,
      tier: s.tierFilter,
      price: s.priceFilter,
      sort: s.sort,
    );
    return ListView(
      padding: const EdgeInsets.only(top: 6, bottom: 28),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              VxChip(
                s.filterActive ? 'Filters on' : 'Filter',
                icon: Ph.slidersHorizontal,
                selected: s.filterActive,
                onTap: () => showFilterSheet(context, field),
              ),
              const SizedBox(width: 8),
              VxChip(
                'All',
                selected: s.sub == null,
                onTap: () => s.setSub(null),
              ),
              for (final x in subs) ...[
                const SizedBox(width: 8),
                VxChip(x, selected: s.sub == x, onTap: () => s.setSub(x)),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${results.length} ${results.length == 1 ? 'tool' : 'tools'}'
                  '${s.filterActive || s.sub != null ? ' after filters' : ' rated'}',
                  style: VxText.muted(context),
                ),
              ),
              VxButton(
                s.sort.label,
                icon: Ph.arrowsDownUp,
                kind: VxButtonKind.ghost,
                dense: true,
                onTap: s.cycleSort,
              ),
            ],
          ),
        ),
        if (results.isEmpty)
          EmptyState(
            icon: Ph.funnelSimple,
            message: 'Nothing clears that filter in this field.',
            action: VxButton('Reset filters', onTap: s.clearFilters),
          ),
        for (final t in results)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: VxCard(
              onTap: () => s.openTool(t.id),
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
                        TierBadge(t.tier),
                        Text(t.price, style: VxText.secondary(context)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(t.name, style: VxText.title(context, size: 18)),
                  const SizedBox(height: 1),
                  Text(t.sub, style: VxText.muted(context)),
                  const SizedBox(height: 8),
                  Text(t.verdict, style: VxText.secondary(context, size: 13.5)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> showFilterSheet(BuildContext context, Field field) =>
    showVxBottomSheet<void>(context, (ctx) {
      final s = AppScope.of(ctx);
      final count = filterField(
        s.catalog,
        field.id,
        sub: s.sub,
        tier: s.tierFilter,
        price: s.priceFilter,
      ).length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Filter ${field.name}', style: VxText.display(ctx, size: 21)),
          const SizedBox(height: 18),
          const Kicker('Minimum tier'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in TierFilter.values)
                VxChip(
                  f.label,
                  selected: s.tierFilter == f,
                  onTap: () => s.setTierFilter(f),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Kicker('Price'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in PriceFilter.values)
                VxChip(
                  f.label,
                  selected: s.priceFilter == f,
                  onTap: () => s.setPriceFilter(f),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              VxButton('Reset', onTap: s.clearFilters),
              const SizedBox(width: 10),
              Expanded(
                child: VxButton(
                  'Show $count',
                  kind: VxButtonKind.primary,
                  onTap: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ],
      );
    });

// ───────── search ─────────

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(String q) {
    _controller.value = TextEditingValue(
      text: q,
      selection: TextSelection.collapsed(offset: q.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final q = _controller.text.trim();
    final hits = searchTools(s.catalog, q);
    return ListView(
      padding: pagePadding,
      children: [
        VxField(
          controller: _controller,
          hint: 'Task, field or tool name',
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          prefix: Icon(
            Ph.magnifyingGlass,
            size: 18,
            color: context.vx.textMuted,
          ),
          suffix: q.isEmpty
              ? null
              : VxIconButton(
                  Ph.xCircle,
                  label: 'Clear search',
                  size: 18,
                  onTap: () => _set(''),
                ),
        ),
        const SizedBox(height: 18),
        if (q.isEmpty) ...[
          const Kicker('Try a discipline', muted: true),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final x in searchSuggestions)
                VxChip(x, selected: false, onTap: () => _set(x)),
            ],
          ),
        ] else if (hits.isEmpty)
          const EmptyState(
            icon: Ph.magnifyingGlass,
            message: 'Nothing matches that. Try a task or a discipline.',
          )
        else ...[
          Kicker(
            '${hits.length} ${hits.length == 1 ? 'match' : 'matches'}',
            muted: true,
          ),
          const SizedBox(height: 8),
          VxGroup(
            children: [
              for (final t in hits)
                ToolRow(t, subtitle: '${s.catalog.fieldOf(t).name} · ${t.sub}'),
            ],
          ),
        ],
      ],
    );
  }
}

// ───────── compare ─────────

class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.vx;
    final tools = s.compareTools;
    if (tools.isEmpty) {
      return ListView(
        padding: pagePadding,
        children: [
          EmptyState(
            icon: Ph.columns,
            message:
                'Nothing lined up yet. Add two or three from a field and '
                'we’ll tell you which one to take.',
            action: VxButton(
              'Browse ${s.field.name}',
              kind: VxButtonKind.primary,
              onTap: () => s.openField(s.field.id),
            ),
          ),
        ],
      );
    }
    final rows = compareRows(tools);
    final winner = compareWinner(tools)!;
    final field = s.catalog.fieldOf(tools.first);
    const labelFlex = 5;
    const cellFlex = 6;
    return ListView(
      padding: pagePadding,
      children: [
        const SizedBox(height: 4),
        Kicker('${field.name} · ${tools.length} of $maxCompare'),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Spacer(flex: labelFlex),
            for (final t in tools)
              Expanded(
                flex: cellFlex,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(-13, 0),
                      child: VxIconButton(
                        Ph.x,
                        size: 15,
                        label: 'Remove ${t.name} from compare',
                        onTap: () => s.toggleCompare(t.id),
                      ),
                    ),
                    Semantics(
                      button: true,
                      child: InkWell(
                        onTap: () => s.openTool(t.id),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8, right: 6),
                          child: Text(
                            t.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: VxText.title(context, size: 15.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        for (final r in rows)
          Container(
            constraints: const BoxConstraints(minHeight: 52),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.divider)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: labelFlex,
                  child: Text(r.label, style: VxText.muted(context)),
                ),
                for (var i = 0; i < r.values.length; i++)
                  Expanded(
                    flex: cellFlex,
                    child: Semantics(
                      label: r.best.contains(i) ? 'Best' : null,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              r.values[i],
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                                color: r.best.contains(i) ? c.accentFg : c.text,
                              ),
                            ),
                          ),
                          if (r.best.contains(i))
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(left: 6, right: 4),
                              decoration: BoxDecoration(
                                color: c.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        VxCard(
          gradient: tools.length > 1 ? heroGradient(context) : null,
          borderColor: tools.length > 1 ? c.accentSoftBorder : null,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Kicker('Our call'),
              const SizedBox(height: 8),
              Text(
                compareVerdict(tools),
                style: TextStyle(fontSize: 14.5, height: 1.5, color: c.text),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (tools.length > 1)
          VxButton(
            'Open ${winner.name}',
            kind: VxButtonKind.primary,
            block: true,
            onTap: () => s.openTool(winner.id),
          ),
        if (tools.length < maxCompare) ...[
          const SizedBox(height: 8),
          VxButton(
            'Add another from ${field.name}',
            block: true,
            icon: Ph.plus,
            onTap: () => s.openField(field.id),
          ),
        ],
      ],
    );
  }
}

// ───────── saved ─────────

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.vx;
    final tools = s.saved.map(s.catalog.tool).whereType<Tool>().toList();
    if (tools.isEmpty) {
      return ListView(
        padding: pagePadding,
        children: [
          EmptyState(
            icon: Ph.bookmarkSimple,
            message: 'Nothing saved yet.',
            action: VxButton(
              'Browse fields',
              kind: VxButtonKind.primary,
              onTap: () => s.setTab(VxTab.fields),
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: pagePadding,
      children: [
        const SizedBox(height: 4),
        VxGroup(
          children: [
            for (final t in tools)
              ToolRow(
                t,
                subtitle: '${s.catalog.fieldOf(t).name} · ${t.price}',
                trailing: Text(
                  moveNote(t.move),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: t.move == 0 ? FontWeight.w400 : FontWeight.w500,
                    color: t.move > 0 ? c.accentFg : c.textMuted,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'We re-score every tool monthly. Each saved tool shows how its tier '
          'moved at the last pass (${s.catalog.lastFullPass}).',
          style: VxText.secondary(context),
        ),
      ],
    );
  }
}

// ───────── method ─────────

class MethodScreen extends StatelessWidget {
  const MethodScreen({super.key});

  static const _measures = [
    (
      Ph.target,
      'Accuracy',
      'A fixed task set written by practitioners in that field — not a general benchmark. Scores are only ever compared inside the field.',
    ),
    (
      Ph.timer,
      'Speed',
      'Median time from prompt to a result you could actually use, measured on the same hardware and connection.',
    ),
    (
      Ph.currencyCircleDollar,
      'Price / value',
      'List price weighed against output quality at that price, including student and academic tiers.',
    ),
    (
      Ph.plugsConnected,
      'Integrations',
      'Native, first-party connections only. Zapier does not count.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.vx;
    return ListView(
      padding: pagePadding,
      children: [
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            text: 'A tier is a recommendation, not a score. It answers one question: ',
            children: const [
              TextSpan(
                text: 'should someone in this field use this tool?',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          style: TextStyle(fontSize: 16, height: 1.5, color: c.text),
        ),
        const SizedBox(height: 18),
        VxGroup(
          children: [
            for (final t in Tier.values)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 108,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TierBadge(t),
                      ),
                    ),
                    Expanded(
                      child: Text(t.why, style: VxText.secondary(context)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        const Kicker('What we measure'),
        const SizedBox(height: 10),
        for (final (icon, k, body) in _measures)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: c.accentFg),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(k, style: VxText.title(context)),
                      const SizedBox(height: 2),
                      Text(body, style: VxText.secondary(context)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        VxCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Ph.info, size: 18, color: c.accentFg),
                  const SizedBox(width: 8),
                  Text('How Vertex makes money', style: VxText.title(context)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'We earn a commission when you subscribe to a tool through '
                'Vertex. Vendors see sales figures; they never see a draft '
                'tier, and they cannot buy one. Tools that pay us nothing are '
                'rated exactly the same way — several A-tiers do.',
                style: VxText.secondary(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Ratings published by the Vertex desk. Re-scored monthly; last full '
          'pass ${s.catalog.lastFullPass}. Disagree with a tier? Every report '
          'takes a challenge, and we publish the ones that change our mind.',
          style: VxText.muted(context, size: 12.5),
        ),
      ],
    );
  }
}
