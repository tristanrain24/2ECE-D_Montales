import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vertex/data/models.dart';
import 'package:vertex/logic/format.dart';
import 'package:vertex/logic/ranking.dart';
import 'package:vertex/logic/search.dart';
import 'package:vertex/services/services.dart';

Catalog loadCatalog() =>
    Catalog.fromJson(File('assets/data/catalog.json').readAsStringSync());

void main() {
  final catalog = loadCatalog();

  group('catalog', () {
    test('ships 22 tools across 9 fields, every field populated', () {
      expect(catalog.tools, hasLength(22));
      expect(catalog.fields, hasLength(9));
      for (final f in catalog.fields) {
        expect(catalog.toolsIn(f.id), isNotEmpty, reason: f.name);
      }
    });

    test('every tool has all four metrics in range and a parseable price', () {
      for (final t in catalog.tools) {
        for (final m in Metric.values) {
          expect(t.metrics[m]!.score, inInclusiveRange(0, 100), reason: t.id);
        }
        expect(t.priceDollars, greaterThan(0), reason: t.id);
        expect(t.plans.where((p) => !p.isCustom), isNotEmpty, reason: t.id);
      }
    });

    test('drops tools whose field is unknown', () {
      final c = Catalog.fromJson('''{"fields":[],"tools":[{"id":"x","name":"X",
        "field":"nope","sub":"s","tier":"A","price":"\$1/mo","verdict":"v",
        "metrics":{"accuracy":{"score":1,"display":""},"speed":{"score":1,"display":""},
        "value":{"score":1,"display":""},"integrations":{"score":1,"display":""}},
        "plans":[{"name":"Solo","price":"\$1/mo","note":""}],
        "domain":"d","evidence":"e","tested":"t"}]}''');
      expect(c.tools, isEmpty);
    });
  });

  group('ranking', () {
    test('orders by tier, then accuracy', () {
      final eng = rankField(catalog, 'eng').map((t) => t.id).toList();
      expect(eng, [
        'solidum',
        'circuitry',
        'femwise',
        'struxlab',
        'toleranceiq',
      ]);
    });

    test('tier and price filters', () {
      ids(List<Tool> l) => l.map((t) => t.id).toSet();
      expect(ids(filterField(catalog, 'eng', tier: TierFilter.aOnly)), {
        'solidum',
        'circuitry',
      });
      expect(
        ids(filterField(catalog, 'eng', tier: TierFilter.bAndUp)),
        isNot(contains('toleranceiq')),
      );
      expect(ids(filterField(catalog, 'eng', price: PriceFilter.under40)), {
        'solidum',
        'circuitry',
        'toleranceiq',
      });
      expect(
        ids(filterField(catalog, 'eng', price: PriceFilter.freeOrStudent)),
        {'solidum', 'circuitry'},
      );
      expect(
        filterField(catalog, 'eng', sort: SortOrder.price).first.id,
        'toleranceiq',
      );
      expect(
        filterField(catalog, 'eng', sub: 'Simulation & FEA').single.id,
        'femwise',
      );
    });

    test('lead price follows the role, never the tier', () {
      final solidum = catalog.tool('solidum')!;
      expect(leadPrice(solidum, Role.student), '\$12/mo with student email');
      expect(leadPrice(solidum, Role.team), '\$95/seat · team');
      expect(leadPrice(solidum, null), 'From \$12/mo');
      expect(leadPrice(catalog.tool('femwise')!, Role.student), 'From \$55/mo');
    });

    test('default plan by role skips student pricing for non-students', () {
      final solidum = catalog.tool('solidum')!;
      expect(defaultPlan(solidum, Role.student).name, 'Student');
      expect(defaultPlan(solidum, Role.pro).name, 'Pro');
      expect(defaultPlan(solidum, Role.team).name, 'Team');
      expect(defaultPlan(catalog.tool('radsecond')!, Role.team).name, 'Reader');
    });

    test('compare marks winners and calls one', () {
      final tools = [
        'solidum',
        'circuitry',
      ].map((i) => catalog.tool(i)!).toList();
      final rows = {for (final r in compareRows(tools)) r.label: r};
      expect(rows['Vertex tier']!.best, {0, 1});
      expect(rows['Accuracy']!.best, {0});
      expect(rows['Price']!.best, {1});
      expect(compareWinner(tools)!.id, 'solidum');
      expect(compareVerdict(tools), startsWith('Solidum takes it.'));
      expect(compareRows([tools.first]).every((r) => r.best.isEmpty), isTrue);
    });
  });

  group('search', () {
    test('finds by task, field and name; ignores stop words', () {
      expect(searchTools(catalog, 'radiology').first.id, 'radsecond');
      expect(searchTools(catalog, 'circuit design').first.id, 'circuitry');
      expect(searchTools(catalog, 'KERNELSMITH').single.id, 'kernelsmith');
      expect(
        searchTools(catalog, 'legal').map((t) => t.fieldId).toSet(),
        contains('law'),
      );
      expect(searchTools(catalog, 'the of and'), isEmpty);
      expect(searchTools(catalog, 'zzzz'), isEmpty);
    });
  });

  group('pricing', () {
    test('plan parsing', () {
      const student = Plan(name: 'Student', price: '\$12/mo', note: '');
      const seat = Plan(name: 'Team', price: '\$95/seat', note: '');
      const free = Plan(name: 'Student', price: 'Free', note: '');
      const custom = Plan(name: 'Department', price: 'Custom', note: '');
      expect(student.monthlyCents, 1200);
      expect(student.requiresStudent, isTrue);
      expect(seat.perSeat, isTrue);
      expect(free.monthlyCents, 0);
      expect(custom.monthlyCents, isNull);
      expect(dueCents(student, Billing.monthly, 1), 1200);
      expect(dueCents(student, Billing.annual, 1), 11520);
      expect(dueCents(seat, Billing.monthly, 4), 38000);
      expect(dueCents(student, Billing.monthly, 4), 1200);
      expect(dueCents(custom, Billing.monthly, 1), isNull);
    });

    test('formatting', () {
      expect(fmtCents(1200), '\$12.00');
      expect(fmtCents(123456789), '\$1,234,567.89');
      expect(fmtCents(5), '\$0.05');
      expect(fmtDate(DateTime(2026, 11, 4)), '4 Nov 2026');
    });

    test('renewal clamps to month end', () {
      expect(
        nextRenewal(DateTime(2026, 1, 31), Billing.monthly),
        DateTime(2026, 2, 28),
      );
      expect(
        nextRenewal(DateTime(2026, 12, 15), Billing.monthly),
        DateTime(2027, 1, 15),
      );
      expect(
        nextRenewal(DateTime(2026, 3, 1), Billing.annual),
        DateTime(2027, 3, 1),
      );
    });
  });

  group('student verification', () {
    test('academic email detection', () {
      for (final ok in [
        'maya.chen@mit.edu',
        'a@cs.stanford.edu',
        'juan@up.edu.ph',
        'x@ox.ac.uk',
        ' Trim@MIT.EDU ',
      ]) {
        expect(isAcademicEmail(ok), isTrue, reason: ok);
      }
      for (final bad in [
        'me@gmail.com',
        'me@education.com',
        'me@edu',
        'not-an-email',
        'a@b@mit.edu',
        'me@academy.co',
      ]) {
        expect(isAcademicEmail(bad), isFalse, reason: bad);
      }
    });

    test('institution lookup', () {
      expect(
        institutionFor('a@mit.edu'),
        'Massachusetts Institute of Technology',
      );
      expect(
        institutionFor('a@cs.mit.edu'),
        'Massachusetts Institute of Technology',
      );
      expect(institutionFor('a@summit.edu'), 'summit.edu');
    });

    test('code round trip', () async {
      final v = DemoStudentVerifier(
        delay: Duration.zero,
        random: Random(1),
        clock: () => DateTime(2026, 11, 16),
      );
      await expectLater(
        v.sendCode('me@gmail.com'),
        throwsA(isA<VerificationException>()),
      );
      await expectLater(
        v.confirm('maya@mit.edu', '000000'),
        throwsA(isA<VerificationException>()),
      );
      await v.sendCode('Maya@MIT.edu');
      final code = v.demoCodeFor('maya@mit.edu')!;
      expect(code, hasLength(6));
      await expectLater(
        v.confirm('maya@mit.edu', code == '111111' ? '222222' : '111111'),
        throwsA(isA<VerificationException>()),
      );
      final st = await v.confirm('maya@mit.edu', code);
      expect(st.institution, 'Massachusetts Institute of Technology');
      expect(st.isValidAt(DateTime(2027, 11, 15)), isTrue);
      expect(st.isValidAt(DateTime(2027, 11, 16)), isFalse);
    });

    test('licence key shape', () {
      final k = newLicenceKey(catalog.tool('solidum')!, Random(3));
      expect(k, matches(RegExp(r'^VX-SOLI-[A-Z2-9]{4}-[A-Z2-9]{4}$')));
    });
  });
}
