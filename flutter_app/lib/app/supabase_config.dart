/// Supabase connection config — Flutter counterpart of App/SupabaseConfig.swift.
///
/// The anon (publishable) key is RLS-gated and safe to embed client-side, per
/// Supabase docs — the same key the Swift app commits. Override any of these
/// at build/run time with --dart-define, e.g.
///   flutter run --dart-define=USE_SUPABASE=true
///   flutter run --dart-define=USE_SUPABASE=true \
///     --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// [enabled] defaults to false so the offline [DemoRepository] stays the safe
/// default (no network on launch, tests untouched). Flip it on to run the app
/// against the live Postgres backend.
abstract class SupabaseConfig {
  static const bool enabled =
      bool.fromEnvironment('USE_SUPABASE', defaultValue: false);

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://khsmwnkitvutcuhypfcz.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtoc213bmtpdHZ1dGN1aHlwZmN6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcyNzUzNDcsImV4cCI6MjA5Mjg1MTM0N30.ZXzw5JmmaGqm8NLurO1pHBBDufmBlYJ8gQnWNVeESCI',
  );

  /// True only when the backend is enabled and both values are non-empty.
  static bool get isConfigured =>
      enabled && url.isNotEmpty && anonKey.isNotEmpty;
}
