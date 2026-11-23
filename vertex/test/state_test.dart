import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:vertex/data/models.dart';
import 'package:vertex/services/services.dart';
import 'package:vertex/state/app_state.dart';
import 'package:vertex/ui/router.dart';

import 'logic_test.dart' show loadCatalog;

class FakeLinks implements LinkOpener {
  FakeLinks({this.ok = true});
  final bool ok;
  final opened = <Uri>[];
  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return ok;
  }
}

Future<AppState> newState(Storage storage, {LinkOpener? links}) =>
    AppState.load(
      catalog: loadCatalog(),
      storage: storage,
      links: links ?? FakeLinks(),
      clock: () => DateTime(2026, 11, 16),
    );

/// The bundled catalog with only [keep] tools left in it.
Catalog trimmed(List<String> keep) {
  final full = loadCatalog();
  final tools = full.tools.where((t) => keep.contains(t.id)).toList();
  return Catalog(
    fields: full.fields
        .where((f) => tools.any((t) => t.fieldId == f.id))
        .toList(),
    tools: tools,
    lastFullPass: 'Aug 2026',
  );
}

void main() {
  test('starts in onboarding and finishes into the chosen field', () async {
    final s = await newState(MemoryStorage());
    expect(s.inIntro, isTrue);
    s.introNext();
    s.introPickField('med');
    s.finishIntro(Role.student);
    expect(s.inIntro, isFalse);
    expect(s.field.name, 'Medicine');
    expect(s.ranked.first.id, 'cortexa');
    s.dispose();
  });

  test('persists and restores everything a user did', () async {
    final store = MemoryStorage();
    final s = await newState(store);
    s.finishIntro(Role.student);
    s.setField('eng');
    s.setThemeMode(ThemeMode.dark);
    s.toggleSaved('solidum');
    s.toggleCompare('solidum');
    s.toggleCompare('circuitry');
    s.addReview(
      Review(
        toolId: 'solidum',
        verdict: ReviewVerdict.take,
        useCase: 'Gearbox',
        body: 'Caught two interference errors.',
        createdAt: s.now(),
      ),
    );
    await s.flushed;
    s.dispose();

    final r = await newState(store);
    expect(r.inIntro, isFalse);
    expect(r.role, Role.student);
    expect(r.themeMode, ThemeMode.dark);
    expect(r.saved, ['solidum']);
    expect(r.compare, ['solidum', 'circuitry']);
    expect(r.reviewsFor('solidum').single.verdict, ReviewVerdict.take);
    r.dispose();
  });

  test('ignores corrupt or stale saved state', () async {
    final s = await newState(MemoryStorage('not json'));
    expect(s.inIntro, isTrue);
    s.dispose();
    final stale = MemoryStorage(
      jsonEncode({
        'onboarded': true,
        'fieldId': 'gone',
        'saved': ['solidum', 'deleted-tool'],
        'compare': ['a', 'b'],
        // Left over from versions with in-app checkout.
        'purchases': [
          {'toolId': 'solidum'},
        ],
        'student': {'email': 'a@mit.edu'},
      }),
    );
    final r = await newState(stale);
    expect(r.inIntro, isFalse);
    expect(r.field.id, 'eng');
    expect(r.saved, ['solidum']);
    expect(r.compare, isEmpty);
    r.dispose();
  });

  test('compare holds three and stays inside one field', () async {
    final s = await newState(MemoryStorage());
    for (final id in ['solidum', 'circuitry', 'femwise', 'struxlab']) {
      s.toggleCompare(id);
    }
    expect(s.compare, ['solidum', 'circuitry', 'femwise']);
    expect(s.toast.value?.message, contains('holds three'));
    s.toggleCompare('cortexa');
    expect(s.compare, ['cortexa']);
    s.toggleCompare('cortexa');
    expect(s.compare, isEmpty);
    s.dispose();
  });

  test('navigation stack and back behaviour', () async {
    final s = await newState(MemoryStorage());
    s.finishIntro();
    expect(s.pop(), isFalse);
    s.setTab(VxTab.fields);
    s.openField('law');
    s.openTool('precedent');
    expect(s.top, isA<DetailPage>());
    expect(s.field.id, 'law');
    expect(s.pop(), isTrue);
    expect(s.top, isA<CategoryPage>());
    expect(s.pop(), isTrue);
    expect(s.tab, VxTab.fields);
    expect(s.pop(), isTrue);
    expect(s.tab, VxTab.home);
    s.openTool('does-not-exist');
    expect(s.stack, isEmpty);
    s.dispose();
  });

  test('a newly published catalog replaces the old one cleanly', () async {
    final store = MemoryStorage();
    final s = await newState(store);
    s.finishIntro();
    s.setField('law');
    s.toggleSaved('precedent');
    s.toggleSaved('solidum');
    s.toggleCompare('solidum');
    s.openField('law');
    s.openTool('precedent');
    s.replaceCatalog(trimmed(['solidum', 'circuitry']));
    expect(s.catalog.lastFullPass, 'Aug 2026');
    expect(s.field.id, 'eng');
    expect(s.saved, ['solidum']);
    expect(s.compare, ['solidum']);
    expect(s.stack, isEmpty);
    expect(s.ranked.map((t) => t.id), ['solidum', 'circuitry']);
    await s.flushed;
    expect(jsonDecode(store.value!)['saved'], ['solidum']);
    s.dispose();
  });

  test('visiting a vendor opens its partner link', () async {
    final links = FakeLinks();
    final s = await newState(MemoryStorage(), links: links);
    await s.visitVendor(s.catalog.tool('solidum')!);
    expect(links.opened.single.toString(), 'https://solidum.ai');
    expect(s.toast.value, isNull);
    s.dispose();

    final failing = await newState(
      MemoryStorage(),
      links: FakeLinks(ok: false),
    );
    await failing.visitVendor(failing.catalog.tool('solidum')!);
    expect(failing.toast.value?.message, 'Couldn’t open solidum.ai');
    failing.dispose();
  });

  test('reset wipes storage and returns to onboarding', () async {
    final store = MemoryStorage();
    final s = await newState(store);
    s.finishIntro(Role.pro);
    s.toggleSaved('solidum');
    await s.resetAll();
    expect(store.value, isNull);
    expect(s.inIntro, isTrue);
    expect(s.saved, isEmpty);
    s.dispose();
  });

  test('undo restores a removed saved tool or compare entry', () async {
    final s = await newState(MemoryStorage());
    s.toggleSaved('solidum');
    s.toggleSaved('circuitry');
    s.toggleSaved('solidum');
    expect(s.saved, ['circuitry']);
    s.toast.value!.undo!();
    expect(s.saved, ['solidum', 'circuitry']);
    expect(s.toast.value, isNull);
    s.toggleCompare('solidum');
    s.toggleCompare('solidum');
    s.toast.value!.undo!();
    expect(s.compare, ['solidum']);
    expect(s.toast.value, isNull);
    s.toggleCompare('circuitry');
    expect(s.toast.value!.undo, isNull);
    s.dispose();
  });

  group('web addresses', () {
    test('every screen has one', () async {
      final s = await newState(MemoryStorage());
      expect(locationOf(s), '/welcome');
      s.finishIntro();
      expect(locationOf(s), '/');
      s.setTab(VxTab.saved);
      expect(locationOf(s), '/saved');
      s.openField('law');
      expect(locationOf(s), '/field/law');
      s.openTool('precedent');
      expect(locationOf(s), '/tool/precedent');
      s.push(const MethodPage());
      expect(locationOf(s), '/method');
      s.dispose();
    });

    test(
      'back and forward keep the stack; links open where they point',
      () async {
        final s = await newState(MemoryStorage());
        s.finishIntro();
        s.openField('eng');
        s.openTool('solidum');
        applyLocation(s, Uri(path: '/field/eng'));
        expect(s.stack, hasLength(1));
        expect(locationOf(s), '/field/eng');
        applyLocation(s, Uri(path: '/tool/solidum'));
        expect(s.stack, hasLength(2));
        applyLocation(s, Uri(path: '/compare'));
        expect(locationOf(s), '/compare');
        applyLocation(s, Uri(path: '/tool/nope'));
        expect(locationOf(s), '/');
        applyLocation(s, Uri(path: '/field/med'));
        expect(s.field.id, 'med');
        s.dispose();
      },
    );

    test('a shared link skips the intro; a bare visit keeps it', () async {
      final s = await newState(MemoryStorage());
      applyLocation(s, Uri(path: '/'));
      expect(s.inIntro, isTrue);
      applyLocation(s, Uri(path: '/tool/cortexa'));
      expect(s.inIntro, isFalse);
      expect(locationOf(s), '/tool/cortexa');
      s.dispose();
    });

    test('share links need a web version to point at', () {
      expect(shareLinkFor('solidum', web: false, site: ''), isNull);
      expect(
        shareLinkFor(
          'solidum',
          web: false,
          site: 'https://example.test/vertex/',
        ).toString(),
        'https://example.test/vertex/#/tool/solidum',
      );
    });
  });
}
