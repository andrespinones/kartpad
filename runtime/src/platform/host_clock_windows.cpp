#include "kartpad/platform/host_services.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#include <thread>

namespace kartpad::platform {

std::uint64_t MonotonicNanoseconds() noexcept {
  LARGE_INTEGER frequency{};
  LARGE_INTEGER counter{};
  if (!::QueryPerformanceFrequency(&frequency) || !::QueryPerformanceCounter(&counter)) {
    return 0;
  }
  const long double seconds = static_cast<long double>(counter.QuadPart) /
                              static_cast<long double>(frequency.QuadPart);
  return static_cast<std::uint64_t>(seconds * 1'000'000'000.0L);
}

void SleepUntil(const std::chrono::steady_clock::time_point deadline) {
  std::this_thread::sleep_until(deadline);
}

bool SetCurrentThreadName(const std::string_view name) noexcept {
  const int length = ::MultiByteToWideChar(CP_UTF8, 0, name.data(), static_cast<int>(name.size()),
                                           nullptr, 0);
  if (length <= 0) {
    return false;
  }
  std::wstring wide(static_cast<std::size_t>(length), L'\0');
  (void)::MultiByteToWideChar(CP_UTF8, 0, name.data(), static_cast<int>(name.size()), wide.data(),
                              length);
  return SUCCEEDED(::SetThreadDescription(::GetCurrentThread(), wide.c_str()));
}

std::string CurrentThreadName() {
  PWSTR wide = nullptr;
  if (FAILED(::GetThreadDescription(::GetCurrentThread(), &wide)) || wide == nullptr) {
    return {};
  }
  const int length = ::WideCharToMultiByte(CP_UTF8, 0, wide, -1, nullptr, 0, nullptr, nullptr);
  std::string result(length > 0 ? static_cast<std::size_t>(length) : 0, '\0');
  if (!result.empty()) {
    (void)::WideCharToMultiByte(CP_UTF8, 0, wide, -1, result.data(), length, nullptr, nullptr);
    result.pop_back();
  }
  ::LocalFree(wide);
  return result;
}

}  // namespace kartpad::platform
