import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/models.dart';
import '../../logic/format.dart';
import '../../logic/ranking.dart';
import '../../services/services.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../sheets.dart';
import '../widgets/widgets.dart';
import 'review.dart';

Future<void> showCheckout(BuildContext context, Tool tool) =>
    showVxSheet<void>(context, (_) => CheckoutFlow(tool: tool));

Future<void> showStudentVerifySheet(BuildContext context) =>
    showVxSheet<void>(context, (ctx) {
      final s = AppScope.of(ctx);
      return SheetScaffold(
        title: 'Student status',
        subtitle: 'Confirmed once a year',
        leadingLabel: 'Close',
        onLeading: () => Navigator.pop(ctx),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: StudentVerifyPanel(onVerified: s.setStudent),
        ),
        footer: s.studentVerified
            ? VxButton(
                'Done',
                kind: VxButtonKind.primary,
                block: true,
                onTap: () => Navigator.pop(ctx),
              )
            : null,
      );
    });

List<PayMethod> platformPayMethods() => switch (defaultTargetPlatform) {
  TargetPlatform.iOS || TargetPlatform.macOS => const [
    PayMethod.applePay,
    PayMethod.card,
    PayMethod.payPal,
  ],
  TargetPlatform.android => const [
    PayMethod.googlePay,
    PayMethod.card,
    PayMethod.payPal,
  ],
  _ => const [PayMethod.card, PayMethod.payPal],
};

IconData _payIcon(PayMethod m) => switch (m) {
  PayMethod.applePay => PhFill.appleLogo,
  PayMethod.googlePay => Ph.googleLogo,
  PayMethod.card => Ph.creditCard,
  PayMethod.payPal => Ph.paypalLogo,
};

enum _Step { plan, verify, pay, processing, done }

class CheckoutFlow extends StatefulWidget {
  const CheckoutFlow({super.key, required this.tool});
  final Tool tool;

  @override
  State<CheckoutFlow> createState() => _CheckoutFlowState();
}

class _CheckoutFlowState extends State<CheckoutFlow> {
  Plan? _plan;
  Billing _billing = Billing.monthly;
  int _seats = 2;
  _Step _step = _Step.plan;
  PayMethod? _method;
  String? _error;
  Purchase? _result;
  bool _verifiedHere = false;

