#include "desktop_channels.h"

#include <array>
#include <cstring>
#include <map>
#include <string>

#ifdef AVALON_HAS_X11
#include <gdk/gdkx.h>
#include <X11/XKBlib.h>
#include <X11/keysym.h>
#endif

namespace {
constexpr std::array<const char*, 3> kActions = {"toggle", "mode", "show"};

class DesktopChannels {
 public:
  DesktopChannels(FlView* view, GtkWindow* window) : window_(window) {
    auto messenger = fl_engine_get_binary_messenger(fl_view_get_engine(view));
    g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
    window_channel_ = fl_method_channel_new(messenger, "avalon/window",
                                           FL_METHOD_CODEC(codec));
    hotkeys_channel_ = fl_method_channel_new(messenger, "avalon/hotkeys",
                                            FL_METHOD_CODEC(codec));
    storage_channel_ = fl_method_channel_new(messenger, "avalon/secure-storage",
                                            FL_METHOD_CODEC(codec));
    fl_method_channel_set_method_call_handler(window_channel_, WindowCall, this,
                                              nullptr);
    fl_method_channel_set_method_call_handler(hotkeys_channel_, HotkeysCall, this,
                                              nullptr);
    fl_method_channel_set_method_call_handler(storage_channel_, StorageCall,
                                              this, nullptr);
#ifdef AVALON_HAS_X11
    GdkDisplay* display = gtk_widget_get_display(GTK_WIDGET(window));
    if (GDK_IS_X11_DISPLAY(display)) {
      display_ = display;
      xdisplay_ = gdk_x11_display_get_xdisplay(display);
      root_ = DefaultRootWindow(xdisplay_);
      Bool supported = False;
      XkbSetDetectableAutoRepeat(xdisplay_, True, &supported);
      gdk_window_add_filter(nullptr, Filter, this);
      XModifierKeymap* modifiers = XGetModifierMapping(xdisplay_);
      const KeyCode numlock = XKeysymToKeycode(xdisplay_, XK_Num_Lock);
      if (modifiers) {
        for (int modifier = 0; modifier < 8; ++modifier) {
          for (int key = 0; key < modifiers->max_keypermod; ++key) {
            if (modifiers->modifiermap[modifier * modifiers->max_keypermod + key]
                == numlock) {
              numlock_mask_ = 1U << modifier;
            }
          }
        }
        XFreeModifiermap(modifiers);
      }
    }
#endif
  }

  ~DesktopChannels() {
    Unregister();
#ifdef AVALON_HAS_X11
    if (xdisplay_) gdk_window_remove_filter(nullptr, Filter, this);
#endif
    g_object_unref(window_channel_);
    g_object_unref(hotkeys_channel_);
    g_object_unref(storage_channel_);
  }

 private:
  GtkWindow* window_;
  FlMethodChannel* window_channel_;
  FlMethodChannel* hotkeys_channel_;
  FlMethodChannel* storage_channel_;
#ifdef AVALON_HAS_X11
  GdkDisplay* display_ = nullptr;
  Display* xdisplay_ = nullptr;
  Window root_ = 0;
  unsigned int numlock_mask_ = 0;
  std::map<unsigned int, std::string> keys_;
  std::map<unsigned int, bool> pressed_;

  static GdkFilterReturn Filter(GdkXEvent* native, GdkEvent*, gpointer data) {
    auto self = static_cast<DesktopChannels*>(data);
    auto event = static_cast<XEvent*>(native);
    if (event->type != KeyPress && event->type != KeyRelease) {
      return GDK_FILTER_CONTINUE;
    }
    auto key = self->keys_.find(event->xkey.keycode);
    if (key == self->keys_.end()) return GDK_FILTER_CONTINUE;
    const auto modifiers = event->xkey.state & ~(LockMask | self->numlock_mask_);
    if (modifiers != (ControlMask | Mod1Mask)) return GDK_FILTER_CONTINUE;
    if (event->type == KeyRelease) {
      self->pressed_[key->first] = false;
    } else if (!self->pressed_[key->first]) {
      self->pressed_[key->first] = true;
      g_autoptr(FlValue) action = fl_value_new_string(key->second.c_str());
      fl_method_channel_invoke_method(self->hotkeys_channel_, "pressed", action,
                                      nullptr, nullptr, nullptr);
    }
    return GDK_FILTER_REMOVE;
  }
#endif

  void Unregister() {
#ifdef AVALON_HAS_X11
    if (!xdisplay_) return;
    for (const auto& key : keys_) {
      for (unsigned int lock : {0U, unsigned(LockMask), numlock_mask_,
                               unsigned(LockMask) | numlock_mask_}) {
        XUngrabKey(xdisplay_, key.first, ControlMask | Mod1Mask | lock, root_);
      }
    }
    XFlush(xdisplay_);
    keys_.clear();
    pressed_.clear();
#endif
  }

