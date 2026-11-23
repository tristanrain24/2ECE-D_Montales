import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'screens/browse.dart';
import 'screens/detail.dart';
import 'screens/you.dart';
import 'widgets/widgets.dart';

const _wideBreakpoint = 860.0;
const _contentMaxWidth = 760.0;

/// What a screen contributes to the shell around it.
class ScreenSpec {
  const ScreenSpec({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.actions = const [],
    this.footer,
  });
  final String key;
  final String title;
  final String subtitle;
  final Widget body;
  final List<Widget> actions;
  final Widget? footer;
}

ScreenSpec _specFor(BuildContext context, AppState s) {
  final cat = s.catalog;
  final searchBtn = VxIconButton(
    Ph.magnifyingGlass,
    label: 'Search',
    onTap: () => s.push(const SearchPage()),
  );
  switch (s.top) {
    case CategoryPage(:final fieldId):
      final f = cat.field(fieldId) ?? s.field;
      return ScreenSpec(
        key: 'category:${f.id}',
        title: f.name,
        subtitle: f.subs,
        actions: [searchBtn],
        body: CategoryScreen(field: f),
      );
    case DetailPage(:final toolId):
      final Tool t = cat.tool(toolId)!;
      return ScreenSpec(
        key: 'detail:${t.id}:${s.stack.length}',
        title: t.name,
        subtitle: t.domain,
        actions: [
          VxIconButton(
            s.isSaved(t.id) ? PhFill.bookmarkSimple : Ph.bookmarkSimple,
            label: s.isSaved(t.id) ? 'Remove from saved' : 'Save',
            color: s.isSaved(t.id) ? context.vx.accentFg : null,
            onTap: () => s.toggleSaved(t.id),
          ),
        ],
        body: DetailScreen(tool: t),
        footer: DetailFooter(tool: t),
      );
    case SearchPage():
      return const ScreenSpec(
        key: 'search',
        title: 'Search',
        subtitle: 'Task, field or name',
        body: SearchScreen(),
      );
    case MethodPage():
      return const ScreenSpec(
        key: 'method',
        title: 'How we rate',
        subtitle: 'Tiers, metrics and money',
        body: MethodScreen(),
      );
    case null:
  }
  return switch (s.tab) {
    VxTab.home => ScreenSpec(
      key: 'home',
      title: 'Vertex',
      subtitle: 'The specialist index',
      actions: [searchBtn],
      body: const HomeScreen(),
    ),
    VxTab.fields => ScreenSpec(
      key: 'fields',
      title: 'Fields',
      subtitle: '${cat.fields.length} fields · ${cat.tools.length} tools rated',
      actions: [searchBtn],
      body: const FieldsScreen(),
    ),
    VxTab.compare => const ScreenSpec(
      key: 'compare',
      title: 'Head to head',
      subtitle: 'Up to three, ranked in field',
      body: CompareScreen(),
    ),
    VxTab.saved => ScreenSpec(
      key: 'saved',
      title: 'Saved',
      subtitle: '${s.saved.length} on watch',
      body: const SavedScreen(),
    ),
    VxTab.you => ScreenSpec(
      key: 'you',
      title: 'You',
      subtitle: s.role?.label ?? 'Reviews and settings',
      body: const YouScreen(),
    ),
  };
}

