#include "kartpad/platform/host_services.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shlobj.h>

#include <array>
#include <stdexcept>

namespace kartpad::platform {
namespace {

void ValidateIdentifier(const std::string_view identifier) {
  if (identifier.empty() || identifier.find('/') != std::string_view::npos ||
      identifier.find('\\') != std::string_view::npos || identifier == "." || identifier == "..") {
    throw std::invalid_argument("application identifier must be one non-empty path component");
  }
}

std::filesystem::path KnownFolder(const KNOWNFOLDERID& identifier) {
  PWSTR value = nullptr;
  if (FAILED(::SHGetKnownFolderPath(identifier, KF_FLAG_CREATE, nullptr, &value))) {
    throw std::runtime_error("SHGetKnownFolderPath failed");
  }
  std::filesystem::path result{value};
  ::CoTaskMemFree(value);
  return result;
}

}  // namespace

HostPaths ResolveHostPaths(const std::string_view application_identifier) {
  ValidateIdentifier(application_identifier);
  const std::filesystem::path component{application_identifier};
  std::array<wchar_t, MAX_PATH + 1> temporary{};
  const DWORD length = ::GetTempPathW(static_cast<DWORD>(temporary.size()), temporary.data());
  if (length == 0 || length >= temporary.size()) {
    throw std::runtime_error("GetTempPathW failed");
  }
  const auto local = KnownFolder(FOLDERID_LocalAppData);
  return {
      .app_support = local / component / "Application Support",
      .cache = local / component / "Cache",
      .temporary = std::filesystem::path{temporary.data()} / component,
  };
}

void EnsureHostDirectories(const HostPaths& paths) {
  std::filesystem::create_directories(paths.app_support);
  std::filesystem::create_directories(paths.cache);
  std::filesystem::create_directories(paths.temporary);
}

}  // namespace kartpad::platform
