#include "kartpad/platform/host_services.h"

#include <cstdlib>
#include <stdexcept>

namespace kartpad::platform {
namespace {

std::filesystem::path RequiredEnvironmentPath(const char* name) {
  const char* value = std::getenv(name);
  if (value == nullptr || *value == '\0') {
    throw std::runtime_error(std::string{"required environment variable is missing: "} + name);
  }
  return std::filesystem::path{value};
}

void ValidateIdentifier(const std::string_view identifier) {
  if (identifier.empty() || identifier.find('/') != std::string_view::npos ||
      identifier.find('\\') != std::string_view::npos || identifier == "." || identifier == "..") {
    throw std::invalid_argument("application identifier must be one non-empty path component");
  }
}

}  // namespace

HostPaths ResolveHostPaths(const std::string_view application_identifier) {
  ValidateIdentifier(application_identifier);
  const std::filesystem::path home = RequiredEnvironmentPath("HOME");
  const std::filesystem::path temp = RequiredEnvironmentPath("TMPDIR");
  const std::filesystem::path component{application_identifier};
  return {
      .app_support = home / "Library" / "Application Support" / component,
      .cache = home / "Library" / "Caches" / component,
      .temporary = temp / component,
  };
}

void EnsureHostDirectories(const HostPaths& paths) {
  std::filesystem::create_directories(paths.app_support);
  std::filesystem::create_directories(paths.cache);
  std::filesystem::create_directories(paths.temporary);
}

}  // namespace kartpad::platform
