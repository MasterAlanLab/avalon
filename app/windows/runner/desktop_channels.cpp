#include "desktop_channels.h"

#include <flutter/standard_method_codec.h>
#include <shlobj.h>
#include <shobjidl.h>
#include <wrl/client.h>
#include <wininet.h>

#include <algorithm>
#include <array>
#include <cwctype>
#include <filesystem>
#include <map>
#include <string>
#include <vector>

namespace {
using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;
constexpr std::array<const char*, 3> kActions = {"toggle", "mode", "show"};
constexpr std::array<UINT, 3> kKeys = {'P', 'M', 'A'};
constexpr int kHotkeyBase = 0x4100;
std::string Utf8(const std::wstring& value);

bool ReadProxy(EncodableMap* value) {
  INTERNET_PER_CONN_OPTIONW options[4] = {};
  options[0].dwOption = INTERNET_PER_CONN_FLAGS;
  options[1].dwOption = INTERNET_PER_CONN_PROXY_SERVER;
  options[2].dwOption = INTERNET_PER_CONN_PROXY_BYPASS;
  options[3].dwOption = INTERNET_PER_CONN_AUTOCONFIG_URL;
  INTERNET_PER_CONN_OPTION_LISTW list = {};
  list.dwSize = sizeof(list);
  list.dwOptionCount = 4;
  list.pOptions = options;
  DWORD size = sizeof(list);
  const bool read = InternetQueryOptionW(
      nullptr, INTERNET_OPTION_PER_CONNECTION_OPTION, &list, &size) != FALSE;
  if (read) {
    (*value)[EncodableValue("flags")] =
        EncodableValue(static_cast<int64_t>(options[0].Value.dwValue));
    const char* keys[] = {"server", "bypass", "autoConfig"};
    for (int i = 1; i < 4; ++i) {
      const auto text = options[i].Value.pszValue;
      (*value)[EncodableValue(keys[i - 1])] =
          EncodableValue(text ? Utf8(text) : "");
    }
  }
  for (int i = 1; i < 4; ++i) {
    if (options[i].Value.pszValue) GlobalFree(options[i].Value.pszValue);
  }
  return read;
}

std::wstring Wide(const std::string& text) {
  const int size = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
      text.c_str(), static_cast<int>(text.size()), nullptr, 0);
  if (!size && !text.empty()) return {};
  std::wstring result(size, L'\0');
  MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, text.c_str(),
      static_cast<int>(text.size()), result.data(), size);
  return result;
}

bool WriteProxy(const EncodableMap& value) {
  const auto flags = value.find(EncodableValue("flags"));
  if (flags == value.end()) return false;
  int64_t bits = -1;
  if (const auto small = std::get_if<int32_t>(&flags->second)) bits = *small;
  if (const auto large = std::get_if<int64_t>(&flags->second)) bits = *large;
  if (bits < 0 || bits > 15) return false;
  std::wstring strings[3];
  const char* keys[] = {"server", "bypass", "autoConfig"};
  for (int i = 0; i < 3; ++i) {
    const auto entry = value.find(EncodableValue(keys[i]));
    if (entry == value.end()) return false;
    const auto text = std::get_if<std::string>(&entry->second);
    if (!text || text->size() > 32768 || text->find('\0') != std::string::npos) {
      return false;
    }
    strings[i] = Wide(*text);
    if (!text->empty() && strings[i].empty()) return false;
  }
  INTERNET_PER_CONN_OPTIONW options[4] = {};
  options[0].dwOption = INTERNET_PER_CONN_FLAGS;
  options[0].Value.dwValue = static_cast<DWORD>(bits);
  options[1].dwOption = INTERNET_PER_CONN_PROXY_SERVER;
  options[2].dwOption = INTERNET_PER_CONN_PROXY_BYPASS;
  options[3].dwOption = INTERNET_PER_CONN_AUTOCONFIG_URL;
  for (int i = 1; i < 4; ++i) options[i].Value.pszValue = strings[i - 1].data();
  INTERNET_PER_CONN_OPTION_LISTW list = {};
  list.dwSize = sizeof(list);
  list.dwOptionCount = 4;
  list.pOptions = options;
  if (!InternetSetOptionW(nullptr, INTERNET_OPTION_PER_CONNECTION_OPTION,
      &list, sizeof(list))) return false;
  const bool notified = InternetSetOptionW(nullptr,
      INTERNET_OPTION_SETTINGS_CHANGED, nullptr, 0) != FALSE;
  const bool refreshed = InternetSetOptionW(nullptr,
      INTERNET_OPTION_REFRESH, nullptr, 0) != FALSE;
  return notified && refreshed;
}