  const char* Register(const char* action) {
#ifdef AVALON_HAS_X11
    if (!xdisplay_) return "unsupported";
    int index = -1;
    for (size_t i = 0; i < kActions.size(); ++i) {
      if (std::strcmp(action, kActions[i]) == 0) index = static_cast<int>(i);
    }
    if (index < 0) return "unsupported";
    const KeySym symbol[] = {XK_P, XK_M, XK_A};
    const KeyCode key = XKeysymToKeycode(xdisplay_, symbol[index]);
    if (!key) return "unsupported";
    if (keys_.find(key) != keys_.end()) return "registered";
    gdk_x11_display_error_trap_push(display_);
    for (unsigned int lock : {0U, unsigned(LockMask), numlock_mask_,
                             unsigned(LockMask) | numlock_mask_}) {
      XGrabKey(xdisplay_, key, ControlMask | Mod1Mask | lock, root_, False,
               GrabModeAsync, GrabModeAsync);
    }
    const int error = gdk_x11_display_error_trap_pop(display_);
    if (error) {
      // A failed variant must not leave a partially registered shortcut.
      for (unsigned int lock : {0U, unsigned(LockMask), numlock_mask_,
                               unsigned(LockMask) | numlock_mask_}) {
        XUngrabKey(xdisplay_, key, ControlMask | Mod1Mask | lock, root_);
      }
      XFlush(xdisplay_);
      return error == BadAccess ? "taken" : "unsupported";
    }
    keys_[key] = action;
    return "registered";
#else
    (void)action;
    return "unsupported";
#endif
  }

  static void WindowCall(FlMethodChannel*, FlMethodCall* call, gpointer data) {
    auto self = static_cast<DesktopChannels*>(data);
    const char* method = fl_method_call_get_name(call);
    if (std::strcmp(method, "startDrag") == 0) {
      GdkDisplay* display = gtk_widget_get_display(GTK_WIDGET(self->window_));
      GdkSeat* seat = gdk_display_get_default_seat(display);
      GdkDevice* pointer = seat ? gdk_seat_get_pointer(seat) : nullptr;
      if (pointer) {
        gint x = 0, y = 0;
        gdk_device_get_position(pointer, nullptr, &x, &y);
        gtk_window_begin_move_drag(self->window_, 1, x, y,
                                   gtk_get_current_event_time());
      }
    } else if (std::strcmp(method, "titleDoubleClick") == 0 ||
               std::strcmp(method, "maximize") == 0) {
      if (gtk_window_is_maximized(self->window_)) {
        gtk_window_unmaximize(self->window_);
      } else {
        gtk_window_maximize(self->window_);
      }
    } else if (std::strcmp(method, "minimize") == 0) {
      gtk_window_iconify(self->window_);
    } else if (std::strcmp(method, "close") == 0) {
      // The window_manager delete-event handler keeps the shell's close policy.
      gtk_window_close(self->window_);
    } else if (std::strcmp(method, "setNativeControlsVisible") != 0) {
      fl_method_call_respond_not_implemented(call, nullptr);
      return;
    }
    fl_method_call_respond_success(call, nullptr, nullptr);
  }

  static void HotkeysCall(FlMethodChannel*, FlMethodCall* call, gpointer data) {
    auto self = static_cast<DesktopChannels*>(data);
    const char* method = fl_method_call_get_name(call);
    if (std::strcmp(method, "unregisterAll") == 0) {
      self->Unregister();
      fl_method_call_respond_success(call, nullptr, nullptr);
      return;
    }
    FlValue* args = fl_method_call_get_args(call);
    if (std::strcmp(method, "register") != 0 ||
        fl_value_get_type(args) != FL_VALUE_TYPE_STRING) {
      fl_method_call_respond_not_implemented(call, nullptr);
      return;
    }
    g_autoptr(FlValue) value =
        fl_value_new_string(self->Register(fl_value_get_string(args)));
    fl_method_call_respond_success(call, value, nullptr);
  }

  static void StorageCall(FlMethodChannel*, FlMethodCall* call, gpointer) {
    if (std::strcmp(fl_method_call_get_name(call), "secretServiceAvailable") != 0) {
      fl_method_call_respond_not_implemented(call, nullptr);
      return;
    }
    g_autoptr(GError) error = nullptr;
    g_autoptr(GDBusConnection) bus = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr,
                                                  &error);
    if (!bus) {
      // A broken or denied session bus is not proof that the service is absent.
      fl_method_call_respond_error(call, "storage_unavailable",
                                  "secure storage is unavailable", nullptr,
                                  nullptr);
      return;
    }
    g_autoptr(GVariant) reply = g_dbus_connection_call_sync(
        bus, "org.freedesktop.DBus", "/org/freedesktop/DBus",
        "org.freedesktop.DBus", "StartServiceByName",
        g_variant_new("(su)", "org.freedesktop.secrets", 0U),
        G_VARIANT_TYPE("(u)"), G_DBUS_CALL_FLAGS_NONE, 3000, nullptr, &error);
    if (reply) {
      g_autoptr(FlValue) value = fl_value_new_bool(true);
      fl_method_call_respond_success(call, value, nullptr);
    } else if (g_error_matches(error, G_DBUS_ERROR, G_DBUS_ERROR_SERVICE_UNKNOWN) ||
               g_error_matches(error, G_DBUS_ERROR, G_DBUS_ERROR_NAME_HAS_NO_OWNER)) {
      g_autoptr(FlValue) value = fl_value_new_bool(false);
      fl_method_call_respond_success(call, value, nullptr);
    } else {
      // Locked, denied, timed out or temporarily broken is not "not installed".
      fl_method_call_respond_error(call, "storage_unavailable",
                                  "secure storage is unavailable", nullptr,
                                  nullptr);
    }
  }
};
}  // namespace

void avalon_register_desktop_channels(FlView* view, GtkWindow* window) {
  auto channels = new DesktopChannels(view, window);
  g_object_set_data_full(G_OBJECT(view), "avalon-desktop-channels", channels,
                         [](gpointer data) {
                           delete static_cast<DesktopChannels*>(data);
                         });
}
