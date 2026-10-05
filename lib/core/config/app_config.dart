/// Runtime configuration, injected at build time with `--dart-define`.
///
/// flutter run --dart-define=API_BASE_URL=https://api.example.com
///             --dart-define=REALTIME_TRANSPORT=sse
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.realtimePath,
    required this.webSocketUrl,
    required this.transport,
    required this.appName,
  });

  factory AppConfig.fromEnvironment() {
    const transportName = String.fromEnvironment('REALTIME_TRANSPORT', defaultValue: 'sse');
    return AppConfig(
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://elyvori-api.onrender.com',
      ),
      realtimePath: const String.fromEnvironment('REALTIME_PATH', defaultValue: '/realtime/stream'),
      webSocketUrl: const String.fromEnvironment('WS_URL', defaultValue: ''),
      transport: transportName == 'websocket' ? RealtimeTransport.webSocket : RealtimeTransport.sse,
      appName: const String.fromEnvironment('APP_NAME', defaultValue: 'Elyvori Pay'),
    );
  }

  final String apiBaseUrl;
  final String realtimePath;
  final String webSocketUrl;
  final RealtimeTransport transport;
  final String appName;

  Uri get realtimeUri => transport == RealtimeTransport.webSocket && webSocketUrl.isNotEmpty
      ? Uri.parse(webSocketUrl)
      : Uri.parse('$apiBaseUrl$realtimePath');
}

enum RealtimeTransport { sse, webSocket }
