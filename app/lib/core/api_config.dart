/// Single source of truth for the backend location.
///
/// Change ONLY this value when your Mac's LAN IP changes (it can change
/// whenever you reconnect to Wi-Fi). Find your current IP by running, in
/// Terminal on the Mac running the FastAPI server:
///
///   ipconfig getifaddr en0
///
/// Rules of thumb:
///   - Physical phone/tablet on the same Wi-Fi -> http://<mac-lan-ip>:8000
///   - Android emulator                        -> http://10.0.2.2:8000
///   - iOS simulator                            -> http://localhost:8000
///   - Deployed backend                         -> https://your-domain.com
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://192.168.18.19:8000';

  /// Network calls longer than this are treated as failed. Keeps the UI
  /// from spinning forever if the phone can't reach the server.
  static const Duration requestTimeout = Duration(seconds: 12);
}
