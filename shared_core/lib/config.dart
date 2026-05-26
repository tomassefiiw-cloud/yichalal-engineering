/// Embedded production config.
/// Values come from --dart-define at build time. The GitHub Actions workflow
/// passes the OpenRouter key at build time (kept in workflow env, never committed).
/// Supabase URL + publishable key are safe to inline (publishable keys are
/// designed to ship to clients).
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://mfnoyegiuuwthygprjua.supabase.co');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY',
      defaultValue: 'sb_publishable_eDkeKLLqtUKeqKGKGsQVGA_BkcXKz5U');

  /// OpenRouter for AI diagnosis. INJECTED at build time, never committed.
  /// If you build locally without -–dart-define=OPENROUTER_KEY=..., AI falls
  /// back to the local rule engine (works fully offline).
  static const openRouterKey = String.fromEnvironment('OPENROUTER_KEY', defaultValue: '');

  /// Working free model on OpenRouter (verified responding).
  static const openRouterModel = String.fromEnvironment('OPENROUTER_MODEL',
      defaultValue: 'openai/gpt-oss-120b:free');

  /// Backup model if primary is rate-limited.
  static const openRouterBackupModel = 'liquid/lfm-2.5-1.2b-instruct:free';
}