std::string Utf8(const std::wstring& value) {
  if (value.empty()) return {};
  const int size = WideCharToMultiByte(CP_UTF8, 0, value.c_str(),
                                       static_cast<int>(value.size()), nullptr,
                                       0, nullptr, nullptr);
  std::string result(size, '\0');
  WideCharToMultiByte(CP_UTF8, 0, value.c_str(), static_cast<int>(value.size()),
                     result.data(), size, nullptr, nullptr);
  return result;
}

std::wstring Expanded(const std::wstring& value) {
  const DWORD size = ExpandEnvironmentStringsW(value.c_str(), nullptr, 0);
  if (!size || size > 32768) return {};
  std::wstring result(size, L'\0');
  if (!ExpandEnvironmentStringsW(value.c_str(), result.data(), size)) return {};
  result.resize(size - 1);
  return result;
}

std::wstring Lower(std::wstring value) {
  std::transform(value.begin(), value.end(), value.begin(),
                 [](wchar_t c) { return static_cast<wchar_t>(std::towlower(c)); });
  return value;
}

struct App {
  std::wstring path;
  std::wstring name;
};

void AddApp(std::map<std::wstring, App>& apps, std::wstring path,
            const std::wstring& name, const std::wstring& self) {
  path = Expanded(path);
  if (path.empty() || name.empty()) return;
  std::error_code error;
  const auto file = std::filesystem::canonical(path, error);
  if (error || !std::filesystem::is_regular_file(file, error) || error ||
      Lower(file.extension().wstring()) != L".exe") {
    return;
  }
  const auto id = Lower(file.wstring());
  if (id == self) return;
  // Installer entries are not programs that should be offered for routing.
  const auto filename = Lower(file.filename().wstring());
  if (filename.find(L"unins") == 0 || filename == L"setup.exe" ||
      filename == L"msiexec.exe") {
    return;
  }
  apps.emplace(id, App{file.wstring(), name});
}

void ScanStartMenu(REFKNOWNFOLDERID folder, std::map<std::wstring, App>& apps,
                   const std::wstring& self) {
  PWSTR root = nullptr;
  if (FAILED(SHGetKnownFolderPath(folder, KF_FLAG_DEFAULT, nullptr, &root))) return;
  const std::filesystem::path directory(root);
  CoTaskMemFree(root);
  std::error_code error;
  std::filesystem::recursive_directory_iterator entries(
      directory, std::filesystem::directory_options::skip_permission_denied,
      error);
  const std::filesystem::recursive_directory_iterator end;
  while (!error && entries != end) {
    const auto path = entries->path();
    if (Lower(path.extension().wstring()) == L".lnk") {
      Microsoft::WRL::ComPtr<IShellLinkW> link;
      if (SUCCEEDED(CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER,
                                     IID_PPV_ARGS(&link)))) {
        Microsoft::WRL::ComPtr<IPersistFile> persist;
        if (SUCCEEDED(link.As(&persist)) &&
            SUCCEEDED(persist->Load(path.c_str(), STGM_READ))) {
          wchar_t target[32768] = {};
          if (SUCCEEDED(link->GetPath(target, 32768, nullptr, SLGP_RAWPATH))) {
            AddApp(apps, target, path.stem().wstring(), self);
          }
        }
      }
    }
    entries.increment(error);
  }
}

std::wstring RegistryString(HKEY key, const wchar_t* name) {
  DWORD type = 0, bytes = 0;
  if (RegQueryValueExW(key, name, nullptr, &type, nullptr, &bytes) != ERROR_SUCCESS ||
      (type != REG_SZ && type != REG_EXPAND_SZ) || bytes > 65536) {
    return {};
  }
  std::vector<wchar_t> value(bytes / sizeof(wchar_t) + 1, L'\0');
  if (RegQueryValueExW(key, name, nullptr, nullptr,
                      reinterpret_cast<BYTE*>(value.data()), &bytes) !=
      ERROR_SUCCESS) {
    return {};
  }
  return value.data();
}

