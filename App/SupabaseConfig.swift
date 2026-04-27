import Foundation

/// Compile-time Supabase configuration. Values committed here are read by
/// `SHJSDSCApp.makeRepository` as the primary source; if either is empty the
/// app falls back to `Bundle.main` (xcconfig path) and then to the offline
/// `DemoRepository`.
///
/// The publishable key is intended for client-side embedding per Supabase
/// docs — it's gated by RLS policies on the server. Never commit a
/// `service_role` key here; that one bypasses RLS.
enum SupabaseConfig {
    static let url: String = "https://khsmwnkitvutcuhypfcz.supabase.co"
    static let anonKey: String = "sb_publishable_ug1qr-7dKQrTITNZXibEWw__OShuxOH"
}
