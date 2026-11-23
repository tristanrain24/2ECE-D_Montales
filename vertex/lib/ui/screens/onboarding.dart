import 'package:material_ui/material_ui.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../widgets/widgets.dart';

class Onboarding extends StatelessWidget {
  const Onboarding({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final step = s.intro;
    return PopScope(
      canPop: step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) s.introBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: AnimatedSwitcher(
                duration: vxMotion(context, 260),
                child: KeyedSubtree(
                  key: ValueKey(step),
                  child: switch (step) {
                    0 => _Welcome(s),
                    1 => _FieldStep(s),
                    _ => _RoleStep(s),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome(this.s);
  final AppState s;

  @override
  Widget build(BuildContext context) {
    final c = context.vx;
    Widget stat(String a, String b) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(a, style: VxText.title(context, size: 22)),
        const SizedBox(height: 2),
        Kicker(b, muted: true),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const VertexMark(size: 30),
              const SizedBox(width: 10),
              Text('Vertex', style: VxText.title(context, size: 17)),
            ],
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Kicker('Welcome'),
                    const SizedBox(height: 14),
                    Text(
                      'One rated pick per field. Nothing else.',
                      style: VxText.display(context, size: 34),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Most lists rank every AI against every other AI, so the '
                      'tool built for your discipline ends up buried under a '
                      'general chatbot. We only ever rank a tool against the '
                      'others in its own field — then tell you plainly which '
                      'one to take.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _RankShift(),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 22,
                      runSpacing: 12,
                      children: [
                        stat('${s.catalog.tools.length}', 'Tools rated'),
                        stat('${s.catalog.fields.length}', 'Fields'),
                        stat('Monthly', 'Re-scored'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          VxButton(
            'Set me up — 20 seconds',
            kind: VxButtonKind.primary,
            block: true,
            trailing: Ph.arrowRight,
            onTap: s.introNext,
          ),
          const SizedBox(height: 6),
          VxButton(
            'Skip — let me just browse',
            kind: VxButtonKind.ghost,
            block: true,
            onTap: s.finishIntro,
          ),
        ],
      ),
    );
  }
}

class _StepHead extends StatelessWidget {
  const _StepHead({
    required this.s,
    required this.step,
    required this.title,
    required this.body,
  });
  final AppState s;
  final int step;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.vx;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Transform.translate(
              offset: const Offset(-12, 0),
              child: VxIconButton(
                Ph.caretLeft,
                label: 'Back',
                onTap: s.introBack,
              ),
            ),
            for (var i = 1; i <= 2; i++)
              Container(
                width: 26,
                height: 2,
                margin: const EdgeInsets.only(right: 6),
                color: i <= step ? c.accent : c.borderStrong,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Kicker('Step $step of 2'),
        const SizedBox(height: 8),
        Text(title, style: VxText.display(context, size: 28)),
        const SizedBox(height: 8),
        Text(body, style: VxText.secondary(context, size: 14)),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _FieldStep extends StatelessWidget {
  const _FieldStep(this.s);
  final AppState s;

  @override
  Widget build(BuildContext context) {
    final c = context.vx;
    return LayoutBuilder(
      builder: (context, box) {
        final inner = box.maxWidth - 44;
        final cols = inner < 300 ? 2 : 3;
        const gap = 10.0;
        final w = (inner - gap * (cols - 1)) / cols;
        return ListView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
          children: [
            _StepHead(
              s: s,
              step: 1,
              title: 'What are you working in?',
              body:
                  'This is the whole trick — everything you see gets ranked '
                  'inside the field you pick.',
            ),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final f in s.catalog.fields)
                  SizedBox(
                    width: w,
                    child: VxCard(
                      selected: s.onboarded && f.id == s.field.id,
                      padding: const EdgeInsets.all(12),
                      onTap: () => s.introPickField(f.id),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 84),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              fieldIcon(f.icon),
                              size: 22,
                              color: c.textSecondary,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              f.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: VxText.title(context, size: 13.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              f.subs,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: VxText.muted(context, size: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            VxButton(
              'Skip this',
              kind: VxButtonKind.ghost,
              block: true,
              onTap: s.finishIntro,
            ),
          ],
        );
      },
    );
  }
}

class _RoleStep extends StatelessWidget {
  const _RoleStep(this.s);
  final AppState s;

  @override
  Widget build(BuildContext context) {
    final c = context.vx;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
      children: [
        _StepHead(
          s: s,
          step: 2,
          title: 'And who’s asking?',
          body:
              'This changes which price we lead with. It never changes a tier.',
        ),
        for (final r in Role.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: VxCard(
              selected: s.role == r,
              padding: EdgeInsets.zero,
              onTap: () => s.finishIntro(r),
              child: VxRow(
                leading: Icon(
                  roleIcon(r),
                  size: 22,
                  color: s.role == r ? c.accentFg : c.textSecondary,
                ),
                title: r.label,
                subtitle: r.note,
                chevron: true,
              ),
            ),
          ),
        const SizedBox(height: 4),
        VxButton(
          'Skip this',
          kind: VxButtonKind.ghost,
          block: true,
          onTap: s.finishIntro,
        ),
      ],
    );
  }
}

/// The idea in one picture: the same tool, buried in an all-AI list and
/// first in its own field.
class _RankShift extends StatelessWidget {
  const _RankShift();

  @override
  Widget build(BuildContext context) {
    final c = context.vx;
    Widget row({
      required String rank,
      required String where,
      required bool ours,
    }) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 46),
            child: Text(
              rank,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: ours ? c.accentFg : c.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A CAD copilot',
                  style: VxText.title(context)
                      .copyWith(color: ours ? c.text : c.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(where, style: VxText.muted(context)),
              ],
            ),
          ),
          if (ours) const TierBadge(Tier.a, word: false),
        ],
      ),
    );
    return Semantics(
      label:
          'Example: a CAD copilot ranks 14th in a list of every AI tool, '
          'and first when ranked only against engineering tools.',
      excludeSemantics: true,
      child: VxCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            row(
              rank: '#14',
              where: 'Ranked against every AI tool',
              ours: false,
            ),
            Divider(height: 1, color: c.divider),
            row(
              rank: '#1',
              where: 'Ranked on Vertex, in Engineering',
              ours: true,
            ),
          ],
        ),
      ),
    );
  }
}
