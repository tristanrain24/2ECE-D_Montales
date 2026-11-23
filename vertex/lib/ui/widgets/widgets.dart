import 'package:material_ui/material_ui.dart';

import '../../data/models.dart';
import '../../theme/tokens.dart';
import 'ph_icons.dart';

export 'ph_icons.dart';

IconData fieldIcon(String name) => switch (name) {
  'gear-six' => Ph.gearSix,
  'heartbeat' => Ph.heartbeat,
  'flask' => Ph.flask,
  'scales' => Ph.scales,
  'chart-line-up' => Ph.chartLineUp,
  'megaphone' => Ph.megaphone,
  'handshake' => Ph.handshake,
  'code' => Ph.code,
  'users-three' => Ph.usersThree,
  _ => Ph.squaresFour,
};

IconData roleIcon(Role r) => switch (r) {
  Role.student => Ph.student,
  Role.pro => Ph.briefcase,
  Role.team => Ph.buildings,
};

/// The Vertex logo mark.
class VertexMark extends StatelessWidget {
  const VertexMark({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _MarkPainter()),
  );
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(22.5 * s)),
      Paint()..color = const Color(0xFF2B2741),
    );
    canvas.drawLine(
      Offset(20 * s, 47 * s),
      Offset(80 * s, 47 * s),
      Paint()
        ..color = const Color(0xFF796CBF)
        ..strokeWidth = 4 * s
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(29 * s, 29 * s)
        ..lineTo(50 * s, 71 * s)
        ..lineTo(71 * s, 29 * s),
      Paint()
        ..color = const Color(0xFFD2CEFD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key, this.muted = false});
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 10.5,
      height: 1.3,
      letterSpacing: 1.3,
      fontWeight: FontWeight.w500,
      color: muted ? context.vx.textMuted : context.vx.accentFg,
    ),
  );
}

class TierBadge extends StatelessWidget {
  const TierBadge(this.tier, {super.key, this.big = false, this.word = true});
  final Tier tier;
  final bool big;
  final bool word;

  @override
  Widget build(BuildContext context) {
    final c = context.vx;
    final (border, bg, fg) = switch (tier) {
      Tier.a => (c.accent, c.accentSoft, c.accentFg),
      Tier.b => (c.borderStrong, c.neutralSoft, c.neutralFg),
      Tier.c => (c.border, Colors.transparent, c.textMuted),
    };
    final size = big ? 12.5 : 11.5;
    return Semantics(
      label: 'Tier ${tier.label}, ${tier.word}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: big ? 10 : 8,
          vertical: big ? 5 : 3,
        ),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(vxRadiusSm),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: tier.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (word) TextSpan(text: '  ${tier.word}'),
            ],
          ),
          style: TextStyle(
            fontSize: size,
            height: 1.2,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
            color: fg,
          ),
        ),
      ),
    );
  }
}

enum VxButtonKind { primary, secondary, ghost, solid, danger }

class VxButton extends StatelessWidget {
  const VxButton(
    this.label, {
    super.key,
    required this.onTap,
    this.kind = VxButtonKind.secondary,
    this.icon,
    this.trailing,
    this.block = false,
    this.busy = false,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onTap;
  final VxButtonKind kind;
  final IconData? icon;
  final IconData? trailing;
  final bool block;
  final bool busy;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.vx;
    final enabled = onTap != null && !busy;
    final (fg, bg, border) = switch (kind) {
      VxButtonKind.primary => (c.accentFg, c.accentSoft, c.accent),
      VxButtonKind.secondary => (c.neutralFg, Colors.transparent, c.border),
      VxButtonKind.ghost => (
        c.accentFg,
        Colors.transparent,
        Colors.transparent,
      ),
      VxButtonKind.solid => (c.inverseFg, c.inverseBg, c.inverseBg),
      VxButtonKind.danger => (c.danger, Colors.transparent, c.border),
    };
    final height = dense ? 36.0 : (block ? 50.0 : 44.0);
    final child = Row(
      mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 1.6, color: fg),
            ),
          )
        else if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(icon, size: 17, color: fg),
          ),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: dense ? 13 : (block ? 15 : 14),
              fontWeight: FontWeight.w500,
              color: fg,
              height: 1.2,
            ),
          ),
        ),
        if (trailing != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(trailing, size: 16, color: fg),
          ),
      ],
    );
    return Opacity(
      opacity: enabled || busy ? 1 : 0.45,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(vxRadius),
          side: BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Container(
            constraints: BoxConstraints(minHeight: height, minWidth: 44),
            padding: EdgeInsets.symmetric(
              horizontal: kind == VxButtonKind.ghost ? 8 : (dense ? 12 : 16),
            ),
            alignment: block ? Alignment.center : null,
            child: block ? child : Center(widthFactor: 1, child: child),
          ),
        ),
      ),
    );
  }
}

class VxIconButton extends StatelessWidget {
  const VxIconButton(
    this.icon, {
    super.key,
    required this.onTap,
    required this.label,
    this.color,
    this.size = 20,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final String label;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox.square(
          dimension: 44,
          child: Icon(
            icon,
            size: size,
            color: color ?? context.vx.textSecondary,
          ),
        ),
      ),
    ),
  );
}

