/// Prevents accidental instantiation.
/// Only groups constant values of the app.
class AppConstants {
  AppConstants._();

  // Default MQTT
  static const String mqttServer = 'broker.triplecyber.com';
  static const int mqttPort = 1883;
  static const int keepAlive = 30;

  // Other services
  static const String appName = 'flutter_rtc_call';
  static const String topicPrefix = 'flutter_rtc_call';
}
