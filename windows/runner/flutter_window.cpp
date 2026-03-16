#include "flutter_window.h"

#include <flutter/standard_method_codec.h>
#include <gdiplus.h>

#include <optional>

#include "resource.h"
#include "flutter/generated_plugin_registrant.h"
#include "utils.h"

namespace {

std::string ReadStringArgument(const flutter::EncodableMap& arguments,
                               const char* key) {
  const auto iterator = arguments.find(flutter::EncodableValue(key));
  if (iterator == arguments.end()) {
    return std::string();
  }

  const auto* value = std::get_if<std::string>(&iterator->second);
  return value == nullptr ? std::string() : *value;
}

HICON LoadDefaultIcon(int size) {
  return static_cast<HICON>(::LoadImageW(
      ::GetModuleHandle(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON), IMAGE_ICON,
      size, size, LR_DEFAULTCOLOR | LR_SHARED));
}

HICON LoadIconFromImageFile(const std::wstring& icon_path, int target_size) {
  Gdiplus::Bitmap source(icon_path.c_str());
  if (source.GetLastStatus() != Gdiplus::Ok) {
    return nullptr;
  }

  Gdiplus::Bitmap canvas(target_size, target_size, PixelFormat32bppARGB);
  if (canvas.GetLastStatus() != Gdiplus::Ok) {
    return nullptr;
  }

  Gdiplus::Graphics graphics(&canvas);
  graphics.SetSmoothingMode(Gdiplus::SmoothingModeAntiAlias);
  graphics.SetInterpolationMode(Gdiplus::InterpolationModeHighQualityBicubic);
  graphics.SetCompositingQuality(Gdiplus::CompositingQualityHighQuality);
  graphics.Clear(Gdiplus::Color(0, 0, 0, 0));
  graphics.DrawImage(&source, 0, 0, target_size, target_size);

  HICON icon = nullptr;
  return canvas.GetHICON(&icon) == Gdiplus::Ok ? icon : nullptr;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  Gdiplus::GdiplusStartupInput gdiplus_startup_input;
  gdiplus_started_ =
      Gdiplus::GdiplusStartup(&gdiplus_token_, &gdiplus_startup_input,
                              nullptr) == Gdiplus::Ok;

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  RegisterWindowIdentityChannel();
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  window_identity_channel_ = nullptr;
  ClearCustomIcons();

  if (gdiplus_started_) {
    Gdiplus::GdiplusShutdown(gdiplus_token_);
    gdiplus_started_ = false;
    gdiplus_token_ = 0;
  }

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::RegisterWindowIdentityChannel() {
  window_identity_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "diary_mvp/window_identity",
          &flutter::StandardMethodCodec::GetInstance());

  window_identity_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<
                 flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() != "applyWindowIdentity") {
          result->NotImplemented();
          return;
        }

        const auto* arguments =
            std::get_if<flutter::EncodableMap>(call.arguments());
        if (arguments == nullptr) {
          result->Error("bad-args", "Expected a map of arguments.");
          return;
        }

        const auto title = Utf16FromUtf8(ReadStringArgument(*arguments, "title"));
        const auto icon_path =
            Utf16FromUtf8(ReadStringArgument(*arguments, "iconPath"));

        if (!title.empty()) {
          ApplyWindowTitle(title);
        }

        if (icon_path.empty()) {
          RestoreDefaultWindowIcon();
          result->Success();
          return;
        }

        if (!ApplyWindowIcon(icon_path)) {
          RestoreDefaultWindowIcon();
          result->Error("icon-load-failed",
                        "Failed to load the requested window icon.");
          return;
        }

        result->Success();
      });
}

void FlutterWindow::ApplyWindowTitle(const std::wstring& title) {
  const auto window = GetHandle();
  if (window == nullptr) {
    return;
  }

  ::SetWindowTextW(window, title.c_str());
}

bool FlutterWindow::ApplyWindowIcon(const std::wstring& icon_path) {
  if (!gdiplus_started_) {
    return false;
  }

  const auto window = GetHandle();
  if (window == nullptr) {
    return false;
  }

  const int large_size = ::GetSystemMetrics(SM_CXICON);
  const int small_size = ::GetSystemMetrics(SM_CXSMICON);
  HICON large_icon = LoadIconFromImageFile(icon_path, large_size);
  HICON small_icon = LoadIconFromImageFile(icon_path, small_size);

  if (large_icon == nullptr || small_icon == nullptr) {
    if (large_icon != nullptr) {
      ::DestroyIcon(large_icon);
    }
    if (small_icon != nullptr) {
      ::DestroyIcon(small_icon);
    }
    return false;
  }

  ::SendMessage(window, WM_SETICON, ICON_BIG,
                reinterpret_cast<LPARAM>(large_icon));
  ::SendMessage(window, WM_SETICON, ICON_SMALL,
                reinterpret_cast<LPARAM>(small_icon));
  ::SetClassLongPtr(window, GCLP_HICON,
                    reinterpret_cast<LONG_PTR>(large_icon));
  ::SetClassLongPtr(window, GCLP_HICONSM,
                    reinterpret_cast<LONG_PTR>(small_icon));

  ClearCustomIcons();
  large_window_icon_ = large_icon;
  small_window_icon_ = small_icon;
  return true;
}

void FlutterWindow::RestoreDefaultWindowIcon() {
  const auto window = GetHandle();
  if (window == nullptr) {
    return;
  }

  HICON large_icon = LoadDefaultIcon(::GetSystemMetrics(SM_CXICON));
  HICON small_icon = LoadDefaultIcon(::GetSystemMetrics(SM_CXSMICON));

  ::SendMessage(window, WM_SETICON, ICON_BIG,
                reinterpret_cast<LPARAM>(large_icon));
  ::SendMessage(window, WM_SETICON, ICON_SMALL,
                reinterpret_cast<LPARAM>(small_icon));
  ::SetClassLongPtr(window, GCLP_HICON,
                    reinterpret_cast<LONG_PTR>(large_icon));
  ::SetClassLongPtr(window, GCLP_HICONSM,
                    reinterpret_cast<LONG_PTR>(small_icon));

  ClearCustomIcons();
}

void FlutterWindow::ClearCustomIcons() {
  if (large_window_icon_ != nullptr) {
    ::DestroyIcon(large_window_icon_);
    large_window_icon_ = nullptr;
  }

  if (small_window_icon_ != nullptr) {
    ::DestroyIcon(small_window_icon_);
    small_window_icon_ = nullptr;
  }
}
