#include "kartpad/platform/host_services.h"

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>

namespace {

void Require(const bool condition, const std::string& message) {
  if (!condition) {
    throw std::runtime_error(message);
  }
}

std::string ReadFile(const std::filesystem::path& path) {
  std::ifstream stream{path, std::ios::binary};
  return std::string{std::istreambuf_iterator<char>{stream}, std::istreambuf_iterator<char>{}};
}

void TestCapabilities() {
#if MKW_HOST_DARWIN
  static_assert(MKW_HOST_DARWIN == 1);
  static_assert(MKW_HOST_WINDOWS == 0);
#elif MKW_HOST_WINDOWS
  static_assert(MKW_HOST_DARWIN == 0);
  static_assert(MKW_HOST_WINDOWS == 1);
#endif
#if defined(__aarch64__) || defined(__arm64__)
  static_assert(MKW_HOST_ARM64 == 1);
  static_assert(MKW_HOST_X86_64 == 0);
#endif
#if MKW_HOST_DARWIN
  static_assert(MKW_RENDER_METAL == 1);
  static_assert(MKW_RENDER_D3D12 == 0);
#elif MKW_HOST_WINDOWS
  static_assert(MKW_RENDER_METAL == 0);
  static_assert(MKW_RENDER_D3D12 == 1);
#endif
}

void TestClockAndThreadName() {
  const std::uint64_t before = kartpad::platform::MonotonicNanoseconds();
  const auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds{5};
  kartpad::platform::SleepUntil(deadline);
  const std::uint64_t after = kartpad::platform::MonotonicNanoseconds();
  Require(after > before, "monotonic clock did not advance");
  Require(after - before >= 4'000'000, "SleepUntil returned materially before its deadline");
  Require(kartpad::platform::SetCurrentThreadName("kartpad-contract"),
          "failed to set the current thread name");
  Require(kartpad::platform::CurrentThreadName() == "kartpad-contract",
          "current thread name did not round-trip");
}

void TestPathsAndAtomicWrite() {
  const auto paths = kartpad::platform::ResolveHostPaths("com.kartpad.contract-tests");
  Require(paths.app_support.filename() == "com.kartpad.contract-tests", "bad app-support path");
  Require(paths.cache.filename() == "com.kartpad.contract-tests", "bad cache path");
  Require(paths.temporary.filename() == "com.kartpad.contract-tests", "bad temporary path");

  const std::filesystem::path root = paths.temporary / "atomic-write-fixture";
  std::filesystem::remove_all(root);
  const std::filesystem::path destination = root / "state.dat";
  kartpad::platform::AtomicWriteFile(destination, "first");
  Require(ReadFile(destination) == "first", "initial atomic write mismatch");
  kartpad::platform::AtomicWriteFile(destination, "second-state");
  Require(ReadFile(destination) == "second-state", "replacement atomic write mismatch");

  std::size_t temporary_count = 0;
  for (const auto& entry : std::filesystem::directory_iterator(root)) {
    temporary_count += entry.path().filename().string().find(".tmp.") != std::string::npos ? 1U : 0U;
  }
  Require(temporary_count == 0, "atomic write left a temporary sibling");
  std::filesystem::remove_all(root);
}

}  // namespace

int main() {
  try {
    TestCapabilities();
    TestClockAndThreadName();
    TestPathsAndAtomicWrite();
    std::cout << "KartPad host contract tests passed\n";
    return EXIT_SUCCESS;
  } catch (const std::exception& error) {
    std::cerr << "KartPad host contract test failure: " << error.what() << '\n';
    return EXIT_FAILURE;
  }
}
