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
  final state = await AppState.load(
    catalog: await const BundledCatalogSource().load(),
    storage: PrefsStorage(),
    // Replace these two with production services before taking real payments
    // or sending real verification email. See README → "Going live".
    payments: DemoPaymentGateway(),
    verifier: DemoStudentVerifier(),
  );
  runApp(VertexApp(state: state));
}
