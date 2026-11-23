import 'package:material_ui/material_ui.dart';

/// Nocturne design tokens, resolved for the light and dark app surfaces.
@immutable
class VxColors extends ThemeExtension<VxColors> {
  const VxColors({
    required this.bg,
    required this.surface,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.border,
    required this.borderStrong,
    required this.accent,
    required this.accentFg,
    required this.accentSoft,
    required this.accentSoftBorder,
    required this.neutralSoft,
    required this.neutralFg,
    required this.track,
    required this.inverseBg,
    required this.inverseFg,
    required this.danger,
    required this.scrim,
  });

  final Color bg;
  final Color surface;
  final Color text;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;
  final Color border;
  final Color borderStrong;
  final Color accent;
  final Color accentFg;
  final Color accentSoft;
  final Color accentSoftBorder;
  final Color neutralSoft;
  final Color neutralFg;
  final Color track;
  final Color inverseBg;
  final Color inverseFg;
  final Color danger;
  final Color scrim;

  static const light = VxColors(
    bg: Color(0xFFE4E7F5),
    surface: Color(0xFFF3F5FE),
    text: Color(0xFF292B31),
    textSecondary: Color(0xFF4E5262),
    textMuted: Color(0xFF5C6071),
    divider: Color(0xFFCFD3E5),
    border: Color(0xFFCFD3E5),
    borderStrong: Color(0xFFB2B6CA),
    accent: Color(0xFF9184D9),
    accentFg: Color(0xFF5D5294),
    accentSoft: Color(0xFFE7E5FE),
    accentSoftBorder: Color(0xFFD2CEFD),
    neutralSoft: Color(0xFFD9DDEE),
    neutralFg: Color(0xFF3F424D),
    track: Color(0xFFCFD3E5),
    inverseBg: Color(0xFF292B31),
    inverseFg: Color(0xFFF3F5FE),
    danger: Color(0xFFA83A47),
    scrim: Color(0x66292B31),
  );

  static const dark = VxColors(
    bg: Color(0xFF161826),
    surface: Color(0xFF232532),
    text: Color(0xFFE9E9ED),
    textSecondary: Color(0xFFB2B6CA),
    textMuted: Color(0xFF9397AB),
    divider: Color(0x29E9E9ED),
    border: Color(0xFF3F424D),
    borderStrong: Color(0xFF595D6C),
    accent: Color(0xFF9184D9),
    accentFg: Color(0xFFD2CEFD),
    accentSoft: Color(0xFF2B2741),
    accentSoftBorder: Color(0xFF423A6A),
    neutralSoft: Color(0xFF30323F),
    neutralFg: Color(0xFFE4E7F5),
    track: Color(0xFF3F424D),
    inverseBg: Color(0xFFF3F5FE),
    inverseFg: Color(0xFF292B31),
    danger: Color(0xFFEE98A1),
    scrim: Color(0x99000000),
  );

  @override
  VxColors copyWith() => this;

  @override
  VxColors lerp(ThemeExtension<VxColors>? other, double t) {
    if (other is! VxColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return VxColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      text: l(text, other.text),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      divider: l(divider, other.divider),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      accent: l(accent, other.accent),
      accentFg: l(accentFg, other.accentFg),
      accentSoft: l(accentSoft, other.accentSoft),
      accentSoftBorder: l(accentSoftBorder, other.accentSoftBorder),
      neutralSoft: l(neutralSoft, other.neutralSoft),
      neutralFg: l(neutralFg, other.neutralFg),
      track: l(track, other.track),
      inverseBg: l(inverseBg, other.inverseBg),
      inverseFg: l(inverseFg, other.inverseFg),
      danger: l(danger, other.danger),
      scrim: l(scrim, other.scrim),
    );
  }
}

extension VxTheme on BuildContext {
  VxColors get vx => Theme.of(this).extension<VxColors>()!;
}

const vxRadius = 8.0;
const vxRadiusSm = 6.0;
const vxFont = 'Inter';

ThemeData buildVxTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? VxColors.dark : VxColors.light;
  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    fontFamily: vxFont,
    scaffoldBackgroundColor: c.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
    ).copyWith(primary: c.accentFg, surface: c.bg, onSurface: c.text),
    splashFactory: InkSparkle.splashFactory,
    // Visible keyboard focus and hover on every control.
    focusColor: c.accent.withValues(alpha: 0.28),
    hoverColor: c.accent.withValues(alpha: 0.08),
    extensions: [c],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: c.text,
      displayColor: c.text,
      fontFamily: vxFont,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accentFg,
      selectionColor: c.accent.withValues(alpha: 0.3),
      selectionHandleColor: c.accent,
    ),
    dividerColor: c.divider,
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.bg,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.bg,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

/// Text styles used across the app. Sizes follow the prototype.
class VxText {
  static TextStyle body(BuildContext c) =>
      TextStyle(fontSize: 15, height: 1.55, color: c.vx.text);
  static TextStyle secondary(BuildContext c, {double size = 13}) =>
      TextStyle(fontSize: size, height: 1.5, color: c.vx.textSecondary);
  static TextStyle muted(BuildContext c, {double size = 12}) =>
      TextStyle(fontSize: size, height: 1.4, color: c.vx.textMuted);
  static TextStyle title(BuildContext c, {double size = 15}) => TextStyle(
    fontSize: size,
    height: 1.25,
    fontWeight: FontWeight.w500,
    color: c.vx.text,
  );
  static TextStyle display(BuildContext c, {double size = 28}) => TextStyle(
    fontSize: size,
    height: 1.12,
    fontWeight: FontWeight.w500,
    letterSpacing: -size * 0.022,
    color: c.vx.text,
  );
}

/// Base text is set about 7% above the design's sizes (15px body becomes
/// 16px), on top of whatever text size the person has chosen.
class VxTextScaler extends TextScaler {
  const VxTextScaler(this.base, [this.boost = 1.07]);
  final TextScaler base;
  final double boost;

  @override
  double scale(double fontSize) => base.scale(fontSize) * boost;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * boost;

  @override
  bool operator ==(Object other) =>
      other is VxTextScaler && other.base == base && other.boost == boost;

  @override
  int get hashCode => Object.hash(base, boost);
}

/// Animation length, or none when the person has asked for reduced motion.
Duration vxMotion(BuildContext context, int milliseconds) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false
    ? Duration.zero
    : Duration(milliseconds: milliseconds);
