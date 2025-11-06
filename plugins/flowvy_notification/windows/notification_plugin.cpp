#include "notification_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>
#include <winrt/Windows.Data.Xml.Dom.h>
#include <winrt/Windows.UI.Notifications.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>

#include <memory>
#include <sstream>
#include <iomanip>
#include <set>

using namespace winrt;
using namespace winrt::Windows::Data::Xml::Dom;
using namespace winrt::Windows::UI::Notifications;
using namespace winrt::Windows::Foundation::Collections;
using winrt::Windows::UI::Notifications::NotificationUpdateResult;

namespace flowvy_notification {

namespace {
hstring Utf8ToHstring(const std::string& str) {
  int size_needed = MultiByteToWideChar(CP_UTF8, 0, str.c_str(), (int)str.size(), NULL, 0);
  std::wstring wstr(size_needed, 0);
  MultiByteToWideChar(CP_UTF8, 0, str.c_str(), (int)str.size(), &wstr[0], size_needed);
  return hstring{wstr};
}

std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel = nullptr;
}  // namespace

void NotificationPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "flowvy_notification",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<NotificationPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

NotificationPlugin::NotificationPlugin() {
  try {
    winrt::init_apartment();
  } catch (...) {
  }
}

NotificationPlugin::~NotificationPlugin() {}

void NotificationPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name() == "showProgress") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENT", "Arguments must be a map");
      return;
    }

    std::string tag, title, status;
    double progress = 0.0;

    auto tag_it = arguments->find(flutter::EncodableValue("tag"));
    if (tag_it != arguments->end()) {
      tag = std::get<std::string>(tag_it->second);
    }

    auto title_it = arguments->find(flutter::EncodableValue("title"));
    if (title_it != arguments->end()) {
      title = std::get<std::string>(title_it->second);
    }

    auto status_it = arguments->find(flutter::EncodableValue("status"));
    if (status_it != arguments->end()) {
      status = std::get<std::string>(status_it->second);
    }

    auto progress_it = arguments->find(flutter::EncodableValue("progress"));
    if (progress_it != arguments->end()) {
      progress = std::get<double>(progress_it->second);
    }

    ShowProgressNotification(tag, title, status, progress);
    result->Success();
  } else if (method_call.method_name() == "cancel") {

    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENT", "Arguments must be a map");
      return;
    }

    std::string tag;
    auto tag_it = arguments->find(flutter::EncodableValue("tag"));
    if (tag_it != arguments->end()) {
      tag = std::get<std::string>(tag_it->second);
    }

    CancelNotification(tag);
    result->Success();
  } else if (method_call.method_name() == "showTrafficLimit") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENT", "Arguments must be a map");
      return;
    }

    std::string tag, title, status;
    int percentage = 0;

    auto tag_it = arguments->find(flutter::EncodableValue("tag"));
    if (tag_it != arguments->end()) {
      tag = std::get<std::string>(tag_it->second);
    }

    auto title_it = arguments->find(flutter::EncodableValue("title"));
    if (title_it != arguments->end()) {
      title = std::get<std::string>(title_it->second);
    }

    auto percentage_it = arguments->find(flutter::EncodableValue("percentage"));
    if (percentage_it != arguments->end()) {
      percentage = std::get<int>(percentage_it->second);
    }

    auto status_it = arguments->find(flutter::EncodableValue("status"));
    if (status_it != arguments->end()) {
      status = std::get<std::string>(status_it->second);
    }

    ShowTrafficLimitNotification(tag, title, percentage, status);
    result->Success();
  } else if (method_call.method_name() == "showSubscriptionExpiry") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENT", "Arguments must be a map");
      return;
    }

    std::string tag, title, body, buttonText, buttonUrl;

    auto tag_it = arguments->find(flutter::EncodableValue("tag"));
    if (tag_it != arguments->end()) {
      tag = std::get<std::string>(tag_it->second);
    }

    auto title_it = arguments->find(flutter::EncodableValue("title"));
    if (title_it != arguments->end()) {
      title = std::get<std::string>(title_it->second);
    }

    auto body_it = arguments->find(flutter::EncodableValue("body"));
    if (body_it != arguments->end()) {
      body = std::get<std::string>(body_it->second);
    }

    auto buttonText_it = arguments->find(flutter::EncodableValue("buttonText"));
    if (buttonText_it != arguments->end()) {
      buttonText = std::get<std::string>(buttonText_it->second);
    }

    auto buttonUrl_it = arguments->find(flutter::EncodableValue("buttonUrl"));
    if (buttonUrl_it != arguments->end()) {
      buttonUrl = std::get<std::string>(buttonUrl_it->second);
    }

    ShowSubscriptionExpiryNotification(tag, title, body, buttonText, buttonUrl);
    result->Success();
  } else {
    result->NotImplemented();
  }
}