class VxCard extends StatelessWidget {
  const VxCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.selected = false,
    this.gradient,
    this.borderColor,
    this.semanticLabel,
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool selected;
  final Gradient? gradient;
  final Color? borderColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.vx;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(vxRadius),
      side: BorderSide(color: borderColor ?? (selected ? c.accent : c.border)),
    );
    Widget body = Padding(padding: padding, child: child);
    if (onTap != null) body = InkWell(onTap: onTap, child: body);
    final card = Ink(
      decoration: ShapeDecoration(
        shape: shape,
        color: gradient == null ? (selected ? c.accentSoft : c.surface) : null,
        gradient: gradient,
      ),
      child: body,
    );
    return Semantics(
      button: onTap != null,
      selected: selected ? true : null,
      label: semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: card,
      ),
    );
  }
}

enum VxTagKind { accent, neutral, outline }

class VxTag extends StatelessWidget {
  const VxTag(this.text, {super.key, this.kind = VxTagKind.neutral, this.icon});
  final String text;
  final VxTagKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.vx;
    final (fg, bg, border) = switch (kind) {
      VxTagKind.accent => (c.accentFg, c.accentSoft, Colors.transparent),
      VxTagKind.neutral => (c.neutralFg, c.neutralSoft, Colors.transparent),
      VxTagKind.outline => (c.accentFg, Colors.transparent, c.accent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(vxRadiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.25,
                letterSpacing: 0.2,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A filter chip: outlined when off, accent-filled when on.
class VxChip extends StatelessWidget {
  const VxChip(
    this.label, {
    super.key,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: VxButton(
      label,
      onTap: onTap,
      icon: icon,
      dense: true,
      kind: selected ? VxButtonKind.primary : VxButtonKind.secondary,
    ),
  );
}

class VxSegmented<T> extends StatelessWidget {
  const VxSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });
  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.vx;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(vxRadius),
      ),
      child: Row(
        children: [
          for (final e in options.entries)
            Expanded(
              child: Semantics(
                button: true,
                selected: e.key == value,
                child: Material(
                  color: e.key == value ? c.accentSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(vxRadiusSm),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onChanged(e.key),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 36),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        e.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: e.key == value
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: e.key == value ? c.accentFg : c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A row inside a grouped card: title, optional subtitle, trailing widget.
class VxRow extends StatelessWidget {
  const VxRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.chevron = false,
    this.subtitleMaxLines = 3,
  });
  final String title;
  final String? subtitle;
  final int subtitleMaxLines;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: VxText.title(context)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        maxLines: subtitleMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: VxText.muted(context),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            if (chevron) ...[
              const SizedBox(width: 6),
              Icon(Ph.caretRight, size: 15, color: context.vx.textMuted),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

/// A card that stacks rows with hairline dividers between them.
class VxGroup extends StatelessWidget {
  const VxGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => VxCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            Divider(height: 1, thickness: 1, color: context.vx.divider),
          children[i],
        ],
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 12),
    child: Column(
      children: [
        Icon(icon, size: 30, color: context.vx.textMuted),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: VxText.secondary(context, size: 14),
        ),
        if (action != null) ...[const SizedBox(height: 18), action!],
      ],
    ),
  );
}

/// A benchmark bar with a tick marking the field median.
class MetricBar extends StatelessWidget {
  const MetricBar({
    super.key,
    required this.value,
    required this.median,
    this.strong = false,
  });
  final int value;
  final int median;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = context.vx;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: vxMotion(context, 700),
      curve: Curves.easeOutCubic,
      builder: (context, k, _) => SizedBox(
        height: 18,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 5,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.track,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 5,
                  height: 8,
                  width: w * value / 100 * k,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: strong
                          ? c.accent
                          : c.accentFg.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Positioned(
                  left: (w * median / 100 - 1).clamp(0, w - 2),
                  top: 0,
                  width: 2,
                  height: 18,
                  child: ColoredBox(color: c.neutralFg),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Labelled text input in the Nocturne style.
class VxField extends StatelessWidget {
  const VxField({
    super.key,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
    this.error,
    this.maxLength,
    this.autofillHints,
    this.textInputAction,
    this.prefix,
    this.suffix,
    this.focusNode,
  });
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool enabled;
  final String? error;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final Widget? prefix;
  final Widget? suffix;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.vx;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(vxRadius),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      enabled: enabled,
      maxLength: maxLength,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      autocorrect: keyboardType != TextInputType.emailAddress,
      style: TextStyle(fontSize: 15, height: 1.45, color: c.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textMuted, fontSize: 15),
        errorText: error,
        errorStyle: TextStyle(color: c.danger, fontSize: 12),
        errorMaxLines: 3,
        counterText: '',
        filled: true,
        fillColor: c.surface,
        isDense: true,
        prefixIcon: prefix,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: border(c.border),
        enabledBorder: border(c.border),
        disabledBorder: border(c.border),
        focusedBorder: border(c.accent),
        errorBorder: border(c.danger),
        focusedErrorBorder: border(c.danger),
      ),
    );
  }
}

/// An inline notice, e.g. the demo-mode disclosure.
class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.vx.neutralSoft,
      borderRadius: BorderRadius.circular(vxRadius),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon ?? Ph.info, size: 15, color: context.vx.neutralFg),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: context.vx.neutralFg,
            ),
          ),
        ),
      ],
    ),
  );
}

/// A circular badge used on confirmation screens.
class BadgeIcon extends StatelessWidget {
  const BadgeIcon(this.icon, {super.key});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: context.vx.accentSoft,
      border: Border.all(color: context.vx.accent),
    ),
    child: Icon(icon, size: 25, color: context.vx.accentFg),
  );
}
