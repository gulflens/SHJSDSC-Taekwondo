import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/locator.dart';
import 'app/supabase_config.dart';
import 'core/repository/supabase_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    // Backend mode — initialise Supabase and inject the network repository.
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    configureDependencies(
      repository: SupabaseRepository(Supabase.instance.client),
    );
  } else {
    // Default: offline demo seed.
    configureDependencies();
  }

  runApp(const ShjsdscApp());
}
