#import <AppKit/AppKit.h>
#import <ImageIO/ImageIO.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#include "kartpad/memory/checked_guest_memory.h"
#include "kartpad/translation/fixture_runtime.h"
#include "ppc_runtime.h"

#include <array>
#include <cmath>
#include <cstdlib>
#include <filesystem>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

namespace {

constexpr std::uint32_t kCommandAddress = 0x80010000;

void Require(const bool condition, const char* message) {
  if (!condition) {
    throw std::runtime_error(message);
  }
}

void PumpEvents(const NSTimeInterval seconds) {
  NSDate* deadline = [NSDate dateWithTimeIntervalSinceNow:seconds];
  while (deadline.timeIntervalSinceNow > 0) {
    NSEvent* event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                        untilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]
                                           inMode:NSDefaultRunLoopMode
                                          dequeue:YES];
    if (event != nil) {
      [NSApp sendEvent:event];
    }
    [NSApp updateWindows];
  }
}

void WritePng(const std::filesystem::path& path, const std::uint32_t width,
              const std::uint32_t height, const std::vector<std::uint8_t>& bgra) {
  std::vector<std::uint8_t> rgba(bgra.size());
  for (std::size_t index = 0; index < bgra.size(); index += 4) {
    rgba[index] = bgra[index + 2];
    rgba[index + 1] = bgra[index + 1];
    rgba[index + 2] = bgra[index];
    rgba[index + 3] = bgra[index + 3];
  }
  CGDataProviderRef provider =
      CGDataProviderCreateWithData(nullptr, rgba.data(), rgba.size(), nullptr);
  Require(provider != nullptr, "PNG data provider creation failed");
  CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
  const auto bitmap_info = static_cast<CGBitmapInfo>(
      static_cast<std::uint32_t>(kCGBitmapByteOrderDefault) |
      static_cast<std::uint32_t>(kCGImageAlphaLast));
  CGImageRef image = CGImageCreate(width, height, 8, 32, width * 4, color_space,
                                   bitmap_info, provider, nullptr, false,
                                   kCGRenderingIntentDefault);
  Require(image != nullptr, "PNG image creation failed");
  std::filesystem::create_directories(path.parent_path());
  CFURLRef url = CFURLCreateFromFileSystemRepresentation(
      nullptr, reinterpret_cast<const UInt8*>(path.c_str()), path.string().size(), false);
  CGImageDestinationRef destination =
      CGImageDestinationCreateWithURL(url, (__bridge CFStringRef)UTTypePNG.identifier, 1, nullptr);
  Require(destination != nullptr, "PNG destination creation failed");
  CGImageDestinationAddImage(destination, image, nullptr);
  Require(CGImageDestinationFinalize(destination), "PNG finalization failed");
  CFRelease(destination);
  CFRelease(url);
  CGImageRelease(image);
  CGColorSpaceRelease(color_space);
  CGDataProviderRelease(provider);
}

