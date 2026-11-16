import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/desktop_edit_store.dart';

/// Local desktop-editing state. Separate from the controller so the export service can read it without a cycle.
final desktopEditStoreProvider = Provider<DesktopEditStore>((ref) => DesktopEditStore());
