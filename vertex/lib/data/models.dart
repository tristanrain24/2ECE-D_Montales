import 'dart:convert';

/// A Vertex tier is a recommendation, not a score.
enum Tier {
  a(
    'A',
    3,
    'Take it',
    'Best in its field on the evidence we have. We would pick this ourselves.',
  ),
  b(
    'B',
    2,
    'Solid',
    'A real option when the A-tier does not fit your budget, stack or jurisdiction.',
  ),
  c(
    'C',
    1,
    'Situational',
    'One narrow strength. Only worth it if that exact thing is your bottleneck.',
  );

  const Tier(this.label, this.rank, this.word, this.why);
  final String label;
  final int rank;
  final String word;
  final String why;

  static Tier parse(String s) =>
      values.firstWhere((t) => t.label == s, orElse: () => Tier.c);
}

enum Metric {
  accuracy('Accuracy'),
  speed('Speed'),
  value('Price / value'),
  integrations('Integrations');

  const Metric(this.label);
  final String label;
}

enum Role {
  student('Student', 'We lead with academic and free tiers'),
  pro('Working professional', 'Individual plans, priced per seat'),
  team('Team or department', 'Seat pricing, admin and audit features');

  const Role(this.label, this.note);
  final String label;
  final String note;
}

class MetricValue {
  const MetricValue(this.score, this.display);
  final int score;
  final String display;
}

class Plan {
  const Plan({required this.name, required this.price, required this.note});
  final String name;

  /// Display label, e.g. `$12/mo`, `$95/seat`, `Free`, `Custom`.
  final String price;
  final String note;

  bool get isFree => price.toLowerCase() == 'free';
  bool get isCustom => price.toLowerCase() == 'custom';
  bool get perSeat => price.contains('/seat');

  /// Student plans are gated behind a verified academic email.
  bool get requiresStudent => name.toLowerCase() == 'student';

  bool get isTeamPlan => RegExp(
    r'team|lab|firm|department|company|practice|cohort',
    caseSensitive: false,
  ).hasMatch(name);

  /// Monthly price per unit in cents. Null when the plan is priced on request.
  int? get monthlyCents {
    if (isFree) return 0;
    final m = RegExp(r'\$(\d+(?:\.\d{1,2})?)').firstMatch(price);
    if (m == null) return null;
    return (double.parse(m.group(1)!) * 100).round();
  }

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
    name: j['name'] as String,
    price: j['price'] as String,
    note: j['note'] as String? ?? '',
  );
}

class Field {
  const Field({
    required this.id,
    required this.name,
    required this.icon,
    required this.subs,
    required this.median,
  });
  final String id;
  final String name;
  final String icon;
  final String subs;
  final Map<Metric, int> median;

  factory Field.fromJson(Map<String, dynamic> j) {
    final m = j['median'] as Map<String, dynamic>;
    return Field(
      id: j['id'] as String,
      name: j['name'] as String,
      icon: j['icon'] as String,
      subs: j['subs'] as String,
      median: {for (final k in Metric.values) k: (m[k.name] as num).toInt()},
    );
  }
}

class Tool {
  const Tool({
    required this.id,
    required this.name,
    required this.fieldId,
    required this.sub,
    required this.tier,
    required this.price,
    required this.verdict,
    required this.metrics,
    required this.wins,
    required this.losses,
    required this.integrations,
    required this.integrationsMore,
    required this.plans,
    required this.domain,
    required this.evidence,
    required this.tested,
    required this.move,
    required this.tagline,
    required this.pitch,
    required this.keywords,
  });

  final String id;
  final String name;
  final String fieldId;
  final String sub;
  final Tier tier;

  /// Headline list price label, e.g. `$39/mo`.
  final String price;
  final String verdict;
  final Map<Metric, MetricValue> metrics;
  final List<String> wins;
  final List<String> losses;
  final List<String> integrations;
  final String integrationsMore;
  final List<Plan> plans;
  final String domain;
  final String evidence;
  final String tested;

  /// Tier movement at the last monthly re-score (+ rose, - fell, 0 held).
  final int move;
  final String tagline;
  final String pitch;
  final String keywords;

  int get accuracy => metrics[Metric.accuracy]!.score;

  int get priceDollars =>
      int.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  factory Tool.fromJson(Map<String, dynamic> j) {
    final m = j['metrics'] as Map<String, dynamic>;
    List<String> strs(String k) =>
        (j[k] as List? ?? const []).map((e) => e as String).toList();
    return Tool(
      id: j['id'] as String,
      name: j['name'] as String,
      fieldId: j['field'] as String,
      sub: j['sub'] as String,
      tier: Tier.parse(j['tier'] as String),
      price: j['price'] as String,
      verdict: j['verdict'] as String,
      metrics: {
        for (final k in Metric.values)
          k: MetricValue(
            ((m[k.name] as Map)['score'] as num).toInt(),
            (m[k.name] as Map)['display'] as String,
          ),
      },
      wins: strs('wins'),
      losses: strs('losses'),
      integrations: strs('integrations'),
      integrationsMore: j['integrationsMore'] as String? ?? '',
      plans: (j['plans'] as List)
          .map((e) => Plan.fromJson(e as Map<String, dynamic>))
          .toList(),
      domain: j['domain'] as String,
      evidence: j['evidence'] as String,
      tested: j['tested'] as String,
      move: (j['move'] as num?)?.toInt() ?? 0,
      tagline: j['tagline'] as String? ?? '',
      pitch: j['pitch'] as String? ?? '',
      keywords: j['keywords'] as String? ?? '',
    );
  }
}

