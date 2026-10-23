#ifndef AVALON_DESKTOP_CHANNELS_H_
#define AVALON_DESKTOP_CHANNELS_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>

class DesktopChannels {
 public:
  DesktopChannels(flutter::BinaryMessenger* messenger, HWND window);
  ~DesktopChannels();
  bool HandleMessage(UINT message, WPARAM wparam);

 private:
  void UnregisterHotkeys();
  HWND window_;
  bool registered_[3] = {};
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> window_channel_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> hotkeys_channel_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> apps_channel_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> proxy_channel_;
};

#endif
