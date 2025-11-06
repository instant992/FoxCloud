#ifndef NOTIFICATION_PLUGIN_H_
#define NOTIFICATION_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <set>
#include <string>

namespace flowvy_notification {

class NotificationPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  NotificationPlugin();
  virtual ~NotificationPlugin();

  NotificationPlugin(const NotificationPlugin&) = delete;
  NotificationPlugin& operator=(const NotificationPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void ShowProgressNotification(
      const std::string& tag,
      const std::string& title,
      const std::string& status,
      double progress);

  void ShowTrafficLimitNotification(
      const std::string& tag,
      const std::string& title,
      int percentage,
      const std::string& status);

  void ShowSubscriptionExpiryNotification(
      const std::string& tag,
      const std::string& title,
      const std::string& body,
      const std::string& buttonText,
      const std::string& buttonUrl);

  void CancelNotification(const std::string& tag);

  std::set<std::string> active_notifications_;
  uint32_t sequence_number_ = 0;
};

}  // namespace flowvy_notification

#endif  // NOTIFICATION_PLUGIN_H_
