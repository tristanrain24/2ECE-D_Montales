import 'package:material_ui/material_ui.dart';

import '../theme/tokens.dart';
import 'widgets/widgets.dart';

/// Presents a task flow: full screen on phones, a centred panel on wide
/// windows.
Future<T?> showVxSheet<T>(BuildContext context, WidgetBuilder builder) {
  final scrim = context.vx.scrim;
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<T>(
      opaque: false,
      barrierColor: scrim,
      barrierDismissible: false,
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (ctx, _, _) => _SheetFrame(child: builder(ctx)),
      transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 640 && size.height >= 560;
    if (!wide) {
      return Material(
        color: context.vx.bg,
        child: SafeArea(child: child),
      );
    }
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 780),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Material(
              color: context.vx.bg,
              elevation: 12,
              shadowColor: Colors.black54,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: context.vx.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Header + scrolling body + pinned footer, used by every task flow.
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.leadingLabel,
    this.onLeading,
    this.footer,
  });
  final String title;
  final String subtitle;
  final Widget body;
  final String? leadingLabel;
  final VoidCallback? onLeading;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.vx;
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.divider)),
          ),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                child: leadingLabel == null
                    ? null
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: VxButton(
                          leadingLabel!,
                          kind: VxButtonKind.ghost,
                          dense: true,
                          onTap: onLeading,
                        ),
                      ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VxText.title(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VxText.muted(context, size: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 76),
            ],
          ),
        ),
        Expanded(child: body),
        if (footer != null)
          Container(
            decoration: BoxDecoration(
              color: c.bg,
              border: Border(top: BorderSide(color: c.divider)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: footer,
          ),
      ],
    );
  }
}

/// A bottom sheet for short choices (filters, pickers, confirmations).
Future<T?> showVxBottomSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: context.vx.bg,
    barrierColor: context.vx.scrim,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: builder(ctx),
        ),
      ),
    ),
  );
}

Future<bool> confirmVx(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final ok = await showVxBottomSheet<bool>(
    context,
    (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: VxText.display(ctx, size: 21)),
        const SizedBox(height: 8),
        Text(message, style: VxText.secondary(ctx, size: 14)),
        const SizedBox(height: 20),
        VxButton(
          confirmLabel,
          block: true,
          kind: destructive ? VxButtonKind.danger : VxButtonKind.primary,
          onTap: () => Navigator.pop(ctx, true),
        ),
        const SizedBox(height: 8),
        VxButton(
          'Keep it',
          block: true,
          kind: VxButtonKind.ghost,
          onTap: () => Navigator.pop(ctx, false),
        ),
      ],
    ),
  );
  return ok ?? false;
}