void RenderTranslatedFrame(const std::filesystem::path& output) {
  kartpad::memory::CheckedGuestMemory memory;
  memory.Map({.guest_base = 0x80000000, .size = 0x20000, .backing = 1});
  CpuContext context{};
  kartpad::translation::BindFixtureMemory(memory);
  try {
    kartpad::translation::RunG7TranslatedFrame(context);
  } catch (...) {
    kartpad::translation::UnbindFixtureMemory();
    throw;
  }
  kartpad::translation::UnbindFixtureMemory();

  Require(memory.LoadUnsigned(kCommandAddress, 4) == 0x4B504446, "translated command magic mismatch");
  const auto width = static_cast<std::uint32_t>(memory.LoadUnsigned(kCommandAddress + 4, 4));
  const auto height = static_cast<std::uint32_t>(memory.LoadUnsigned(kCommandAddress + 8, 4));
  const auto rgba = static_cast<std::uint32_t>(memory.LoadUnsigned(kCommandAddress + 12, 4));
  Require(width == 256 && height == 192 && rgba == 0x2458A8FF,
          "translated frame command mismatch");

  [NSApplication sharedApplication];
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  NSWindow* window = [[NSWindow alloc]
      initWithContentRect:NSMakeRect(0, 0, width, height)
                styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                          NSWindowStyleMaskMiniaturizable
                  backing:NSBackingStoreBuffered
                    defer:NO];
  window.title = @"KartPad — Translated Frame";
  [window center];

  id<MTLDevice> device = MTLCreateSystemDefaultDevice();
  Require(device != nil, "Metal device unavailable");
  CAMetalLayer* layer = [CAMetalLayer layer];
  layer.device = device;
  layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
  layer.framebufferOnly = NO;
  layer.drawableSize = CGSizeMake(width, height);
  layer.contentsScale = NSScreen.mainScreen.backingScaleFactor;
  window.contentView.wantsLayer = YES;
  window.contentView.layer = layer;
  [window makeKeyAndOrderFront:nil];
  [NSApp activateIgnoringOtherApps:YES];
  PumpEvents(0.15);

  id<CAMetalDrawable> drawable = [layer nextDrawable];
  Require(drawable != nil, "CAMetalLayer did not provide a drawable");
  id<MTLCommandQueue> queue = [device newCommandQueue];
  id<MTLCommandBuffer> commands = [queue commandBuffer];
  MTLRenderPassDescriptor* pass = [MTLRenderPassDescriptor renderPassDescriptor];
  pass.colorAttachments[0].texture = drawable.texture;
  pass.colorAttachments[0].loadAction = MTLLoadActionClear;
  pass.colorAttachments[0].storeAction = MTLStoreActionStore;
  pass.colorAttachments[0].clearColor = MTLClearColorMake(
      static_cast<double>((rgba >> 24) & 0xFF) / 255.0,
      static_cast<double>((rgba >> 16) & 0xFF) / 255.0,
      static_cast<double>((rgba >> 8) & 0xFF) / 255.0,
      static_cast<double>(rgba & 0xFF) / 255.0);
  id<MTLRenderCommandEncoder> render = [commands renderCommandEncoderWithDescriptor:pass];
  [render endEncoding];
  id<MTLBuffer> readback = [device newBufferWithLength:width * height * 4
                                               options:MTLResourceStorageModeShared];
  id<MTLBlitCommandEncoder> blit = [commands blitCommandEncoder];
  [blit copyFromTexture:drawable.texture
            sourceSlice:0
            sourceLevel:0
           sourceOrigin:MTLOriginMake(0, 0, 0)
             sourceSize:MTLSizeMake(width, height, 1)
               toBuffer:readback
      destinationOffset:0
 destinationBytesPerRow:width * 4
destinationBytesPerImage:width * height * 4];
  [blit endEncoding];
  [commands presentDrawable:drawable];
  [commands commit];
  [commands waitUntilCompleted];
  Require(commands.status == MTLCommandBufferStatusCompleted && commands.error == nil,
          "translated frame Metal command failed");

  const auto* bytes = static_cast<const std::uint8_t*>(readback.contents);
  std::vector<std::uint8_t> pixels(bytes, bytes + width * height * 4);
  const std::array<std::uint8_t, 4> expected = {0xA8, 0x58, 0x24, 0xFF};
  for (std::size_t index = 0; index < pixels.size(); index += 4) {
    for (std::size_t channel = 0; channel < 4; ++channel) {
      Require(std::abs(static_cast<int>(pixels[index + channel]) - expected[channel]) <= 1,
              "translated drawable pixel mismatch");
    }
  }
  WritePng(output, width, height, pixels);
  PumpEvents(0.5);
  [window orderOut:nil];
  std::cout << "translatedFunction=0x80001000 command=KPDF drawable=" << width << 'x' << height
            << " rgba=2458A8FF pixelCompare=pass output=" << output << '\n';
}

}  // namespace

int main(int argc, const char* argv[]) {
  @autoreleasepool {
    try {
      if (argc != 2) {
        throw std::invalid_argument("usage: KartPadG7Frame <output.png>");
      }
      RenderTranslatedFrame(std::filesystem::path{argv[1]});
      return EXIT_SUCCESS;
    } catch (const std::exception& error) {
      std::cerr << "KartPad translated frame failure: " << error.what() << '\n';
      return EXIT_FAILURE;
    }
  }
}
