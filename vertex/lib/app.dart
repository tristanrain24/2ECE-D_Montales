import 'package:material_ui/material_ui.dart';

import 'state/app_state.dart';
import 'theme/tokens.dart';
import 'ui/router.dart';
import 'ui/screens/onboarding.dart';
import 'ui/shell.dart';

class VertexApp extends StatefulWidget {
  const VertexApp({super.key, required this.state});
  final AppState state;

  @override
  State<VertexApp> createState() => _VertexAppState();
}

class _VertexAppState extends State<VertexApp> {
  late final _router = VxRouterDelegate(
    state: widget.state,
    home: const _Root(),
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScope(
    state: widget.state,
    child: ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) => MaterialApp.router(
        title: 'Vertex',
        debugShowCheckedModeBanner: false,
        theme: buildVxTheme(Brightness.light),
        darkTheme: buildVxTheme(Brightness.dark),
        themeMode: widget.state.themeMode,
        routerDelegate: _router,
        routeInformationParser: const VxRouteParser(),
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(textScaler: VxTextScaler(mq.textScaler)),
            child: child!,
          );
        },
      ),
    ),
  );
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final intro = AppScope.of(context).inIntro;
    return AnimatedSwitcher(
      duration: vxMotion(context, 280),
      child: intro
          ? const Onboarding(key: ValueKey('intro'))
          : const Shell(key: ValueKey('shell')),
    );
  }
}