void NotificationPlugin::ShowProgressNotification(
    const std::string& tag,
    const std::string& title,
    const std::string& status,
    double progress) {

  bool isUpdate = active_notifications_.count(tag) > 0;

  try {
    std::wstring titleWide = Utf8ToHstring(title).c_str();
    std::wstring statusWide = Utf8ToHstring(status).c_str();

    std::wstringstream progressValueStream;
    progressValueStream << std::fixed << std::setprecision(2) << progress;
    std::wstring progressValueStr = progressValueStream.str();

    std::wstringstream progressPercentStream;
    progressPercentStream << std::fixed << std::setprecision(0) << (progress * 100) << L"%";
    std::wstring progressPercentStr = progressPercentStream.str();

    // XML with data binding using standard Microsoft property names
    std::wstring toastXml = L"<toast>\n"
                            L"  <visual>\n"
                            L"    <binding template=\"ToastGeneric\">\n"
                            L"      <text>{progressTitle}</text>\n"
                            L"      <progress value=\"{progressValue}\" valueStringOverride=\"{progressValueString}\" status=\"{progressStatus}\" />\n"
                            L"    </binding>\n"
                            L"  </visual>\n"
                            L"  <audio silent=\"true\"/>\n"
                            L"</toast>";

    XmlDocument doc;
    doc.LoadXml(toastXml);

    ToastNotification toast(doc);
    toast.Tag(Utf8ToHstring(tag));
    toast.Group(L"downloads");

    NotificationData data;
    data.SequenceNumber(isUpdate ? ++sequence_number_ : 1);

    IMap<hstring, hstring> values = data.Values();
    values.Insert(L"progressTitle", titleWide);
    values.Insert(L"progressValue", progressValueStr);
    values.Insert(L"progressValueString", progressPercentStr);
    values.Insert(L"progressStatus", statusWide);

    auto notifier = ToastNotificationManager::CreateToastNotifier(L"Flowvy.App");

    if (isUpdate) {
      auto updateResult = notifier.Update(data, Utf8ToHstring(tag), L"downloads");
      if (updateResult == NotificationUpdateResult::NotificationNotFound) {
        toast.Data(data);
        notifier.Show(toast);
        active_notifications_.insert(tag);
      }
    } else {
      toast.Data(data);
      notifier.Show(toast);
      active_notifications_.insert(tag);
      sequence_number_ = 1;
    }
  } catch (...) {
  }
}

void NotificationPlugin::ShowTrafficLimitNotification(
    const std::string& tag,
    const std::string& title,
    int percentage,
    const std::string& status) {

  try {
    std::wstring titleWide = Utf8ToHstring(title).c_str();
    std::wstring statusWide = Utf8ToHstring(status).c_str();

    std::wstringstream progressValueStream;
    progressValueStream << std::fixed << std::setprecision(2) << (percentage / 100.0);
    std::wstring progressValueStr = progressValueStream.str();

    std::wstringstream progressPercentStream;
    progressPercentStream << std::fixed << std::setprecision(0) << percentage << L"%";
    std::wstring progressPercentStr = progressPercentStream.str();

    std::wstring toastXml = L"<toast>\n"
                            L"  <visual>\n"
                            L"    <binding template=\"ToastGeneric\">\n"
                            L"      <text>{progressTitle}</text>\n"
                            L"      <progress value=\"{progressValue}\" valueStringOverride=\"{progressValueString}\" status=\"{progressStatus}\" />\n"
                            L"    </binding>\n"
                            L"  </visual>\n"
                            L"  <audio src=\"ms-winsoundevent:Notification.Default\"/>\n"
                            L"</toast>";

    XmlDocument doc;
    doc.LoadXml(toastXml);

    ToastNotification toast(doc);
    toast.Tag(Utf8ToHstring(tag));
    toast.Group(L"traffic");

    NotificationData data;
    data.SequenceNumber(1);

    IMap<hstring, hstring> values = data.Values();
    values.Insert(L"progressTitle", titleWide);
    values.Insert(L"progressValue", progressValueStr);
    values.Insert(L"progressValueString", progressPercentStr);
    values.Insert(L"progressStatus", statusWide);

    toast.Data(data);

    auto notifier = ToastNotificationManager::CreateToastNotifier(L"Flowvy.App");
    notifier.Show(toast);
  } catch (...) {
  }
}

