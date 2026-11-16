import 'package:material_ui/material_ui.dart';

import 'state/app_state.dart';
import 'theme/tokens.dart';
import 'ui/screens/onboarding.dart';
import 'ui/shell.dart';

class VertexApp extends StatelessWidget {
  const VertexApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => AppScope(
    state: state,
    child: ListenableBuilder(
      listenable: state,
      builder: (context, _) => MaterialApp(
        title: 'Vertex',
        debugShowCheckedModeBanner: false,
        theme: buildVxTheme(Brightness.light),
        darkTheme: buildVxTheme(Brightness.dark),
        themeMode: state.themeMode,
        home: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: state.inIntro
              ? const Onboarding(key: ValueKey('intro'))
              : const Shell(key: ValueKey('shell')),
        ),
      ),
    ),
  );
}
