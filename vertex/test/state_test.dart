import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:vertex/data/models.dart';
import 'package:vertex/services/services.dart';
import 'package:vertex/state/app_state.dart';

import 'logic_test.dart' show loadCatalog;

Future<AppState> newState(Storage storage, {DateTime? at}) => AppState.load(
  catalog: loadCatalog(),
  storage: storage,
  payments: DemoPaymentGateway(delay: Duration.zero),
  verifier: DemoStudentVerifier(delay: Duration.zero),
  clock: () => at ?? DateTime(2026, 11, 16),
);

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
    final tool = s.catalog.tool('solidum')!;
    s.recordPurchase(
      tool: tool,
      plan: tool.plans.first,
      billing: Billing.monthly,
      seats: 1,
      method: 'Card',
    );
    s.addReview(
      Review(
        toolId: 'solidum',
        verdict: ReviewVerdict.take,
        useCase: 'Gearbox',
        body: 'Caught two interference errors.',
        createdAt: s.now(),
      ),
    );
    s.setStudent(
      StudentStatus(
        email: 'maya@mit.edu',
        institution: 'MIT',
        verifiedAt: s.now(),
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
    expect(r.purchaseFor('solidum')!.amountCents, 1200);
    expect(r.purchaseFor('solidum')!.renewsAt, DateTime(2026, 12, 16));
    expect(r.reviewsFor('solidum').single.verdict, ReviewVerdict.take);
    expect(r.studentVerified, isTrue);
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
      }),
    );
    final r = await newState(stale);
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
    expect(s.toast.value, contains('holds three'));
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

  test(
    'changing plan keeps the licence key; cancelling keeps access',
    () async {
      final s = await newState(MemoryStorage());
      final tool = s.catalog.tool('solidum')!;
      final a = s.recordPurchase(
        tool: tool,
        plan: tool.plans[1],
        billing: Billing.monthly,
        seats: 1,
        method: 'Card',
      );
      final b = s.recordPurchase(
        tool: tool,
        plan: tool.plans[2],
        billing: Billing.annual,
        seats: 3,
        method: 'Card',
      );
      expect(s.purchases, hasLength(1));
      expect(b.licenceKey, a.licenceKey);
      expect(b.amountCents, (9500 * 3 * 12 * 0.8).round());
      expect(b.renewsAt, DateTime(2027, 11, 16));
      s.cancelPurchase('solidum');
      expect(s.purchaseFor('solidum')!.isActive, isFalse);
      s.dispose();
    },
  );

  test('student status lapses after a year', () async {
    final store = MemoryStorage();
    final s = await newState(store);
    s.setStudent(
      StudentStatus(
        email: 'a@mit.edu',
        institution: 'MIT',
        verifiedAt: DateTime(2026, 1, 1),
      ),
    );
    expect(s.studentVerified, isTrue);
    await s.flushed;
    s.dispose();
    final later = await newState(store, at: DateTime(2027, 1, 2));
    expect(later.studentVerified, isFalse);
    later.dispose();
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
}