void NotificationPlugin::ShowSubscriptionExpiryNotification(
    const std::string& tag,
    const std::string& title,
    const std::string& body,
    const std::string& buttonText,
    const std::string& buttonUrl) {

  try {
    std::wstring titleWide = Utf8ToHstring(title).c_str();
    std::wstring bodyWide = Utf8ToHstring(body).c_str();

    std::wstring actionsSection = L"";
    if (!buttonUrl.empty() && !buttonText.empty()) {
      std::wstring buttonTextWide = Utf8ToHstring(buttonText).c_str();
      std::wstring buttonUrlWide = Utf8ToHstring(buttonUrl).c_str();

      // Escape XML special characters in button attributes
      auto escapeForAttribute = [](const std::wstring& str) -> std::wstring {
        std::wstring result = str;
        size_t pos = 0;
        while ((pos = result.find(L"&", pos)) != std::wstring::npos) {
          result.replace(pos, 1, L"&amp;");
          pos += 5;
        }
        pos = 0;
        while ((pos = result.find(L"\"", pos)) != std::wstring::npos) {
          result.replace(pos, 1, L"&quot;");
          pos += 6;
        }
        pos = 0;
        while ((pos = result.find(L"<", pos)) != std::wstring::npos) {
          result.replace(pos, 1, L"&lt;");
          pos += 4;
        }
        pos = 0;
        while ((pos = result.find(L">", pos)) != std::wstring::npos) {
          result.replace(pos, 1, L"&gt;");
          pos += 4;
        }
        return result;
      };

      std::wstring buttonTextEscaped = escapeForAttribute(buttonTextWide);
      std::wstring buttonUrlEscaped = escapeForAttribute(buttonUrlWide);

      actionsSection = L"  <actions>\n"
                       L"    <action content=\"" + buttonTextEscaped + L"\" arguments=\"" + buttonUrlEscaped + L"\" activationType=\"protocol\"/>\n"
                       L"  </actions>\n";
    }

    std::wstring toastXml = L"<toast>\n"
                            L"  <visual>\n"
                            L"    <binding template=\"ToastGeneric\">\n"
                            L"      <text>{titleText}</text>\n"
                            L"      <text>{bodyText}</text>\n"
                            L"    </binding>\n"
                            L"  </visual>\n"
                            + actionsSection +
                            L"  <audio src=\"ms-winsoundevent:Notification.Default\"/>\n"
                            L"</toast>";

    XmlDocument doc;
    doc.LoadXml(toastXml);

    ToastNotification toast(doc);
    toast.Tag(Utf8ToHstring(tag));
    toast.Group(L"subscription");

    NotificationData data;
    data.SequenceNumber(1);

    IMap<hstring, hstring> values = data.Values();
    values.Insert(L"titleText", titleWide);
    values.Insert(L"bodyText", bodyWide);

    toast.Data(data);

    auto notifier = ToastNotificationManager::CreateToastNotifier(L"Flowvy.App");
    notifier.Show(toast);
  } catch (...) {
  }
}

void NotificationPlugin::CancelNotification(const std::string& tag) {
  try {
    ToastNotificationManager::History().Remove(Utf8ToHstring(tag), L"downloads");
    active_notifications_.erase(tag);
  } catch (...) {
  }
}

}  // namespace flowvy_notification
