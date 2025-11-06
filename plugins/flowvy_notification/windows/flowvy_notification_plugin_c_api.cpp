#include "include/flowvy_notification/flowvy_notification_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "notification_plugin.h"

void FlowvyNotificationPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flowvy_notification::NotificationPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