  Tool get tool => widget.tool;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_plan == null) {
      final s = AppScope.read(context);
      final owned = s.purchaseFor(tool.id);
      _plan =
          tool.plans
              .where((p) => p.name == owned?.planName && !p.isCustom)
              .firstOrNull ??
          defaultPlan(tool, s.role);
      if (owned != null) {
        _billing = owned.billing;
        _seats = owned.seats < 2 ? 2 : owned.seats;
      }
    }
  }

  Plan get plan => _plan!;
  int get _due => dueCents(plan, _billing, _seats) ?? 0;

  List<_Step> _flow(AppState s) => [
    _Step.plan,
    if (plan.requiresStudent && (!s.studentVerified || _verifiedHere))
      _Step.verify,
    if (_due > 0) _Step.pay,
  ];

  String _priceSuffix() {
    final per = plan.perSeat
        ? ' for $_seats ${_seats == 1 ? 'seat' : 'seats'}'
        : '';
    return '${fmtCents(_due)}/${periodLabel(_billing)}$per';
  }

  void _advance(AppState s) {
    final flow = _flow(s);
    final i = flow.indexOf(_step);
    if (i >= 0 && i < flow.length - 1) {
      setState(() {
        _step = flow[i + 1];
        _error = null;
      });
    } else {
      _complete(s);
    }
  }

  void _back(AppState s) {
    final flow = _flow(s);
    final i = flow.indexOf(_step);
    if (i > 0) {
      setState(() {
        _step = flow[i - 1];
        _error = null;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _complete(AppState s) async {
    var methodLabel = 'No payment needed';
    if (_due > 0) {
      final method = _method;
      if (method == null) return;
      setState(() {
        _step = _Step.processing;
        _error = null;
      });
      final PaymentResult res;
      try {
        res = await s.payments.charge(
          amountCents: _due,
          method: method,
          description: '${tool.name} · ${plan.name}',
        );
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _step = _Step.pay;
          _error =
              'We couldn’t reach the payment service. Nothing was charged.';
        });
        return;
      }
      if (!mounted) return;
      if (!res.ok) {
        setState(() {
          _step = _Step.pay;
          _error = '${res.error} Nothing was charged.';
        });
        return;
      }
      methodLabel = method.label;
    }
    final p = s.recordPurchase(
      tool: tool,
      plan: plan,
      billing: _billing,
      seats: _seats,
      method: methodLabel,
    );
    setState(() {
      _result = p;
      _step = _Step.done;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final flow = _flow(s);
    final idx = flow.indexOf(_step);
    final changing = s.purchaseFor(tool.id)?.isActive ?? false;
    final subtitle = switch (_step) {
      _Step.processing => 'Processing',
      _Step.done => 'Done',
      _ =>
        'Step ${idx + 1} of ${flow.length} · ${switch (_step) {
          _Step.plan => 'Plan',
          _Step.verify => 'Verify',
          _ => 'Pay',
        }}',
    };
    return PopScope(
      canPop: _step != _Step.processing,
      child: SheetScaffold(
        title: _step == _Step.done || !changing
            ? 'Get ${tool.name}'
            : 'Change plan · ${tool.name}',
        subtitle: subtitle,
        leadingLabel: switch (_step) {
          _Step.plan => 'Close',
          _Step.verify || _Step.pay => 'Back',
          _ => null,
        },
        onLeading: () => _back(s),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey(_step),
            child: switch (_step) {
              _Step.plan => _planStep(context),
              _Step.verify => Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: StudentVerifyPanel(
                    onVerified: (st) {
                      _verifiedHere = true;
                      s.setStudent(st);
                    },
                  ),
                ),
              ),
              _Step.pay => _payStep(context, s),
              _Step.processing => _processing(context),
              _Step.done => _done(context, s),
            },
          ),
        ),
        footer: switch (_step) {
          _Step.processing => null,
          _Step.done => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VxButton(
                'Done',
                kind: VxButtonKind.primary,
                block: true,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
              VxButton(
                'Write a review',
                block: true,
                kind: VxButtonKind.ghost,
                onTap: () {
                  final nav = Navigator.of(context);
                  final ctx = nav.context;
                  nav.pop();
                  showReviewSheet(ctx, tool);
                },
              ),
            ],
          ),
          _ => _footer(context, s),
        },
      ),
    );
  }

  Widget _footer(BuildContext context, AppState s) {
    final isLast = _flow(s).last == _step;
    final String label;
    VoidCallback? onTap = () => _advance(s);
    if (_step == _Step.verify) {
      label = 'Continue';
      if (!s.studentVerified) onTap = null;
    } else if (_step == _Step.pay) {
      label = _method == null
          ? 'Choose a payment method'
          : 'Pay ${fmtCents(_due)} with ${_method!.label}';
      if (_method == null) onTap = null;
    } else {
      label = isLast ? 'Start ${plan.name} plan' : 'Continue';
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Due today', style: VxText.muted(context, size: 13)),
            ),
            Text(
              _due == 0 ? 'Free' : _priceSuffix(),
              style: VxText.title(context, size: 13.5),
            ),
          ],
        ),
        const SizedBox(height: 12),
        VxButton(label, kind: VxButtonKind.primary, block: true, onTap: onTap),
      ],
    );
  }

  Widget _planStep(BuildContext context) {
    final c = context.vx;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Kicker('Billing'),
        const SizedBox(height: 8),
        VxSegmented<Billing>(
          options: const {
            Billing.monthly: 'Monthly',
            Billing.annual: 'Annual · save 20%',
          },
          value: _billing,
          onChanged: (b) => setState(() => _billing = b),
        ),
        const SizedBox(height: 22),
        const Kicker('Plan'),
        const SizedBox(height: 8),
        for (final p in tool.plans)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Opacity(
              opacity: p.isCustom ? 0.6 : 1,
              child: VxCard(
                selected: p == plan,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                onTap: p.isCustom
                    ? null
                    : () => setState(() {
                        _plan = p;
                        _error = null;
                      }),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 1.5,
                          color: p == plan ? c.accentFg : c.borderStrong,
                        ),
                      ),
                      child: p == plan
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.accentFg,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: VxText.title(context)),
                          const SizedBox(height: 2),
                          Text(
                            p.isCustom
                                ? 'Priced on request — contact ${tool.domain}'
                                : p.requiresStudent
                                ? 'Student email required'
                                : p.note,
                            style: VxText.muted(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(p.price, style: VxText.title(context)),
                  ],
                ),
              ),
            ),
          ),
        if (plan.perSeat) ...[
          const SizedBox(height: 12),
          const Kicker('Seats'),
          const SizedBox(height: 8),
          VxCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                VxIconButton(
                  Ph.minus,
                  label: 'Fewer seats',
                  onTap: _seats > 1 ? () => setState(() => _seats--) : null,
                ),
                Expanded(
                  child: Text(
                    '$_seats ${_seats == 1 ? 'seat' : 'seats'}',
                    textAlign: TextAlign.center,
                    style: VxText.title(context),
                  ),
                ),
                VxIconButton(
                  Ph.plus,
                  label: 'More seats',
                  onTap: _seats < 500 ? () => setState(() => _seats++) : null,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _payStep(BuildContext context, AppState s) {
    final c = context.vx;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        VxCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${tool.name} · ${plan.name}',
                      style: VxText.title(context, size: 14.5),
                    ),
                  ),
                  Text(fmtCents(_due), style: VxText.body(context)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_billing == Billing.monthly ? 'Billed monthly' : 'Billed yearly'}'
                '${plan.perSeat ? ' · $_seats ${_seats == 1 ? 'seat' : 'seats'}' : ''}'
                ' · cancel any time',
                style: VxText.muted(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Kicker('Pay with'),
        const SizedBox(height: 8),
        for (final m in platformPayMethods())
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: VxCard(
              selected: _method == m,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              onTap: () => setState(() {
                _method = m;
                _error = null;
              }),
              child: Row(
                children: [
                  Icon(
                    _payIcon(m),
                    size: 19,
                    color: _method == m ? c.accentFg : c.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      m.label,
                      style: VxText.title(context, size: 14.5),
                    ),
                  ),
                  if (_method == m)
                    Icon(PhFill.checkCircle, size: 18, color: c.accentFg),
                ],
              ),
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(_error!, style: TextStyle(fontSize: 13, color: c.danger)),
        ],
        if (s.payments.isDemo) ...[
          const SizedBox(height: 12),
          const Notice(
            'Demo checkout. No payment details are collected and nothing is '
            'charged — the plan is activated on this device only.',
          ),
        ],
      ],
    );
  }

  Widget _processing(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 44,
          child: CircularProgressIndicator(
            strokeWidth: 1.6,
            color: context.vx.accent,
            backgroundColor: context.vx.accentSoftBorder,
          ),
        ),
        const SizedBox(height: 20),
        Text('Confirming payment', style: VxText.title(context)),
        const SizedBox(height: 5),
        Text(
          '${_method?.label ?? ''} · nothing charged twice',
          style: VxText.muted(context),
        ),
      ],
    ),
  );

  Widget _done(BuildContext context, AppState s) {
    final p = _result!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 36, 22, 20),
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: BadgeIcon(Ph.check),
        ),
        const SizedBox(height: 18),
        Text('You’re in.', style: VxText.display(context, size: 30)),
        const SizedBox(height: 8),
        Text(
          '${tool.name} ${p.planName} is active'
          '${p.amountCents == 0 ? ' on the free plan' : ' at ${fmtCents(p.amountCents)}/${periodLabel(p.billing)}'}. '
          'Your licence key is below and in the You tab.',
          style: VxText.secondary(context, size: 14),
        ),
        const SizedBox(height: 18),
        LicenceKeyCard(licenceKey: p.licenceKey),
      ],
    );
  }
}

