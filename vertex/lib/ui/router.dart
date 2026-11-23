import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../services/services.dart';
import '../state/app_state.dart';

/// Every screen has an address, so the browser's Back and Forward buttons,
/// refresh and shared links all work on the web:
///
///   /            Home          /tool/ID      a tool report
///   /fields      Fields        /field/ID     one field's ranked list
///   /compare     Compare       /search       Search
///   /saved       Saved         /method       How we rate
///   /you         You           /welcome      the intro
String locationOf(AppState s) {
  if (s.inIntro) return '/welcome';
  return switch (s.top) {
    DetailPage(:final toolId) => '/tool/$toolId',
    CategoryPage(:final fieldId) => '/field/$fieldId',
    SearchPage() => '/search',
    MethodPage() => '/method',
    null => s.tab == VxTab.home ? '/' : '/${s.tab.name}',
  };
}

String _locationOfPage(VxPage p) => switch (p) {
  DetailPage(:final toolId) => '/tool/$toolId',
  CategoryPage(:final fieldId) => '/field/$fieldId',
  SearchPage() => '/search',
  MethodPage() => '/method',
};

/// Moves the app to [uri], keeping as much of the current back stack as
/// still makes sense.
void applyLocation(AppState s, Uri uri) {
  final parts = uri.pathSegments.where((p) => p.isNotEmpty).toList();
  if ('/${parts.join('/')}' == locationOf(s)) return;
  if (parts.isEmpty || parts.first == 'welcome') {
    if (!s.inIntro) s.setTab(VxTab.home);
    return;
  }
  final VxPage? page = switch (parts) {
    ['tool', final id] when s.catalog.tool(id) != null => DetailPage(id),
    ['field', final id] when s.catalog.field(id) != null => CategoryPage(id),
    ['search'] => const SearchPage(),
    ['method'] => const MethodPage(),
    _ => null,
  };
  if (page == null) {
    final tab = VxTab.values.where((t) => t.name == parts.first).firstOrNull;
    if (s.inIntro && tab == null) return;
    if (s.inIntro) s.finishIntro();
    s.setTab(tab ?? VxTab.home);
    return;
  }
  // A shared link skips the intro; it can be replayed from the You tab.
  if (s.inIntro) s.finishIntro();
  final target = _locationOfPage(page);
  final i = s.stack.lastIndexWhere((p) => _locationOfPage(p) == target);
  if (i >= 0) {
    s.popTo(i);
  } else if (page is CategoryPage) {
    s.openField(page.fieldId);
  } else {
    s.push(page);
  }
}

/// Link to a tool report in the web version of Vertex, or null when there
/// is no web version to link to.
Uri? shareLinkFor(String toolId, {bool web = kIsWeb, String site = webAppUrl}) {
  if (!web && site.isEmpty) return null;
  final base = web ? Uri.base.removeFragment() : Uri.parse(site);
  return base.replace(fragment: '/tool/$toolId');
}

class VxRouteParser extends RouteInformationParser<Uri> {
  const VxRouteParser();
  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) =>
      SynchronousFuture(routeInformation.uri);
  @override
  RouteInformation restoreRouteInformation(Uri configuration) =>
      RouteInformation(uri: configuration);
}

class VxRouterDelegate extends RouterDelegate<Uri>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri> {
  VxRouterDelegate({required this.state, required this.home}) {
    state.addListener(notifyListeners);
  }

  final AppState state;
  final Widget home;

  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Uri get currentConfiguration => Uri(path: locationOf(state));

  @override
  Future<void> setNewRoutePath(Uri configuration) {
    // The router can deliver a location mid-build; apply it after the frame.
    return Future(() => applyLocation(state, configuration));
  }

  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    pages: [MaterialPage(key: const ValueKey('vertex'), child: home)],
    onDidRemovePage: (_) {},
  );

  @override
  void dispose() {
    state.removeListener(notifyListeners);
    super.dispose();
  }
}
