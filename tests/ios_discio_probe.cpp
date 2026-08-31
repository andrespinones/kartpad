#include <filesystem>
#include <iostream>
#include <memory>
#include <optional>
#include <string>

#include "DiscIO/DiscExtractor.h"
#include "DiscIO/Filesystem.h"
#include "DiscIO/Volume.h"

#if defined(KARTPAD_FMT_ALLOC_SHIM)
// The feasibility oracle is linked against the reference build's fmt v12 ABI.
// Its system fmt archive is macOS-only, so provide the one allocation shim that
// Dolphin's logging object needs instead of linking a host-platform object.
namespace fmt::v12::detail
{
void* allocate(std::size_t size)
{
  return ::operator new(size);
}
}  // namespace fmt::v12::detail
#endif

int main(int argc, char** argv)
{
  if (argc != 3)
  {
    std::cerr << "usage: ios-discio-probe IMAGE DESTINATION\n";
    return 64;
  }

  std::unique_ptr<DiscIO::Volume> volume = DiscIO::CreateVolume(argv[1]);
  if (!volume)
  {
    std::cerr << "open failed\n";
    return 65;
  }

  const DiscIO::Partition partition = volume->GetGamePartition();
  const DiscIO::FileSystem* filesystem = volume->GetFileSystem(partition);
  if (!filesystem || !filesystem->IsValid())
  {
    std::cerr << "filesystem failed\n";
    return 66;
  }

  const std::string game_id = volume->GetGameID(partition);
  const std::optional<u16> revision = volume->GetRevision(partition);
  std::cout << "game=" << game_id << " revision="
            << (revision ? std::to_string(*revision) : "missing")
            << " children=" << filesystem->GetRoot().GetTotalChildren() << '\n';
  if (game_id != "RMCP01" || revision != std::optional<u16>{0})
  {
    std::cerr << "unsupported disc\n";
    return 67;
  }

  std::error_code error;
  std::filesystem::create_directories(argv[2], error);
  if (error || !DiscIO::ExportSystemData(*volume, partition, argv[2]))
  {
    std::cerr << "system export failed\n";
    return 68;
  }

  std::cout << "system export passed\n";
  return 0;
}
