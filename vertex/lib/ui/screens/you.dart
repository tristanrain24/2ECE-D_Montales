import 'package:material_ui/material_ui.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../sheets.dart';
import '../widgets/widgets.dart';
import 'browse.dart';
import 'review.dart';

const appVersion = '1.0.0';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = context.vx;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Kicker(text),
    );

    return ListView(
      padding: pagePadding,
      children: [
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
              subtitle: 'Clears reviews, saved tools and settings',
              chevron: true,
              onTap: () async {
                final ok = await confirmVx(
                  context,
                  title: 'Reset Vertex?',
                  message:
                      'This removes your reviews, saved tools, compare list '
                      'and settings from this device. '
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
