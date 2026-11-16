import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/models.dart';
import '../../logic/format.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../sheets.dart';
import '../widgets/widgets.dart';
import 'browse.dart';
import 'checkout.dart';
import 'review.dart';

const appVersion = '1.0.0';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.vx;
    final st = s.student;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Kicker(text),
    );

    Widget statusTag(Purchase p) => p.isActive
        ? const VxTag('Active', kind: VxTagKind.accent)
        : const VxTag('Cancelled');

    return ListView(
      padding: pagePadding,
      children: [
        label('Purchases'),
        if (s.purchases.isEmpty)
          VxCard(
            child: Text(
              'No plans yet. When you get a tool through Vertex, its plan and '
              'licence key live here.',
              style: VxText.secondary(context),
            ),
          )
        else
          VxGroup(
            children: [
              for (final p in s.purchases)
                VxRow(
                  title:
                      '${s.catalog.tool(p.toolId)?.name ?? p.toolId} · ${p.planName}',
                  subtitle: p.isActive
                      ? '${p.amountCents == 0 ? 'Free' : '${fmtCents(p.amountCents)}/${periodLabel(p.billing)}'} · renews ${fmtDate(p.renewsAt)}'
                      : 'Access until ${fmtDate(p.renewsAt)}',
                  trailing: statusTag(p),
                  chevron: true,
                  onTap: () => showPurchaseSheet(context, p),
                ),
            ],
          ),

        label('Student status'),
        VxGroup(
          children: [
            if (s.studentVerified && st != null)
              VxRow(
                leading: Icon(PhFill.sealCheck, size: 22, color: c.accentFg),
                title: 'Verified',
                subtitle: '${st.domain} · renews ${fmtDate(st.expiresAt)}',
                chevron: true,
                onTap: () => showStudentVerifySheet(context),
              )
            else
              VxRow(
                leading: Icon(Ph.student, size: 22, color: c.textSecondary),
                title: st == null ? 'Not verified' : 'Verification expired',
                subtitle: 'Verify a school email to unlock student pricing',
                chevron: true,
                onTap: () => showStudentVerifySheet(context),
              ),
          ],
        ),

        label('Your reviews'),
        if (s.reviews.isEmpty)
          VxCard(
            child: Text(
              'You haven’t reviewed anything yet. Open a tool and tell the '
              'desk how it went.',
              style: VxText.secondary(context),
            ),
          )
        else
          VxGroup(
            children: [
              for (final r in s.reviews) ReviewRow(review: r, showTool: true),
            ],
          ),

        label('Preferences'),
        VxGroup(
          children: [
            VxRow(
              leading: Icon(
                fieldIcon(s.field.icon),
                size: 20,
                color: c.textSecondary,
              ),
              title: 'Field',
              subtitle: s.field.name,
              chevron: true,
              onTap: () => _pickField(context),
            ),
            VxRow(
              leading: Icon(
                s.role == null ? Ph.user : roleIcon(s.role!),
                size: 20,
                color: c.textSecondary,
              ),
              title: 'Who’s asking',
              subtitle: s.role?.label ?? 'Not set — we lead with list prices',
              chevron: true,
              onTap: () => _pickRole(context),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Appearance', style: VxText.title(context)),
                  const SizedBox(height: 10),
                  VxSegmented<ThemeMode>(
                    options: const {
                      ThemeMode.system: 'System',
                      ThemeMode.light: 'Light',
                      ThemeMode.dark: 'Dark',
                    },
                    value: s.themeMode,
                    onChanged: s.setThemeMode,
                  ),
                ],
              ),
            ),
          ],
        ),

        label('About'),
        VxGroup(
          children: [
            VxRow(
              title: 'How we rate',
              subtitle: 'Tiers, metrics and how Vertex makes money',
              chevron: true,
              onTap: () => s.push(const MethodPage()),
            ),
            VxRow(
              title: 'Replay the intro',
              chevron: true,
              onTap: s.replayIntro,
            ),
            VxRow(
              title: 'Open-source licences',
              chevron: true,
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Vertex',
                applicationVersion: appVersion,
              ),
            ),
            VxRow(
              title: 'Reset app data',
              subtitle: 'Clears plans, reviews, saved tools and settings',
              chevron: true,
              onTap: () async {
                final ok = await confirmVx(
                  context,
                  title: 'Reset Vertex?',
                  message:
                      'This removes your plans, licence keys, reviews, saved '
                      'tools, student status and settings from this device. '
                      'It can’t be undone.',
                  confirmLabel: 'Reset everything',
                  destructive: true,
                );
                if (ok) await s.resetAll();
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'Vertex $appVersion · catalog ${s.catalog.lastFullPass}',
            style: VxText.muted(context, size: 11.5),
          ),
        ),
      ],
    );
  }

  static Future<void> _pickField(BuildContext context) =>
      showVxBottomSheet<void>(context, (ctx) {
        final s = AppScope.of(ctx);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your field', style: VxText.display(ctx, size: 21)),
            const SizedBox(height: 14),
            VxGroup(
              children: [
                for (final f in s.catalog.fields)
                  VxRow(
                    leading: Icon(
                      fieldIcon(f.icon),
                      size: 20,
                      color: f.id == s.field.id
                          ? ctx.vx.accentFg
                          : ctx.vx.textSecondary,
                    ),
                    title: f.name,
                    trailing: f.id == s.field.id
                        ? Icon(Ph.check, size: 17, color: ctx.vx.accentFg)
                        : null,
                    onTap: () {
                      s.setField(f.id);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ],
        );
      });

  static Future<void> _pickRole(BuildContext context) =>
      showVxBottomSheet<void>(context, (ctx) {
        final s = AppScope.of(ctx);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Who’s asking?', style: VxText.display(ctx, size: 21)),
            const SizedBox(height: 4),
            Text(
              'This changes which price we lead with. It never changes a tier.',
              style: VxText.secondary(ctx),
            ),
            const SizedBox(height: 14),
            VxGroup(
              children: [
                for (final r in Role.values)
                  VxRow(
                    leading: Icon(
                      roleIcon(r),
                      size: 20,
                      color: r == s.role
                          ? ctx.vx.accentFg
                          : ctx.vx.textSecondary,
                    ),
                    title: r.label,
                    subtitle: r.note,
                    trailing: r == s.role
                        ? Icon(Ph.check, size: 17, color: ctx.vx.accentFg)
                        : null,
                    onTap: () {
                      s.setRole(r);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ],
        );
      });
}

Future<void> showPurchaseSheet(
  BuildContext context,
  Purchase purchase,
) => showVxBottomSheet<void>(context, (ctx) {
  final s = AppScope.of(ctx);
  // Re-read so the sheet reflects a cancellation made while it is open.
  final p = s.purchaseFor(purchase.toolId) ?? purchase;
  final tool = s.catalog.tool(p.toolId);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              '${tool?.name ?? p.toolId} · ${p.planName}',
              style: VxText.display(ctx, size: 21),
            ),
          ),
          p.isActive
              ? const VxTag('Active', kind: VxTagKind.accent)
              : const VxTag('Cancelled'),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        [
          if (p.amountCents == 0)
            'Free plan'
          else
            '${fmtCents(p.amountCents)} per ${p.billing == Billing.monthly ? 'month' : 'year'}',
          if (p.seats > 1) '${p.seats} seats',
          if (p.amountCents > 0) p.method,
          p.isActive
              ? 'renews ${fmtDate(p.renewsAt)}'
              : 'access until ${fmtDate(p.renewsAt)}',
        ].join(' · '),
        style: VxText.secondary(ctx),
      ),
      const SizedBox(height: 16),
      LicenceKeyCard(licenceKey: p.licenceKey),
      const SizedBox(height: 12),
      VxButton(
        'Copy licence key',
        icon: Ph.copy,
        block: true,
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: p.licenceKey));
          s.flash('Licence key copied');
        },
      ),
      if (tool != null) ...[
        const SizedBox(height: 8),
        VxButton(
          p.isActive ? 'Change plan' : 'Resubscribe',
          block: true,
          kind: p.isActive ? VxButtonKind.secondary : VxButtonKind.primary,
          onTap: () {
            final nav = Navigator.of(ctx, rootNavigator: true);
            nav.pop();
            showCheckout(nav.context, tool);
          },
        ),
      ],
      if (p.isActive) ...[
        const SizedBox(height: 8),
        VxButton(
          'Cancel subscription',
          kind: VxButtonKind.danger,
          block: true,
          onTap: () async {
            final ok = await confirmVx(
              ctx,
              title: 'Cancel ${tool?.name ?? 'this plan'}?',
              message:
                  'You keep access until ${fmtDate(p.renewsAt)} and '
                  'won’t be charged again.',
              confirmLabel: 'Cancel subscription',
              destructive: true,
            );
            if (ok) s.cancelPurchase(p.toolId);
          },
        ),
      ],
    ],
  );
});
