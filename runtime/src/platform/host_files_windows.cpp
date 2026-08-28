#include "kartpad/platform/host_services.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#include <algorithm>
#include <stdexcept>
#include <system_error>

namespace kartpad::platform {
namespace {

[[noreturn]] void ThrowWindowsError(const char* operation) {
  throw std::system_error(static_cast<int>(::GetLastError()), std::system_category(), operation);
}

}  // namespace

void AtomicWriteFile(const std::filesystem::path& destination, const std::string_view contents) {
  const std::filesystem::path parent = destination.parent_path();
  if (parent.empty()) {
    throw std::invalid_argument("atomic destination must have a parent directory");
  }
  std::filesystem::create_directories(parent);

  wchar_t temporary_name[MAX_PATH + 1]{};
  if (::GetTempFileNameW(parent.c_str(), L"KPD", 0, temporary_name) == 0) {
    ThrowWindowsError("GetTempFileNameW");
  }
  const std::filesystem::path temporary{temporary_name};
  HANDLE file = ::CreateFileW(temporary.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS,
                              FILE_ATTRIBUTE_NORMAL | FILE_FLAG_WRITE_THROUGH, nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    (void)::DeleteFileW(temporary.c_str());
    ThrowWindowsError("CreateFileW");
  }

  try {
    std::size_t offset = 0;
    while (offset < contents.size()) {
      DWORD written = 0;
      const DWORD remaining = static_cast<DWORD>(
          std::min<std::size_t>(contents.size() - offset, static_cast<std::size_t>(MAXDWORD)));
      if (!::WriteFile(file, contents.data() + offset, remaining, &written, nullptr)) {
        ThrowWindowsError("WriteFile");
      }
      offset += written;
    }
    if (!::FlushFileBuffers(file)) {
      ThrowWindowsError("FlushFileBuffers");
    }
    ::CloseHandle(file);
    file = INVALID_HANDLE_VALUE;
    if (!::MoveFileExW(temporary.c_str(), destination.c_str(),
                       MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) {
      ThrowWindowsError("MoveFileExW");
    }
  } catch (...) {
    if (file != INVALID_HANDLE_VALUE) {
      ::CloseHandle(file);
    }
    (void)::DeleteFileW(temporary.c_str());
    throw;
  }
}

}  // namespace kartpad::platform
