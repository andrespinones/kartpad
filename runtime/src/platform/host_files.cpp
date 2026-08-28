#include "kartpad/platform/host_services.h"

#include <fcntl.h>
#include <unistd.h>

#include <cerrno>
#include <cstring>
#include <stdexcept>
#include <system_error>

namespace kartpad::platform {
namespace {

class FileDescriptor final {
 public:
  explicit FileDescriptor(const int value) : value_(value) {}
  ~FileDescriptor() {
    if (value_ >= 0) {
      ::close(value_);
    }
  }
  FileDescriptor(const FileDescriptor&) = delete;
  FileDescriptor& operator=(const FileDescriptor&) = delete;
  [[nodiscard]] int Get() const noexcept { return value_; }

 private:
  int value_;
};

[[noreturn]] void ThrowSystemError(const char* operation) {
  throw std::system_error(errno, std::generic_category(), operation);
}

}  // namespace

void AtomicWriteFile(const std::filesystem::path& destination, const std::string_view contents) {
  const std::filesystem::path parent = destination.parent_path();
  if (parent.empty()) {
    throw std::invalid_argument("atomic destination must have a parent directory");
  }
  std::filesystem::create_directories(parent);

  std::string pattern = (parent / (destination.filename().string() + ".tmp.XXXXXX")).string();
  FileDescriptor file{::mkstemp(pattern.data())};
  if (file.Get() < 0) {
    ThrowSystemError("mkstemp");
  }

  try {
    std::size_t offset = 0;
    while (offset < contents.size()) {
      const ssize_t written = ::write(file.Get(), contents.data() + offset, contents.size() - offset);
      if (written < 0) {
        if (errno == EINTR) {
          continue;
        }
        ThrowSystemError("write");
      }
      offset += static_cast<std::size_t>(written);
    }
    if (::fsync(file.Get()) != 0) {
      ThrowSystemError("fsync");
    }
    if (::rename(pattern.c_str(), destination.c_str()) != 0) {
      ThrowSystemError("rename");
    }

    FileDescriptor directory{::open(parent.c_str(), O_RDONLY | O_DIRECTORY)};
    if (directory.Get() >= 0) {
      (void)::fsync(directory.Get());
    }
  } catch (...) {
    (void)::unlink(pattern.c_str());
    throw;
  }
}

}  // namespace kartpad::platform
