import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../logic/ranking.dart';
import '../services/services.dart';

enum VxTab {
  home('Home'),
  fields('Fields'),
  compare('Compare'),
  saved('Saved'),
  you('You');

  const VxTab(this.label);
  final String label;
}

/// A screen pushed on top of the current tab.
sealed class VxPage {
  const VxPage();
}

class CategoryPage extends VxPage {
  const CategoryPage(this.fieldId);
  final String fieldId;
}

class DetailPage extends VxPage {
  const DetailPage(this.toolId);
  final String toolId;
}

class SearchPage extends VxPage {
  const SearchPage();
}

class MethodPage extends VxPage {
  const MethodPage();
}

const maxCompare = 3;

class AppState extends ChangeNotifier {
  AppState({
    required this.catalog,
    required this.storage,
    this.links = const SystemLinkOpener(),
    DateTime Function()? clock,
  }) : now = clock ?? DateTime.now,
       fieldId = catalog.fields.first.id;

  Catalog catalog;
  final Storage storage;
  final LinkOpener links;
  final DateTime Function() now;

  static Future<AppState> load({
    required Catalog catalog,
    required Storage storage,
    LinkOpener links = const SystemLinkOpener(),
    DateTime Function()? clock,
  }) async {
    final s = AppState(
      catalog: catalog,
      storage: storage,
      links: links,
      clock: clock,
    );
    try {
      final raw = await storage.read();
      if (raw != null) s._restore(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Unreadable saved state is not worth blocking launch over.
    }
    return s;
  }

  // ───────── persisted ─────────

  bool onboarded = false;
  String fieldId;
  Role? role;
  ThemeMode themeMode = ThemeMode.system;
  List<String> saved = [];
  List<String> compare = [];
  List<Review> reviews = [];

  // ───────── session ─────────

  /// Null while the app is in use; otherwise the onboarding step showing.
  int? introStep;
  VxTab tab = VxTab.home;
  List<VxPage> stack = [];
  String? sub;
  TierFilter tierFilter = TierFilter.any;
  PriceFilter priceFilter = PriceFilter.any;
  SortOrder sort = SortOrder.tier;
  final toast = ValueNotifier<String?>(null);
  Timer? _toastTimer;

  bool get inIntro => introStep != null || !onboarded;
  int get intro => introStep ?? 0;

  Field get field => catalog.field(fieldId) ?? catalog.fields.first;
  List<Tool> get ranked => rankField(catalog, field.id);
  VxPage? get top => stack.isEmpty ? null : stack.last;
  bool get filterActive =>
      tierFilter != TierFilter.any || priceFilter != PriceFilter.any;

  void _restore(Map<String, dynamic> j) {
    onboarded = j['onboarded'] as bool? ?? false;
    final f = j['fieldId'] as String?;
    if (f != null && catalog.field(f) != null) fieldId = f;
    final r = j['role'] as String?;
    role = Role.values.where((e) => e.name == r).firstOrNull;
    final t = j['themeMode'] as String?;
    themeMode =
        ThemeMode.values.where((e) => e.name == t).firstOrNull ??
        ThemeMode.system;
    List<String> ids(String k) => (j[k] as List? ?? const [])
        .map((e) => e as String)
        .where((id) => catalog.tool(id) != null)
        .toList();
    saved = ids('saved');
    compare = ids('compare').take(maxCompare).toList();
    reviews = (j['reviews'] as List? ?? const [])
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .where((r) => catalog.tool(r.toolId) != null)
        .toList();
  }

  Map<String, dynamic> toJson() => {
    'onboarded': onboarded,
    'fieldId': fieldId,
    'role': role?.name,
    'themeMode': themeMode.name,
    'saved': saved,
    'compare': compare,
    'reviews': reviews.map((r) => r.toJson()).toList(),
  };

  Future<void> _pending = Future.value();

  /// Resolves once every change so far has reached storage.
  Future<void> get flushed => _pending;

  void _commit() {
    notifyListeners();
    final snapshot = jsonEncode(toJson());
    _pending = _pending.then((_) => storage.write(snapshot)).catchError((_) {});
  }

  void flash(String message) {
    _toastTimer?.cancel();
    toast.value = message;
    _toastTimer = Timer(const Duration(milliseconds: 2400), () {
      toast.value = null;
    });
  }

  // ───────── onboarding ─────────

  void introNext() {
    introStep = 1;
    notifyListeners();
  }

  void introBack() {
    if (intro > 0) {
      introStep = intro - 1;
      notifyListeners();
    }
  }

  void introPickField(String id) {
    _setField(id);
    introStep = 2;
    _commit();
  }

  void finishIntro([Role? picked]) {
    if (picked != null) role = picked;
    onboarded = true;
    introStep = null;
    tab = VxTab.home;
    stack = [];
    _commit();
  }

  void replayIntro() {
    introStep = 0;
    tab = VxTab.home;
    stack = [];
    notifyListeners();
  }

  // ───────── navigation ─────────

  void setTab(VxTab t) {
    tab = t;
    stack = [];
    notifyListeners();
  }

  void push(VxPage page) {
    stack = [...stack, page];
    notifyListeners();
  }

  /// Returns false when there was nothing to pop.
  bool pop() {
    if (stack.isEmpty) {
      if (tab == VxTab.home) return false;
      tab = VxTab.home;
    } else {
      stack = stack.sublist(0, stack.length - 1);
    }
    notifyListeners();
    return true;
  }

  void openTool(String id) {
    if (catalog.tool(id) == null) return;
    push(DetailPage(id));
  }

  void openField(String id) {
    _setField(id);
    stack = [...stack, CategoryPage(id)];
    _commit();
  }

  void _setField(String id) {
    if (catalog.field(id) == null || id == fieldId) return;
    fieldId = id;
    sub = null;
    tierFilter = TierFilter.any;
    priceFilter = PriceFilter.any;
  }

  // ───────── preferences ─────────

  void setField(String id) {
    _setField(id);
    _commit();
  }

  void setRole(Role? r) {
    role = r;
    _commit();
  }

  void setThemeMode(ThemeMode m) {
    themeMode = m;
    _commit();
  }

  void setSub(String? s) {
    sub = s;
    notifyListeners();
  }

  void setTierFilter(TierFilter f) {
    tierFilter = f;
    notifyListeners();
  }

  void setPriceFilter(PriceFilter f) {
    priceFilter = f;
    notifyListeners();
  }

  void cycleSort() {
    sort = sort.next;
    notifyListeners();
  }

  void clearFilters() {
    tierFilter = TierFilter.any;
    priceFilter = PriceFilter.any;
    sub = null;
    notifyListeners();
  }

  // ───────── saved & compare ─────────

  bool isSaved(String id) => saved.contains(id);

  void toggleSaved(String id) {
    if (saved.contains(id)) {
      saved = saved.where((x) => x != id).toList();
      flash('Removed from saved');
    } else {
      saved = [...saved, id];
      flash('Saved · check back after the monthly re-score');
    }
    _commit();
  }

  bool inCompare(String id) => compare.contains(id);

  List<Tool> get compareTools =>
      compare.map(catalog.tool).whereType<Tool>().toList();

  /// Compare stays inside one field: a tier means nothing across fields.
  void toggleCompare(String id) {
    final tool = catalog.tool(id);
    if (tool == null) return;
    if (compare.contains(id)) {
      compare = compare.where((x) => x != id).toList();
      flash('Removed from compare');
    } else {
      final current = compareTools;
      if (current.isNotEmpty && current.first.fieldId != tool.fieldId) {
        compare = [id];
        flash('Compare switched to ${catalog.fieldOf(tool).name}');
      } else if (compare.length >= maxCompare) {
        flash('Compare holds three — remove one first');
        return;
      } else {
        compare = [...compare, id];
        flash('Added to compare');
      }
    }
    _commit();
  }

  // ───────── catalog ─────────

  /// Swaps in a newly published catalog, dropping anything that refers to a
  /// tool or field it no longer contains.
  void replaceCatalog(Catalog next) {
    catalog = next;
    if (next.field(fieldId) == null) {
      fieldId = next.fields.first.id;
      sub = null;
    }
    if (sub != null && !next.toolsIn(fieldId).any((t) => t.sub == sub)) {
      sub = null;
    }
    saved = saved.where((id) => next.tool(id) != null).toList();
    compare = compare.where((id) => next.tool(id) != null).toList();
    reviews = reviews.where((r) => next.tool(r.toolId) != null).toList();
    stack = stack
        .where(
          (p) => switch (p) {
            DetailPage(:final toolId) => next.tool(toolId) != null,
            CategoryPage(:final fieldId) => next.field(fieldId) != null,
            _ => true,
          },
        )
        .toList();
    _commit();
  }

  // ───────── vendor hand-off ─────────

  /// Opens the vendor's site through Vertex's partner link.
  Future<void> visitVendor(Tool tool) async {
    final ok = await links.open(tool.link);
    if (!ok) flash('Couldn’t open ${tool.domain}');
  }

  // ───────── reviews ─────────

  List<Review> reviewsFor(String toolId) =>
      reviews.where((r) => r.toolId == toolId).toList();

  void addReview(Review r) {
    reviews = [r, ...reviews];
    _commit();
  }

  void deleteReview(Review r) {
    reviews = reviews.where((x) => !identical(x, r)).toList();
    flash('Review withdrawn');
    _commit();
  }

  // ───────── reset ─────────

  Future<void> resetAll() async {
    onboarded = false;
    introStep = 0;
    fieldId = catalog.fields.first.id;
    role = null;
    themeMode = ThemeMode.system;
    saved = [];
    compare = [];
    reviews = [];
    tab = VxTab.home;
    stack = [];
    clearFilters();
    await _pending;
    await storage.clear();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    toast.dispose();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// For callbacks, where rebuilding on change is not wanted.
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