void ScanRegistry(HKEY hive, REGSAM view, const wchar_t* path,
                  std::map<std::wstring, App>& apps, const std::wstring& self,
                  bool app_paths) {
  HKEY root = nullptr;
  if (RegOpenKeyExW(hive, path, 0, KEY_READ | view, &root) != ERROR_SUCCESS) return;
  for (DWORD index = 0;; ++index) {
    wchar_t name[256] = {};
    DWORD size = 256;
    const auto status = RegEnumKeyExW(root, index, name, &size, nullptr, nullptr,
                                     nullptr, nullptr);
    if (status == ERROR_NO_MORE_ITEMS) break;
    if (status != ERROR_SUCCESS) continue;
    HKEY child = nullptr;
    if (RegOpenKeyExW(root, name, 0, KEY_READ | view, &child) != ERROR_SUCCESS) {
      continue;
    }
    if (app_paths) {
      auto target = RegistryString(child, nullptr);
      if (target.size() >= 2 && target.front() == L'"' && target.back() == L'"') {
        target = target.substr(1, target.size() - 2);
      }
      AddApp(apps, target, std::filesystem::path(name).stem().wstring(), self);
    } else {
      auto label = RegistryString(child, L"DisplayName");
      auto icon = RegistryString(child, L"DisplayIcon");
      // DisplayIcon may be "path",index. Only executable paths are retained.
      if (!icon.empty() && icon.front() == L'"') {
        const auto quote = icon.find(L'"', 1);
        icon = quote == std::wstring::npos ? L"" : icon.substr(1, quote - 1);
      } else if (const auto comma = icon.rfind(L','); comma != std::wstring::npos) {
        icon.resize(comma);
      }
      AddApp(apps, icon, label, self);
    }
    RegCloseKey(child);
  }
  RegCloseKey(root);
}

EncodableList InstalledApps() {
  wchar_t executable[32768] = {};
  GetModuleFileNameW(nullptr, executable, 32768);
  std::error_code error;
  const auto own = std::filesystem::canonical(executable, error);
  const auto self = Lower(error ? std::wstring(executable) : own.wstring());
  std::map<std::wstring, App> apps;
  ScanStartMenu(FOLDERID_Programs, apps, self);
  ScanStartMenu(FOLDERID_CommonPrograms, apps, self);
  for (HKEY hive : {HKEY_CURRENT_USER, HKEY_LOCAL_MACHINE}) {
    for (REGSAM view : {KEY_WOW64_64KEY, KEY_WOW64_32KEY}) {
      ScanRegistry(hive, view,
                    L"Software\\Microsoft\\Windows\\CurrentVersion\\App Paths",
                    apps, self, true);
      ScanRegistry(hive, view,
                    L"Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall",
                    apps, self, false);
    }
  }
  EncodableList result;
  for (const auto& entry : apps) {
    result.emplace_back(EncodableMap{
        {EncodableValue("id"), EncodableValue(Utf8(entry.second.path))},
        {EncodableValue("name"), EncodableValue(Utf8(entry.second.name))},
        {EncodableValue("system"), EncodableValue(false)},
    });
  }
  return result;
}
}  // namespace

