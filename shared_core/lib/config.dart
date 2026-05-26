/// Embedded production config.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://yptrodblyfscyqngakie.supabase.co');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY',
      defaultValue: 'sb_publishable_aURUM8bSD1KPhH_9_dgaXw_MZbGfb1r');

  /// OpenRouter for AI diagnosis. INJECTED at build time, never committed.
  static const openRouterKey = String.fromEnvironment('OPENROUTER_KEY', defaultValue: '');

  /// Verified working free models on OpenRouter.
  static const openRouterModel = String.fromEnvironment('OPENROUTER_MODEL',
      defaultValue: 'openai/gpt-oss-120b:free');

  /// Backup if primary is rate-limited.
  static const openRouterBackupModel = 'meta-llama/llama-3.3-70b-instruct:free';
}
