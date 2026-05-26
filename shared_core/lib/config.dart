/// Embedded production config.
/// Sensitive values come from `--dart-define` at build time so they never
/// end up in the public repo. The Github Actions workflow injects them.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://mfnoyegiuuwthygprjua.supabase.co');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY',
      defaultValue: 'sb_publishable_eDkeKLLqtUKeqKGKGsQVGA_BkcXKz5U');

  /// OpenRouter (DeepSeek) for AI diagnosis
  static const openRouterKey = String.fromEnvironment('OPENROUTER_KEY', defaultValue: '');
  static const openRouterModel = String.fromEnvironment('OPENROUTER_MODEL',
      defaultValue: 'deepseek/deepseek-chat-v3-0324:free');
}
