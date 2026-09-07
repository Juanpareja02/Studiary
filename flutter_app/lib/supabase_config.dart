/// Configuración pública del cliente Supabase.
///
/// Estos valores se inyectan al compilar con `--dart-define`. La clave
/// publishable/anon está diseñada para vivir en una app cliente; nunca pongas
/// aquí una clave `secret` o `service_role`.
class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured =>
      url.startsWith('https://') && publishableKey.isNotEmpty;
}
