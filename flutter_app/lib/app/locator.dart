import 'package:get_it/get_it.dart';

import '../core/repository/demo_repository.dart';
import '../core/repository/repository.dart';

/// Dependency injection — the Flutter equivalent of the Swift app's single
/// `@Environment(AppSession)` global plus repository injection. The concrete
/// [Repository] is chosen in `main()` (Demo offline vs Supabase backend);
/// nothing else in the app references a concrete repository.
final getIt = GetIt.instance;

/// Registers the app-wide [Repository]. Pass [repository] to inject the
/// Supabase-backed implementation; omit it to use the offline [DemoRepository].
void configureDependencies({Repository? repository}) {
  if (getIt.isRegistered<Repository>()) return;
  getIt.registerLazySingleton<Repository>(() => repository ?? DemoRepository());
}