(IconData, IconData) _tabIcons(VxTab t) => switch (t) {
  VxTab.home => (Ph.house, PhFill.house),
  VxTab.fields => (Ph.squaresFour, PhFill.squaresFour),
  VxTab.compare => (Ph.columns, PhFill.columns),
  VxTab.saved => (Ph.bookmarkSimple, PhFill.bookmarkSimple),
  VxTab.you => (Ph.userCircle, PhFill.userCircle),
};

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    final spec = _specFor(context, s);
    final atRoot = s.stack.isEmpty && s.tab == VxTab.home;

    final content = Column(
      children: [
        _Header(spec: spec, canBack: s.stack.isNotEmpty, showMark: !wide),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.012),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            layoutBuilder: (current, previous) => current ?? const SizedBox(),
            child: KeyedSubtree(
              key: ValueKey(spec.key),
              child: _Centered(child: spec.body),
            ),
          ),
        ),
        if (spec.footer != null)
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.vx.bg,
              border: Border(top: BorderSide(color: context.vx.divider)),
            ),
            child: _Centered(child: spec.footer!),
          ),
      ],
    );

    final showTabs = !wide && s.top is! SearchPage;
    final body = wide
        ? Row(
            children: [
              const _SideRail(),
              VerticalDivider(width: 1, color: context.vx.divider),
              Expanded(child: content),
            ],
          )
        : Column(
            children: [
              Expanded(child: content),
              if (showTabs) const _TabBar(),
            ],
          );

    return PopScope(
      canPop: atRoot,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) s.pop();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (s.stack.isNotEmpty) s.pop();
          },
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
              _openSearch(s),
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
              _openSearch(s),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(child: body),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: showTabs ? 78 : 18,
                    child: _Toast(listenable: s.toast),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _openSearch(AppState s) {
    if (s.top is! SearchPage) s.push(const SearchPage());
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
      child: child,
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.spec,
    required this.canBack,
    required this.showMark,
  });
  final ScreenSpec spec;
  final bool canBack;
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.read(context);
    return _Centered(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
        child: Row(
          children: [
            if (canBack)
              VxIconButton(Ph.caretLeft, label: 'Back', onTap: s.pop)
            else if (showMark)
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: VertexMark(size: 28),
              )
            else
              const SizedBox(width: 10, height: 44),
            Expanded(
              child: Semantics(
                header: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VxText.title(context, size: 17),
                    ),
                    Text(
                      spec.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VxText.muted(context, size: 11.5),
                    ),
                  ],
                ),
              ),
            ),
            ...spec.actions,
          ],
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.vx;
    return Material(
      color: c.bg,
      shape: Border(top: BorderSide(color: c.divider)),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: [
          for (final t in VxTab.values)
            Expanded(
              child: Builder(
                builder: (context) {
                  final on = s.stack.isEmpty && s.tab == t;
                  final (off, fill) = _tabIcons(t);
                  final fg = on ? c.accentFg : c.textMuted;
                  return Semantics(
                    button: true,
                    selected: on,
                    label: t.label,
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => s.setTab(t),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 9, bottom: 7),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(on ? fill : off, size: 22, color: fg),
                            const SizedBox(height: 3),
                            Text(
                              t.label,
                              style: TextStyle(
                                fontSize: 10.5,
                                height: 1.2,
                                color: fg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.vx;
    return SizedBox(
      width: 216,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 22),
              child: Row(
                children: [
                  const VertexMark(size: 30),
                  const SizedBox(width: 10),
                  Text('Vertex', style: VxText.title(context, size: 18)),
                ],
              ),
            ),
            for (final t in VxTab.values)
              Builder(
                builder: (context) {
                  final on = s.stack.isEmpty && s.tab == t;
                  final (off, fill) = _tabIcons(t);
                  final fg = on ? c.accentFg : c.textSecondary;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Semantics(
                      button: true,
                      selected: on,
                      child: Material(
                        color: on ? c.accentSoft : Colors.transparent,
                        borderRadius: BorderRadius.circular(vxRadius),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => s.setTab(t),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            child: Row(
                              children: [
                                Icon(on ? fill : off, size: 20, color: fg),
                                const SizedBox(width: 12),
                                Text(
                                  t.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: on
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                    color: fg,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${s.catalog.tools.length} tools · ${s.catalog.fields.length} fields\nRe-scored monthly',
                style: VxText.muted(context, size: 11.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.listenable});
  final ValueNotifier<String?> listenable;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ValueListenableBuilder<String?>(
      valueListenable: listenable,
      builder: (context, msg, _) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: msg == null
            ? const SizedBox.shrink()
            : Center(
                key: ValueKey(msg),
                child: Semantics(
                  liveRegion: true,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: context.vx.inverseBg,
                      borderRadius: BorderRadius.circular(vxRadius),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Ph.checkCircle,
                          size: 16,
                          color: context.vx.inverseFg,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            msg,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: context.vx.inverseFg,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    ),
  );
}
