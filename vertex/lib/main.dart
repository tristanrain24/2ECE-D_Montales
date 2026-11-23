import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'services/services.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Inter',
    ], await rootBundle.loadString('assets/fonts/Inter-LICENSE.txt'));
    yield LicenseEntryWithLineBreaks([
      'Phosphor Icons',
    ], await rootBundle.loadString('assets/fonts/Phosphor-LICENSE.txt'));
  });

  final catalogs = CatalogSource(
    cache: const PrefsStorage('vertex.catalog.v1'),
  );
  final state = await AppState.load(
    catalog: await catalogs.initial(),
    storage: const PrefsStorage(),
  );
  runApp(VertexApp(state: state));

  // Pick up re-scored ratings without delaying start-up.
  final latest = await catalogs.refresh();
  if (latest != null) state.replaceCatalog(latest);
}