class Catalog {
  Catalog({
    required this.fields,
    required this.tools,
    required this.lastFullPass,
  }) : _toolsById = {for (final t in tools) t.id: t},
       _fieldsById = {for (final f in fields) f.id: f};

  final List<Field> fields;
  final List<Tool> tools;
  final String lastFullPass;
  final Map<String, Tool> _toolsById;
  final Map<String, Field> _fieldsById;

  Tool? tool(String id) => _toolsById[id];
  Field? field(String id) => _fieldsById[id];
  Field fieldOf(Tool t) => _fieldsById[t.fieldId]!;
  List<Tool> toolsIn(String fieldId) =>
      tools.where((t) => t.fieldId == fieldId).toList();

  factory Catalog.fromJson(String source) {
    final j = jsonDecode(source) as Map<String, dynamic>;
    final fields = (j['fields'] as List)
        .map((e) => Field.fromJson(e as Map<String, dynamic>))
        .toList();
    final ids = fields.map((f) => f.id).toSet();
    final tools = (j['tools'] as List)
        .map((e) => Tool.fromJson(e as Map<String, dynamic>))
        // A tool without a known field cannot be ranked, so it is dropped.
        .where((t) => ids.contains(t.fieldId) && t.plans.isNotEmpty)
        .toList();
    return Catalog(
      fields: fields,
      tools: tools,
      lastFullPass: j['lastFullPass'] as String? ?? '',
    );
  }
}

enum Billing { monthly, annual }

enum PurchaseStatus { active, cancelled }

class Purchase {
  const Purchase({
    required this.toolId,
    required this.planName,
    required this.billing,
    required this.seats,
    required this.amountCents,
    required this.purchasedAt,
    required this.renewsAt,
    required this.licenceKey,
    required this.method,
    this.status = PurchaseStatus.active,
  });

  final String toolId;
  final String planName;
  final Billing billing;
  final int seats;

  /// Amount charged per billing period, in cents.
  final int amountCents;
  final DateTime purchasedAt;
  final DateTime renewsAt;
  final String licenceKey;
  final String method;
  final PurchaseStatus status;

  bool get isActive => status == PurchaseStatus.active;

  Purchase cancelled() => Purchase(
    toolId: toolId,
    planName: planName,
    billing: billing,
    seats: seats,
    amountCents: amountCents,
    purchasedAt: purchasedAt,
    renewsAt: renewsAt,
    licenceKey: licenceKey,
    method: method,
    status: PurchaseStatus.cancelled,
  );

  Map<String, dynamic> toJson() => {
    'toolId': toolId,
    'planName': planName,
    'billing': billing.name,
    'seats': seats,
    'amountCents': amountCents,
    'purchasedAt': purchasedAt.toIso8601String(),
    'renewsAt': renewsAt.toIso8601String(),
    'licenceKey': licenceKey,
    'method': method,
    'status': status.name,
  };

  factory Purchase.fromJson(Map<String, dynamic> j) => Purchase(
    toolId: j['toolId'] as String,
    planName: j['planName'] as String,
    billing: Billing.values.byName(j['billing'] as String),
    seats: (j['seats'] as num).toInt(),
    amountCents: (j['amountCents'] as num).toInt(),
    purchasedAt: DateTime.parse(j['purchasedAt'] as String),
    renewsAt: DateTime.parse(j['renewsAt'] as String),
    licenceKey: j['licenceKey'] as String,
    method: j['method'] as String? ?? '',
    status: PurchaseStatus.values.byName(j['status'] as String),
  );
}

enum ReviewVerdict {
  take('Take it'),
  fine('It’s fine'),
  skip('Skip it');

  const ReviewVerdict(this.label);
  final String label;
}

class Review {
  const Review({
    required this.toolId,
    required this.verdict,
    required this.useCase,
    required this.body,
    required this.createdAt,
  });
  final String toolId;
  final ReviewVerdict verdict;
  final String useCase;
  final String body;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'toolId': toolId,
    'verdict': verdict.name,
    'useCase': useCase,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Review.fromJson(Map<String, dynamic> j) => Review(
    toolId: j['toolId'] as String,
    verdict: ReviewVerdict.values.byName(j['verdict'] as String),
    useCase: j['useCase'] as String? ?? '',
    body: j['body'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

class StudentStatus {
  const StudentStatus({
    required this.email,
    required this.institution,
    required this.verifiedAt,
  });
  final String email;
  final String institution;
  final DateTime verifiedAt;

  String get domain => email.split('@').last;

  /// Student status is re-confirmed once a year.
  DateTime get expiresAt =>
      DateTime(verifiedAt.year + 1, verifiedAt.month, verifiedAt.day);
  bool isValidAt(DateTime now) => now.isBefore(expiresAt);

  Map<String, dynamic> toJson() => {
    'email': email,
    'institution': institution,
    'verifiedAt': verifiedAt.toIso8601String(),
  };

  factory StudentStatus.fromJson(Map<String, dynamic> j) => StudentStatus(
    email: j['email'] as String,
    institution: j['institution'] as String,
    verifiedAt: DateTime.parse(j['verifiedAt'] as String),
  );
}
