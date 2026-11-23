import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
        expect(t.link.scheme, 'https', reason: t.id);
        expect(t.link.host, isNotEmpty, reason: t.id);
      }
    });

    String doc({
      List<String> fields = const ['eng'],
      String toolField = 'eng',
    }) => jsonEncode({
      'sample': false,
      'fields': [
        for (final f in fields)
          {
            'id': f,
            'name': f,
            'icon': 'code',
            'subs': '',
            'median': {
              'accuracy': 50,
              'speed': 50,
              'value': 50,
              'integrations': 50,
            },
          },
      ],
      'tools': [
        {
          'id': 'x',
          'name': 'X',
          'field': toolField,
          'sub': 's',
          'tier': 'A',
          'price': '\$1/mo',
          'verdict': 'v',
          'metrics': {
            for (final m in ['accuracy', 'speed', 'value', 'integrations'])
              m: {'score': 1, 'display': ''},
          },
          'plans': [
            {'name': 'Solo', 'price': '\$1/mo', 'note': ''},
          ],
          'domain': 'x.example',
          'url': 'https://x.example/?ref=vertex',
          'evidence': 'e',
          'tested': 't',
        },
      ],
    });

    test('reads partner links and the sample flag', () {
      final c = Catalog.fromJson(doc());
      expect(c.sample, isFalse);
      expect(c.tool('x')!.link.toString(), 'https://x.example/?ref=vertex');
      expect(catalog.sample, isTrue);
      expect(catalog.tool('solidum')!.link.toString(), 'https://solidum.ai');
    });

    test('drops fields with nothing rated and tools with no field', () {
      final c = Catalog.fromJson(doc(fields: ['eng', 'law']));
      expect(c.fields.map((f) => f.id), ['eng']);
      expect(
        () => Catalog.fromJson(doc(toolField: 'nope')),
        throwsFormatException,
      );
    });

    test('rejects malformed documents', () {
      expect(() => Catalog.fromJson('[]'), throwsFormatException);
      expect(() => Catalog.fromJson('{'), throwsFormatException);
      expect(() => Catalog.fromJson('{"fields": 3}'), throwsA(anything));
    });

    group('source', () {
      final bundled = File('assets/data/catalog.json').readAsStringSync();
      final published = doc();
      CatalogSource source(MockClient client, Storage cache) => CatalogSource(
        url: 'https://example.test/catalog.json',
        client: client,
        bundled: () async => bundled,
        cache: cache,
      );

      test(
        'starts from the bundled copy, then caches a good download',
        () async {
          final cache = MemoryStorage();
          final src = source(
            MockClient((_) async => http.Response(published, 200)),
            cache,
          );
          expect((await src.initial()).tools, hasLength(22));
          final next = await src.refresh();
          expect(next!.tools.single.id, 'x');
          expect(cache.value, published);
          expect((await src.initial()).tools.single.id, 'x');
        },
      );

      test('ignores failures, bad edits and a corrupt cache', () async {
        final cache = MemoryStorage('not json');
        for (final res in [
          http.Response('missing', 404),
          http.Response('{"fields": []', 200),
          http.Response(doc(toolField: 'nope'), 200),
        ]) {
          final src = source(MockClient((_) async => res), cache);
          expect(await src.refresh(), isNull);
        }
        final offline = source(
          MockClient((_) async => throw const SocketException('offline')),
          cache,
        );
        expect(await offline.refresh(), isNull);
        expect((await offline.initial()).tools, hasLength(22));
        expect(cache.value, isNull);
      });
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
      expect(leadPrice(solidum, Role.student), '\$12/mo for students');
      expect(leadPrice(solidum, Role.team), '\$95/seat · team');
      expect(leadPrice(solidum, null), 'From \$12/mo');
      expect(leadPrice(catalog.tool('femwise')!, Role.student), 'From \$55/mo');
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

  group('format', () {
    test('dates and tier movement', () {
      expect(fmtDate(DateTime(2026, 11, 4)), '4 Nov 2026');
      expect(moveNote(0), 'Tier held');
      expect(moveNote(2), 'Rose +2');
      expect(moveNote(-1), 'Fell -1');
    });

    test('plan helpers', () {
      expect(
        const Plan(name: 'Student', price: 'Free', note: '').isFree,
        isTrue,
      );
      expect(
        const Plan(name: 'Student', price: '\$9', note: '').requiresStudent,
        isTrue,
      );
      expect(const Plan(name: 'Lab', price: '', note: '').isTeamPlan, isTrue);
    });
  });
}