DesktopChannels::DesktopChannels(flutter::BinaryMessenger* messenger, HWND window)
    : window_(window) {
  auto codec = &flutter::StandardMethodCodec::GetInstance();
  window_channel_ =
      std::make_unique<flutter::MethodChannel<EncodableValue>>(
          messenger, "avalon/window", codec);
  hotkeys_channel_ =
      std::make_unique<flutter::MethodChannel<EncodableValue>>(
          messenger, "avalon/hotkeys", codec);
  apps_channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, "dev.avalon/apps", codec);
  proxy_channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      messenger, "avalon/system-proxy", codec);
  proxy_channel_->SetMethodCallHandler([](const auto& call, auto result) {
    if (call.method_name() == "read") {
      EncodableMap value;
      if (ReadProxy(&value)) result->Success(EncodableValue(value));
      else result->Error("system_proxy", "The system proxy settings could not be read");
    } else if (call.method_name() == "write") {
      const auto value = call.arguments()
          ? std::get_if<EncodableMap>(call.arguments()) : nullptr;
      if (value) {
        const auto entry = value->find(EncodableValue("expected"));
        const auto expected = entry == value->end()
            ? nullptr : std::get_if<EncodableMap>(&entry->second);
        if (expected) {
          EncodableMap current;
          bool same = expected->size() == 4 && ReadProxy(&current);
          for (const auto& item : *expected) {
            const auto key = std::get_if<std::string>(&item.first);
            if (!key) { same = false; break; }
            const auto found = current.find(item.first);
            if (found == current.end()) { same = false; break; }
            if (*key == "flags") {
              auto integer = [](const EncodableValue& number) -> int64_t {
                if (const auto small = std::get_if<int32_t>(&number)) return *small;
                if (const auto large = std::get_if<int64_t>(&number)) return *large;
                return -1;
              };
              if (integer(item.second) != integer(found->second)) same = false;
            } else {
              const auto wanted = std::get_if<std::string>(&item.second);
              const auto actual = std::get_if<std::string>(&found->second);
              if (!wanted || !actual || *wanted != *actual) same = false;
            }
          }
          if (!same) {
            result->Error("system_proxy_changed", "The system proxy settings changed");
            return;
          }
        } else if (entry != value->end()) {
          result->Error("system_proxy", "The system proxy settings could not be changed");
          return;
        }
      }
      if (value && WriteProxy(*value)) result->Success();
      else result->Error("system_proxy", "The system proxy settings could not be changed");
    } else {
      result->NotImplemented();
    }
  });
  window_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        const auto& method = call.method_name();
        if (method == "startDrag") {
          ReleaseCapture();
          SendMessage(window_, WM_NCLBUTTONDOWN, HTCAPTION, 0);
        } else if (method == "titleDoubleClick" || method == "maximize") {
          ShowWindow(window_, IsZoomed(window_) ? SW_RESTORE : SW_MAXIMIZE);
        } else if (method == "minimize") {
          ShowWindow(window_, SW_MINIMIZE);
        } else if (method == "close") {
          // window_manager intercepts WM_CLOSE and delegates the close policy.
          PostMessage(window_, WM_CLOSE, 0, 0);
        } else if (method != "setNativeControlsVisible") {
          result->NotImplemented();
          return;
        }
        result->Success();
      });
  hotkeys_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        if (call.method_name() == "unregisterAll") {
          UnregisterHotkeys();
          result->Success();
          return;
        }
        const auto action = call.arguments()
            ? std::get_if<std::string>(call.arguments()) : nullptr;
        if (call.method_name() != "register" || !action) {
          result->NotImplemented();
          return;
        }
        for (size_t index = 0; index < kActions.size(); ++index) {
          if (*action != kActions[index]) continue;
          const int id = kHotkeyBase + static_cast<int>(index);
          if (registered_[index]) UnregisterHotKey(window_, id);
          registered_[index] = RegisterHotKey(
              window_, id, MOD_CONTROL | MOD_ALT | MOD_NOREPEAT, kKeys[index]) != 0;
          result->Success(EncodableValue(registered_[index] ? "registered" :
              GetLastError() == ERROR_HOTKEY_ALREADY_REGISTERED ? "taken" :
              "unsupported"));
          return;
        }
        result->Success(EncodableValue("unsupported"));
      });
  apps_channel_->SetMethodCallHandler([](const auto& call, auto result) {
    if (call.method_name() != "list") {
      result->NotImplemented();
      return;
    }
    result->Success(EncodableValue(InstalledApps()));
  });
}

DesktopChannels::~DesktopChannels() { UnregisterHotkeys(); }

void DesktopChannels::UnregisterHotkeys() {
  for (size_t index = 0; index < kActions.size(); ++index) {
    if (registered_[index]) {
      UnregisterHotKey(window_, kHotkeyBase + static_cast<int>(index));
      registered_[index] = false;
    }
  }
}

bool DesktopChannels::HandleMessage(UINT message, WPARAM wparam) {
  if (message != WM_HOTKEY || wparam < kHotkeyBase ||
      wparam >= kHotkeyBase + kActions.size()) return false;
  const auto index = static_cast<size_t>(wparam - kHotkeyBase);
  if (registered_[index]) {
    hotkeys_channel_->InvokeMethod(
        "pressed", std::make_unique<EncodableValue>(kActions[index]));
  }
  return true;
}
