class AppConstants {
  // Değerler --dart-define-from-file=.env.json ile enjekte edilir.
  // .env.json dosyası git'e eklenmez (bkz. .gitignore).
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