class LicenceKeyCard extends StatelessWidget {
  const LicenceKeyCard({super.key, required this.licenceKey});
  final String licenceKey;

  @override
  Widget build(BuildContext context) => VxCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Kicker('Licence key', muted: true),
        const SizedBox(height: 6),
        SelectableText(
          licenceKey,
          style: TextStyle(
            fontSize: 16,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w500,
            color: context.vx.text,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}

/// Email → one-time code → verified. Used in checkout and from the You tab.
class StudentVerifyPanel extends StatefulWidget {
  const StudentVerifyPanel({super.key, required this.onVerified});
  final ValueChanged<StudentStatus> onVerified;

  @override
  State<StudentVerifyPanel> createState() => _StudentVerifyPanelState();
}

class _StudentVerifyPanelState extends State<StudentVerifyPanel> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _sent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(AppState s) op) async {
    final s = AppScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await op(s);
    } on VerificationException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Something went wrong. Check your connection and try again.';
    }
    if (mounted) setState(() => _busy = false);
  }

  void _send() => _run((s) async {
    await s.verifier.sendCode(_email.text);
    _sent = true;
  });

  void _confirm() => _run((s) async {
    final status = await s.verifier.confirm(_email.text, _code.text);
    widget.onVerified(status);
  });

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.vx;
    final st = s.student;
    if (s.studentVerified && st != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You’re verified', style: VxText.display(context, size: 22)),
          const SizedBox(height: 14),
          VxCard(
            borderColor: c.accent,
            child: Row(
              children: [
                Icon(PhFill.sealCheck, size: 22, color: c.accentFg),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(st.email, style: VxText.title(context)),
                      const SizedBox(height: 2),
                      Text(
                        'Verified · ${st.institution}',
                        style: TextStyle(fontSize: 12, color: c.accentFg),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Student pricing is unlocked until ${fmtDate(st.expiresAt)}.',
            style: VxText.muted(context),
          ),
        ],
      );
    }
    final demoCode = _sent ? s.verifier.demoCodeFor(_email.text) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Confirm you’re a student',
          style: VxText.display(context, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          'Use your school email. We send one code, nothing else.',
          style: VxText.secondary(context),
        ),
        const SizedBox(height: 18),
        VxField(
          controller: _email,
          hint: 'you@university.edu',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          enabled: !_sent && !_busy,
          error: _sent ? null : _error,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _send(),
        ),
        const SizedBox(height: 10),
        if (!_sent)
          VxButton(
            'Send code',
            kind: VxButtonKind.primary,
            block: true,
            busy: _busy,
            onTap: _send,
          )
        else ...[
          if (s.verifier.isDemo && demoCode != null) ...[
            Notice(
              'Demo mode: no email is sent. Your code is $demoCode.',
              icon: Ph.envelopeSimple,
            ),
            const SizedBox(height: 10),
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'We sent a 6-digit code to ${_email.text.trim()}.',
                style: VxText.secondary(context),
              ),
            ),
          VxField(
            controller: _code,
            hint: '6-digit code',
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            error: _error,
            enabled: !_busy,
            autofillHints: const [AutofillHints.oneTimeCode],
            onSubmitted: (_) => _confirm(),
          ),
          const SizedBox(height: 10),
          VxButton(
            'Verify',
            kind: VxButtonKind.primary,
            block: true,
            busy: _busy,
            onTap: _confirm,
          ),
          const SizedBox(height: 4),
          VxButton(
            'Use a different email',
            kind: VxButtonKind.ghost,
            block: true,
            onTap: _busy
                ? null
                : () => setState(() {
                    _sent = false;
                    _error = null;
                    _code.clear();
                  }),
          ),
        ],
      ],
    );
  }
}
