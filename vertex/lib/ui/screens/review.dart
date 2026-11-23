import 'package:material_ui/material_ui.dart';

import '../../data/models.dart';
import '../../logic/format.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../sheets.dart';
import '../widgets/widgets.dart';

const minReviewLength = 20;

Future<void> showReviewSheet(BuildContext context, Tool tool) =>
    showVxSheet<void>(context, (_) => ReviewFlow(tool: tool));

class ReviewFlow extends StatefulWidget {
  const ReviewFlow({super.key, required this.tool});
  final Tool tool;

  @override
  State<ReviewFlow> createState() => _ReviewFlowState();
}

class _ReviewFlowState extends State<ReviewFlow> {
  final _useCase = TextEditingController();
  final _body = TextEditingController();
  ReviewVerdict? _verdict;
  bool _sent = false;

  @override
  void dispose() {
    _useCase.dispose();
    _body.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _verdict != null || _useCase.text.isNotEmpty || _body.text.isNotEmpty;
  int get _remaining => minReviewLength - _body.text.trim().length;
  bool get _valid => _verdict != null && _remaining <= 0;

  Future<void> _cancel() async {
    final nav = Navigator.of(context);
    if (_sent || !_dirty) return nav.pop();
    final discard = await confirmVx(
      context,
      title: 'Discard this review?',
      message: 'What you’ve written so far won’t be kept.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (discard) nav.pop();
  }

  void _send() {
    final s = AppScope.read(context);
    s.addReview(
      Review(
        toolId: widget.tool.id,
        verdict: _verdict!,
        useCase: _useCase.text.trim(),
        body: _body.text.trim(),
        createdAt: s.now(),
      ),
    );
    FocusScope.of(context).unfocus();
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tool;
    return PopScope(
      canPop: _sent || !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: SheetScaffold(
        title: 'Review ${t.name}',
        subtitle: 'Read by a person before it’s published',
        leadingLabel: _sent ? 'Done' : 'Cancel',
        onLeading: _cancel,
        body: AnimatedSwitcher(
          duration: vxMotion(context, 220),
          child: _sent ? _confirmation(context) : _form(context),
        ),
        footer: _sent
            ? VxButton(
                'Done',
                kind: VxButtonKind.primary,
                block: true,
                onTap: () => Navigator.pop(context),
              )
            : VxButton(
                'Send for review',
                kind: VxButtonKind.primary,
                block: true,
                onTap: _valid ? _send : null,
              ),
      ),
    );
  }

  Widget _form(BuildContext context) => ListView(
    key: const ValueKey('form'),
    padding: const EdgeInsets.all(20),
    children: [
      const Kicker('Your verdict'),
      const SizedBox(height: 8),
      Row(
        children: [
          for (final v in ReviewVerdict.values) ...[
            if (v != ReviewVerdict.values.first) const SizedBox(width: 8),
            Expanded(
              child: VxCard(
                selected: _verdict == v,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                onTap: () => setState(() => _verdict = v),
                child: Center(
                  child: Text(
                    v.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _verdict == v
                          ? context.vx.accentFg
                          : context.vx.text,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 22),
      const Kicker('What did you use it for?'),
      const SizedBox(height: 8),
      VxField(
        controller: _useCase,
        hint: 'e.g. Gearbox housing, capstone project',
        maxLength: 80,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 22),
      const Kicker('Your review'),
      const SizedBox(height: 8),
      VxField(
        controller: _body,
        hint: 'What worked, what didn’t, and who it’s for.',
        maxLines: 6,
        maxLength: 1200,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 6),
      Text(
        _verdict == null
            ? 'Pick a verdict to continue.'
            : _remaining > 0
            ? '$_remaining more ${_remaining == 1 ? 'character' : 'characters'} needed.'
            : 'Reviews never change a tier on their own — the desk weighs them '
                  'at the next re-score.',
        style: VxText.muted(context),
      ),
    ],
  );

  Widget _confirmation(BuildContext context) => ListView(
    key: const ValueKey('sent'),
    padding: const EdgeInsets.fromLTRB(22, 36, 22, 20),
    children: [
      const Align(
        alignment: Alignment.centerLeft,
        child: BadgeIcon(Ph.paperPlaneTilt),
      ),
      const SizedBox(height: 18),
      Text('Sent to the Vertex desk', style: VxText.display(context, size: 26)),
      const SizedBox(height: 8),
      Text(
        'A person on our team reads it first. It goes live once it’s approved '
        '— usually within a day.',
        style: VxText.secondary(context, size: 14),
      ),
      const SizedBox(height: 16),
      const Align(
        alignment: Alignment.centerLeft,
        child: VxTag('In review', icon: Ph.clock),
      ),
    ],
  );
}

/// One of the user's own reviews, as listed on a tool page and the You tab.
class ReviewRow extends StatelessWidget {
  const ReviewRow({super.key, required this.review, this.showTool = false});
  final Review review;
  final bool showTool;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.read(context);
    final tool = s.catalog.tool(review.toolId);
    final title = showTool && tool != null
        ? '${tool.name} · ${review.verdict.label}'
        : review.verdict.label;
    return VxRow(
      title: title,
      subtitle: '“${review.body.replaceAll(RegExp(r'\s+'), ' ')}”',
      subtitleMaxLines: 1,
      trailing: const VxTag('In review'),
      onTap: () => showVxBottomSheet<void>(
        context,
        (ctx) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${tool?.name ?? 'Review'} · ${review.verdict.label}',
                    style: VxText.display(ctx, size: 21),
                  ),
                ),
                const VxTag('In review', icon: Ph.clock),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                'Sent ${fmtDate(review.createdAt)}',
                if (review.useCase.isNotEmpty) review.useCase,
              ].join(' · '),
              style: VxText.muted(ctx),
            ),
            const SizedBox(height: 14),
            Text(review.body, style: VxText.body(ctx)),
            const SizedBox(height: 20),
            VxButton(
              'Withdraw review',
              kind: VxButtonKind.danger,
              block: true,
              onTap: () {
                Navigator.pop(ctx);
                s.deleteReview(review);
              },
            ),
            const SizedBox(height: 8),
            VxButton(
              'Close',
              kind: VxButtonKind.ghost,
              block: true,
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
