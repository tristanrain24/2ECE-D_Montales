import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vertex/app.dart';
import 'package:vertex/data/models.dart';
import 'package:vertex/services/services.dart';
import 'package:vertex/state/app_state.dart';

import 'logic_test.dart' show loadCatalog;

const phone = Size(390, 844);
const smallPhone = Size(320, 568);
const desktop = Size(1280, 800);

Future<AppState> boot(
  WidgetTester tester, {
  Size size = phone,
  bool onboarded = true,
  Role? role,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  final state = AppState(
    catalog: loadCatalog(),
    storage: MemoryStorage(),
    payments: DemoPaymentGateway(delay: const Duration(milliseconds: 50)),
    verifier: DemoStudentVerifier(delay: Duration.zero),
    clock: () => DateTime(2026, 11, 16),
  );
  if (onboarded) state.finishIntro(role);
  addTearDown(state.dispose);
  await tester.pumpWidget(VertexApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

/// Lets toasts expire so no timer outlives the test.
Future<void> drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  if (find.text(text).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  final f = find.text(text).last;
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('onboarding: pick a field and a role, land on its top pick', (
    tester,
  ) async {
    final s = await boot(tester, onboarded: false);
    expect(
      find.text('One rated pick per field. Nothing else.'),
      findsOneWidget,
    );
    await tapText(tester, 'Set me up — 20 seconds');
    expect(find.text('What are you working in?'), findsOneWidget);
    await tapText(tester, 'Medicine');
    expect(find.text('And who’s asking?'), findsOneWidget);
    await tapText(tester, 'Student');
    expect(s.inIntro, isFalse);
    expect(find.text('Cortexa MD'), findsOneWidget);
    expect(find.text('MEDICINE · STUDENT'), findsOneWidget);
    expect(find.text('\$14/mo with student email'), findsOneWidget);
  });

  testWidgets('onboarding can be skipped and stepped back through', (
    tester,
  ) async {
    final s = await boot(tester, onboarded: false);
    await tapText(tester, 'Set me up — 20 seconds');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome'.toUpperCase()), findsOneWidget);
    await tapText(tester, 'Skip — let me just browse');
    expect(s.inIntro, isFalse);
    expect(find.text('Here’s the call.'), findsOneWidget);
  });

  testWidgets('student buys the top pick end to end', (tester) async {
    final s = await boot(tester, role: Role.student);
    await tapText(tester, 'Solidum');
    expect(find.text('Measured in Engineering'.toUpperCase()), findsOneWidget);
    await tapText(tester, 'Get Solidum · \$12/mo with student email');

    expect(find.text('Step 1 of 3 · Plan'), findsOneWidget);
    expect(find.text('\$12.00/mo'), findsOneWidget);
    await tapText(tester, 'Continue');

    expect(find.text('Step 2 of 3 · Verify'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'me@gmail.com');
    await tapText(tester, 'Send code');
    expect(find.textContaining('Use a school address'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'maya.chen@mit.edu');
    await tapText(tester, 'Send code');
    final code = s.verifier.demoCodeFor('maya.chen@mit.edu')!;
    expect(find.textContaining(code), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '000000');
    await tapText(tester, 'Verify');
    if (code != '000000') {
      expect(find.textContaining('doesn’t match'), findsOneWidget);
    }
    await tester.enterText(find.byType(TextField).last, code);
    await tapText(tester, 'Verify');
    expect(
      find.text('Verified · Massachusetts Institute of Technology'),
      findsOneWidget,
    );
    await tapText(tester, 'Continue');

    expect(find.text('Step 3 of 3 · Pay'), findsOneWidget);
    expect(find.textContaining('Demo checkout'), findsOneWidget);
    expect(find.text('Choose a payment method'), findsOneWidget);
    await tapText(tester, 'Card');
    await tester.tap(find.text('Pay \$12.00 with Card'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('Confirming payment'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('You’re in.'), findsOneWidget);
    final p = s.purchaseFor('solidum')!;
    expect(p.planName, 'Student');
    expect(p.amountCents, 1200);
    expect(find.text(p.licenceKey), findsOneWidget);
    await tapText(tester, 'Done');

    expect(find.text('Manage plan · Student'), findsOneWidget);
    s.setTab(VxTab.you);
    await tester.pumpAndSettle();
    expect(find.text('Solidum · Student'), findsOneWidget);
    expect(find.text('\$12.00/mo · renews 16 Dec 2026'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
  });

  testWidgets('non-student: two steps, seat pricing, annual billing, cancel', (
    tester,
  ) async {
    final s = await boot(tester, role: Role.team);
    await tapText(tester, 'Solidum');
    await tapText(tester, 'Get Solidum · \$95/seat · team');
    expect(find.text('Step 1 of 2 · Plan'), findsOneWidget);
    expect(find.text('\$190.00/mo for 2 seats'), findsOneWidget);
    await tester.tap(find.byTooltip('More seats'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Annual · save 20%');
    expect(find.text('\$2,736.00/yr for 3 seats'), findsOneWidget);
    await tapText(tester, 'Continue');
    await tapText(tester, 'PayPal');
    await tapText(tester, 'Pay \$2,736.00 with PayPal');
    expect(find.text('You’re in.'), findsOneWidget);
    await tapText(tester, 'Done');

    await tapText(tester, 'Manage plan · Team');
    await tapText(tester, 'Cancel subscription');
    await tapText(tester, 'Cancel subscription');
    expect(s.purchaseFor('solidum')!.isActive, isFalse);
    await drain(tester);
  });

  testWidgets('free plan activates without a payment step', (tester) async {
    final s = await boot(tester);
    s.setStudent(
      StudentStatus(
        email: 'a@mit.edu',
        institution: 'MIT',
        verifiedAt: DateTime(2026, 11, 1),
      ),
    );
    s.openTool('circuitry');
    await tester.pumpAndSettle();
    await tapText(tester, 'Get Circuitry · from Free');
    await tapText(tester, 'Student');
    expect(find.text('Step 1 of 1 · Plan'), findsOneWidget);
    await tapText(tester, 'Start Student plan');
    expect(find.text('You’re in.'), findsOneWidget);
    expect(s.purchaseFor('circuitry')!.amountCents, 0);
  });

  testWidgets('review goes to the desk and shows as in review', (tester) async {
    final s = await boot(tester);
    s.openTool('solidum');
    await tester.pumpAndSettle();
    await tapText(tester, 'Write a review');
    expect(find.text('Pick a verdict to continue.'), findsOneWidget);
    await tapText(tester, 'Take it');
    await tester.enterText(find.byType(TextField).last, 'Too short');
    await tester.pumpAndSettle();
    expect(find.text('11 more characters needed.'), findsOneWidget);
    await tester.tap(find.text('Send for review'));
    await tester.pumpAndSettle();
    expect(s.reviews, isEmpty);
    await tester.enterText(
      find.byType(TextField).last,
      'Caught two interference errors before I printed anything.',
    );
    await tester.pumpAndSettle();
    await tapText(tester, 'Send for review');
    expect(find.text('Sent to the Vertex desk'), findsOneWidget);
    await tapText(tester, 'Done');
    expect(s.reviewsFor('solidum'), hasLength(1));
    expect(find.text('In review'), findsOneWidget);
  });

  testWidgets('category filters, sort and empty state', (tester) async {
    final s = await boot(tester);
    s.openField('eng');
    await tester.pumpAndSettle();
    expect(find.text('5 tools rated'), findsOneWidget);
    await tapText(tester, 'Filter');
    await tapText(tester, 'A only');
    await tapText(tester, 'Show 2');
    expect(find.text('2 tools after filters'), findsOneWidget);
    expect(find.text('Filters on'), findsOneWidget);
    s.setSub('GD&T checking');
    await tester.pumpAndSettle();
    expect(
      find.text('Nothing clears that filter in this field.'),
      findsOneWidget,
    );
    await tapText(tester, 'Reset filters');
    expect(find.text('5 tools rated'), findsOneWidget);
    await tapText(tester, 'By tier');
    expect(find.text('By accuracy'), findsOneWidget);
  });

  testWidgets('search, save and compare', (tester) async {
    final s = await boot(tester);
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'radiology');
    await tester.pumpAndSettle();
    await tapText(tester, 'RadSecond');
    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();
    expect(s.saved, ['radsecond']);
    await tapText(tester, 'Add to compare');
    await drain(tester);
    s.openTool('cortexa');
    await tester.pumpAndSettle();
    await tapText(tester, 'Add to compare');
    await drain(tester);
    await tapText(tester, 'In compare — view head to head');
    expect(find.textContaining('Cortexa MD takes it.'), findsOneWidget);
    expect(find.text('MEDICINE · 2 OF 3'), findsOneWidget);
    s.setTab(VxTab.saved);
    await tester.pumpAndSettle();
    expect(find.text('Medicine · \$120/mo'), findsOneWidget);
  });

  // Every screen must lay out without overflow at the extremes we ship to.
  for (final (name, size, scale) in [
    ('small phone, large text', smallPhone, 1.5),
    ('phone', phone, 1.0),
    ('desktop', desktop, 1.0),
  ]) {
    testWidgets('all screens lay out on $name', (tester) async {
      final problems = <String>{};
      final old = FlutterError.onError;
      FlutterError.onError = (d) {
        final lines = d.toString().split('\n');
        final i = lines.indexWhere((l) => l.contains('creator:'));
        problems.add(
          '${lines.where((l) => l.contains('lib/')).join(' | ')} :: ${i < 0 ? '' : lines.sublist(i, i + 4).join(' ')}',
        );
        old?.call(d);
      };
      final s = await boot(
        tester,
        size: size,
        textScale: scale,
        role: Role.student,
      );
      final tool = s.catalog.tool('solidum')!;
      s.toggleSaved('solidum');
      for (final id in ['solidum', 'circuitry', 'femwise']) {
        s.toggleCompare(id);
      }
      s.recordPurchase(
        tool: tool,
        plan: tool.plans[2],
        billing: Billing.annual,
        seats: 12,
        method: 'Card',
      );
      s.addReview(
        Review(
          toolId: 'solidum',
          verdict: ReviewVerdict.fine,
          useCase: 'Capstone',
          body: 'A long enough review body to clip in the list row.',
          createdAt: s.now(),
        ),
      );
      for (final t in VxTab.values) {
        s.setTab(t);
        await tester.pumpAndSettle();
        tester.takeException();
      }
      for (final page in <VxPage>[
        const MethodPage(),
        const SearchPage(),
        const CategoryPage('med'),
        for (final t in s.catalog.tools) DetailPage(t.id),
      ]) {
        s.setTab(VxTab.home);
        s.push(page);
        await tester.pumpAndSettle();
        tester.takeException();
      }
      s.replayIntro();
      for (var i = 0; i < 3; i++) {
        await tester.pumpAndSettle();
        tester.takeException();
        if (i == 0) s.introNext();
        if (i == 1) s.introPickField('eng');
      }
      await drain(tester);
      FlutterError.onError = old;
      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  }

  testWidgets('dark theme renders', (tester) async {
    final s = await boot(tester);
    s.setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    final ctx = tester.element(find.text('Vertex'));
    expect(Theme.of(ctx).brightness, Brightness.dark);
  });
}
