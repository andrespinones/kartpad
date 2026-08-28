#include "kartpad/platform/host_services.h"

#include <pthread.h>

#include <array>
#include <thread>

namespace kartpad::platform {

std::uint64_t MonotonicNanoseconds() noexcept {
  const auto now = std::chrono::steady_clock::now().time_since_epoch();
  return static_cast<std::uint64_t>(
      std::chrono::duration_cast<std::chrono::nanoseconds>(now).count());
}

void SleepUntil(const std::chrono::steady_clock::time_point deadline) {
  std::this_thread::sleep_until(deadline);
}

bool SetCurrentThreadName(const std::string_view name) noexcept {
  // Darwin limits pthread names to 63 UTF-8 bytes plus the terminator.
  constexpr std::size_t kMaximumNameBytes = 63;
  const std::string bounded{name.substr(0, kMaximumNameBytes)};
#if MKW_HOST_DARWIN
  return pthread_setname_np(bounded.c_str()) == 0;
#elif MKW_HOST_WINDOWS
  (void)bounded;
  return false;
#endif
}

std::string CurrentThreadName() {
  std::array<char, 64> name{};
  if (pthread_getname_np(pthread_self(), name.data(), name.size()) != 0) {
    return {};
  }
  return std::string{name.data()};
}

}  // namespace kartpad::platform
