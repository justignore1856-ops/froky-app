import '../model/settings_model/settings_model.dart';

/// Modified singleton for managing settings data.
class SettingsData {
  static final SettingsData _instance = SettingsData._internal();

  static SettingsData get instance => _instance;

  factory SettingsData() {
    return _instance;
  }

  SettingsData._internal();

  SystemSettings? system;
  StorageSettings? storage;
  EmailSettings? email;
  PaymentSettings? payment;
  AuthenticationSettings? authentication;
  NotificationSettings? notification;
  WebSettings? web;
  AppSettings? app;
  DeliveryBoySettings? deliveryBoy;
  AdvertisementSettings? advertisement;
  MarketsSettings? markets;
  WatchAndBuy? watchAndBuy;


  void setSettingsData(List<SettingsApiModel> data) {
    for (final item in data) {
      final valueJson = item.value as Map<String, dynamic>;
      switch (item.variable) {
        case 'system':
          system = SystemSettings.fromJson(valueJson);
          break;
        case 'storage':
          storage = StorageSettings.fromJson(valueJson);
          break;
        case 'email':
          email = EmailSettings.fromJson(valueJson);
          break;
        case 'payment':
          payment = PaymentSettings.fromJson(valueJson);
          break;
        case 'authentication':
          authentication = AuthenticationSettings.fromJson(valueJson);
          break;
        case 'notification':
          notification = NotificationSettings.fromJson(valueJson);
          break;
        case 'web':
          web = WebSettings.fromJson(valueJson);
          break;
        case 'app':
          app = AppSettings.fromJson(valueJson);
          break;
        case 'delivery_boy':
          deliveryBoy = DeliveryBoySettings.fromJson(valueJson);
          break;
        case 'advertisement':
          advertisement = AdvertisementSettings.fromJson(valueJson);
          break;
        case 'markets':
          markets = MarketsSettings.fromJson(valueJson);
          break;
        case 'watch_and_buy':
        case 'watchAndBuy':
        case 'watch_buy':
        case 'watchBuy':
          watchAndBuy = WatchAndBuy.fromJson(valueJson);
          break;
      }
    }
  }

  void clear() {
    system = null;
    storage = null;
    email = null;
    payment = null;
    authentication = null;
    notification = null;
    web = null;
    app = null;
    deliveryBoy = null;
    advertisement = null;
    markets = null;
    watchAndBuy = null;
  }
}