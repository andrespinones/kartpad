#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import <GameController/GameController.h>
#import <Metal/Metal.h>

#include "kartpad/platform/host_services.h"

#include <arpa/inet.h>
#include <netdb.h>
#include <sys/socket.h>
#include <unistd.h>

#include <array>
#include <cerrno>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <iostream>
#include <stdexcept>
#include <string>
#include <string_view>
#include <system_error>

namespace {

void Require(const bool condition, const char* message) {
  if (!condition) {
    throw std::runtime_error(message);
  }
}

class FileDescriptor final {
 public:
  explicit FileDescriptor(const int value) : value_(value) {
    if (value_ < 0) {
      throw std::system_error(errno, std::generic_category(), "socket");
    }
  }
  ~FileDescriptor() { (void)::close(value_); }
  FileDescriptor(const FileDescriptor&) = delete;
  FileDescriptor& operator=(const FileDescriptor&) = delete;
  [[nodiscard]] int Get() const noexcept { return value_; }

 private:
  int value_;
};

void TestMetalClearReadback() {
  id<MTLDevice> device = MTLCreateSystemDefaultDevice();
  Require(device != nil, "Metal device is unavailable");
  id<MTLCommandQueue> queue = [device newCommandQueue];
  Require(queue != nil, "Metal command queue creation failed");

  MTLTextureDescriptor* descriptor =
      [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                         width:8
                                                        height:8
                                                     mipmapped:NO];
  descriptor.storageMode = MTLStorageModeShared;
  descriptor.usage = MTLTextureUsageRenderTarget;
  id<MTLTexture> texture = [device newTextureWithDescriptor:descriptor];
  Require(texture != nil, "Metal texture creation failed");

  MTLRenderPassDescriptor* pass = [MTLRenderPassDescriptor renderPassDescriptor];
  pass.colorAttachments[0].texture = texture;
  pass.colorAttachments[0].loadAction = MTLLoadActionClear;
  pass.colorAttachments[0].storeAction = MTLStoreActionStore;
  pass.colorAttachments[0].clearColor = MTLClearColorMake(0.25, 0.5, 0.75, 1.0);

  id<MTLCommandBuffer> commands = [queue commandBuffer];
  Require(commands != nil, "Metal command buffer creation failed");
  id<MTLRenderCommandEncoder> encoder = [commands renderCommandEncoderWithDescriptor:pass];
  Require(encoder != nil, "Metal render encoder creation failed");
  [encoder endEncoding];
  [commands commit];
  [commands waitUntilCompleted];
  Require(commands.status == MTLCommandBufferStatusCompleted, "Metal clear command failed");
  Require(commands.error == nil, "Metal validation reported a command error");

  std::array<std::uint8_t, 8 * 8 * 4> pixels{};
  [texture getBytes:pixels.data()
         bytesPerRow:8 * 4
          fromRegion:MTLRegionMake2D(0, 0, 8, 8)
         mipmapLevel:0];
  for (std::size_t index = 0; index < pixels.size(); index += 4) {
    Require(std::abs(static_cast<int>(pixels[index]) - 64) <= 1, "Metal red clear mismatch");
    Require(std::abs(static_cast<int>(pixels[index + 1]) - 128) <= 1,
            "Metal green clear mismatch");
    Require(std::abs(static_cast<int>(pixels[index + 2]) - 191) <= 1,
            "Metal blue clear mismatch");
    Require(pixels[index + 3] == 255, "Metal alpha clear mismatch");
  }
  std::cout << "metalDevice=" << device.name.UTF8String << " clearReadback=pass\n";
}

void TestCoreAudioInitialization() {
  AudioComponentDescription description{};
  description.componentType = kAudioUnitType_Output;
  description.componentSubType = kAudioUnitSubType_DefaultOutput;
  description.componentManufacturer = kAudioUnitManufacturer_Apple;
  AudioComponent component = AudioComponentFindNext(nullptr, &description);
  Require(component != nullptr, "CoreAudio default output component is unavailable");

  AudioComponentInstance instance = nullptr;
  Require(AudioComponentInstanceNew(component, &instance) == noErr && instance != nullptr,
          "CoreAudio output instance creation failed");
  AudioStreamBasicDescription format{};
  UInt32 size = sizeof(format);
  const OSStatus result = AudioUnitGetProperty(instance, kAudioUnitProperty_StreamFormat,
                                                kAudioUnitScope_Output, 0, &format, &size);
  Require(result == noErr, "CoreAudio stream format query failed");
  Require(format.mSampleRate > 0 && format.mChannelsPerFrame > 0,
          "CoreAudio returned an invalid stream format");
  Require(AudioComponentInstanceDispose(instance) == noErr, "CoreAudio instance disposal failed");
  std::cout << "coreAudioSampleRate=" << format.mSampleRate
            << " channels=" << format.mChannelsPerFrame << " init=pass\n";
}

void TestGameControllerInitialization() {
  GCController.shouldMonitorBackgroundEvents = YES;
  NSArray<GCController*>* controllers = GCController.controllers;
  Require(controllers != nil, "GameController discovery returned nil");
  std::cout << "gameControllers=" << controllers.count << " discovery=pass\n";
}

void TestStorage() {
  const auto paths = kartpad::platform::ResolveHostPaths("com.kartpad.subsystem-smoke");
  const std::filesystem::path root = paths.temporary / "storage";
  std::filesystem::remove_all(root);
  const std::filesystem::path state = root / "state.bin";
  kartpad::platform::AtomicWriteFile(state, "kartpad-storage-smoke");
  Require(std::filesystem::file_size(state) == 21, "storage atomic write size mismatch");
  std::filesystem::remove_all(root);
  std::cout << "storageAtomicWrite=pass\n";
}

void TestDnsAndLoopbackTcp() {
  addrinfo hints{};
  hints.ai_family = AF_INET;
  hints.ai_socktype = SOCK_STREAM;
  addrinfo* resolved = nullptr;
  Require(::getaddrinfo("localhost", "80", &hints, &resolved) == 0 && resolved != nullptr,
          "DNS localhost resolution failed");
  ::freeaddrinfo(resolved);

  FileDescriptor server{::socket(AF_INET, SOCK_STREAM, 0)};
  sockaddr_in address{};
  address.sin_family = AF_INET;
  address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  address.sin_port = 0;
  Require(::bind(server.Get(), reinterpret_cast<sockaddr*>(&address), sizeof(address)) == 0,
          "loopback bind failed");
  Require(::listen(server.Get(), 1) == 0, "loopback listen failed");
  socklen_t address_length = sizeof(address);
  Require(::getsockname(server.Get(), reinterpret_cast<sockaddr*>(&address), &address_length) == 0,
          "loopback getsockname failed");

  FileDescriptor client{::socket(AF_INET, SOCK_STREAM, 0)};
  Require(::connect(client.Get(), reinterpret_cast<sockaddr*>(&address), sizeof(address)) == 0,
          "loopback connect failed");
  FileDescriptor accepted{::accept(server.Get(), nullptr, nullptr)};
  constexpr std::string_view message = "kartpad-loopback";
  Require(::send(client.Get(), message.data(), message.size(), 0) ==
              static_cast<ssize_t>(message.size()),
          "loopback send failed");
  std::array<char, 64> buffer{};
  const ssize_t received = ::recv(accepted.Get(), buffer.data(), buffer.size(), 0);
  Require(received == static_cast<ssize_t>(message.size()), "loopback receive length mismatch");
  Require(std::string_view{buffer.data(), static_cast<std::size_t>(received)} == message,
          "loopback payload mismatch");
  std::cout << "dns=pass loopbackTcp=pass\n";
}

}  // namespace

int main() {
  @autoreleasepool {
    try {
      TestMetalClearReadback();
      TestCoreAudioInitialization();
      TestGameControllerInitialization();
      TestStorage();
      TestDnsAndLoopbackTcp();
      std::cout << "KartPad native Apple subsystem smoke passed\n";
      return EXIT_SUCCESS;
    } catch (const std::exception& error) {
      std::cerr << "KartPad Apple subsystem smoke failure: " << error.what() << '\n';
      return EXIT_FAILURE;
    }
  }
}
