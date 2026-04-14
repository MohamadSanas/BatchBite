/// Backend base URL. Override at build time, e.g.:
/// `flutter run --dart-define=API_BASE=http://10.0.2.2:8000` (Android emulator)
const String kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://127.0.0.1:8000',
);
