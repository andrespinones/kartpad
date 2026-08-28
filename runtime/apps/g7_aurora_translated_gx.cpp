#include <aurora/aurora.h>
#include <aurora/event.h>
#include <aurora/main.h>
#include <dolphin/gx.h>

#include "kartpad/memory/checked_guest_memory.h"
#include "kartpad/translation/fixture_runtime.h"
#include "ppc_runtime.h"

#include <array>
#include <bit>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <stdexcept>

namespace {

constexpr std::uint32_t kCommandAddress = 0x80010000;
constexpr std::uint32_t kCommandMagic = 0x4B504758;
constexpr std::uint32_t kCommandVersion = 0x47583031;

struct Vertex {
  float x;
  float y;
  float z;
  std::uint32_t rgba;
};

struct TranslatedGxCommand {
  std::uint32_t clear_rgba;
  std::array<Vertex, 3> vertices;
};

void LogMessage(AuroraLogLevel level, const char* module, const char* message,
                unsigned int length) {
  (void)length;
  FILE* output = level >= LOG_ERROR ? stderr : stdout;
  std::fprintf(output, "[aurora:%s] %s\n", module, message);
  std::fflush(output);
  if (level == LOG_FATAL) {
    std::abort();
  }
}

std::uint32_t LoadWord(const kartpad::memory::CheckedGuestMemory& memory,
                       const std::uint32_t offset) {
  return static_cast<std::uint32_t>(memory.LoadUnsigned(kCommandAddress + offset, 4));
}

TranslatedGxCommand RunTranslatedCommand() {
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

  if (LoadWord(memory, 0) != kCommandMagic || LoadWord(memory, 8) != 3 ||
      LoadWord(memory, 12) != kCommandVersion) {
    throw std::runtime_error("translated GX command header mismatch");
  }

  TranslatedGxCommand command{.clear_rgba = LoadWord(memory, 4)};
  for (std::uint32_t index = 0; index < command.vertices.size(); ++index) {
    const std::uint32_t base = 16 + index * 16;
    command.vertices[index] = {
        .x = std::bit_cast<float>(LoadWord(memory, base)),
        .y = std::bit_cast<float>(LoadWord(memory, base + 4)),
        .z = std::bit_cast<float>(LoadWord(memory, base + 8)),
        .rgba = LoadWord(memory, base + 12),
    };
  }
  return command;
}

GXColor ToColor(const std::uint32_t rgba) {
  return GXColor{
      .r = static_cast<std::uint8_t>(rgba >> 24),
      .g = static_cast<std::uint8_t>(rgba >> 16),
      .b = static_cast<std::uint8_t>(rgba >> 8),
      .a = static_cast<std::uint8_t>(rgba),
  };
}

void DrawTranslatedTriangle(const TranslatedGxCommand& command,
                            const AuroraWindowSize& size) {
  const float identity[3][4] = {
      {1.0F, 0.0F, 0.0F, 0.0F},
      {0.0F, 1.0F, 0.0F, 0.0F},
      {0.0F, 0.0F, 1.0F, 0.0F},
  };
  const float projection[4][4] = {
      {2.0F / static_cast<float>(size.width), 0.0F, 0.0F, -1.0F},
      {0.0F, 2.0F / static_cast<float>(size.height), 0.0F, -1.0F},
      {0.0F, 0.0F, -1.0F, 0.0F},
      {0.0F, 0.0F, 0.0F, 1.0F},
  };

  GXSetCopyClear(ToColor(command.clear_rgba), GX_MAX_Z24);
  GXSetViewport(0.0F, 0.0F, static_cast<float>(size.width),
                static_cast<float>(size.height), 0.0F, 1.0F);
  GXSetScissor(0, 0, size.width, size.height);
  GXSetProjection(projection, GX_ORTHOGRAPHIC);
  GXLoadPosMtxImm(identity, GX_PNMTX0);
  GXSetCurrentMtx(GX_PNMTX0);
  GXSetCullMode(GX_CULL_NONE);
  GXSetZMode(GX_FALSE, GX_ALWAYS, GX_FALSE);
  GXSetBlendMode(GX_BM_NONE, GX_BL_ONE, GX_BL_ZERO, GX_LO_COPY);
  GXSetColorUpdate(GX_TRUE);
  GXSetAlphaUpdate(GX_TRUE);

  GXClearVtxDesc();
  GXSetVtxDesc(GX_VA_POS, GX_DIRECT);
  GXSetVtxAttrFmt(GX_VTXFMT0, GX_VA_POS, GX_POS_XYZ, GX_F32, 0);
  GXSetNumChans(0);
  GXSetNumTexGens(0);
  GXSetNumTevStages(1);
  GXSetTevOrder(GX_TEVSTAGE0, GX_TEXCOORD_NULL, GX_TEXMAP_NULL, GX_COLOR_NULL);
  GXSetTevKColor(GX_KCOLOR0, ToColor(command.vertices[0].rgba));
  GXSetTevKColorSel(GX_TEVSTAGE0, GX_TEV_KCSEL_K0);
  GXSetTevKAlphaSel(GX_TEVSTAGE0, GX_TEV_KASEL_K0_A);
  GXSetTevColorIn(GX_TEVSTAGE0, GX_CC_ZERO, GX_CC_ZERO, GX_CC_ZERO, GX_CC_KONST);
  GXSetTevAlphaIn(GX_TEVSTAGE0, GX_CA_ZERO, GX_CA_ZERO, GX_CA_ZERO, GX_CA_KONST);
  GXSetTevColorOp(GX_TEVSTAGE0, GX_TEV_ADD, GX_TB_ZERO, GX_CS_SCALE_1, GX_TRUE,
                  GX_TEVPREV);
  GXSetTevAlphaOp(GX_TEVSTAGE0, GX_TEV_ADD, GX_TB_ZERO, GX_CS_SCALE_1, GX_TRUE,
                  GX_TEVPREV);

  GXBegin(GX_TRIANGLES, GX_VTXFMT0, 3);
  for (const Vertex& vertex : command.vertices) {
    const float x = (vertex.x + 1.0F) * 0.5F * static_cast<float>(size.width);
    const float y = (vertex.y + 1.0F) * 0.5F * static_cast<float>(size.height);
    GXPosition3f32(x, y, vertex.z);
  }
  GXEnd();
}

}  // namespace

int main(int argc, char* argv[]) {
  if (argc != 2) {
    std::fprintf(stderr, "usage: %s CAPTURE.bmp\n", argv[0]);
    return 64;
  }

  try {
    const TranslatedGxCommand command = RunTranslatedCommand();
    const AuroraConfig config = {
        .appName = "KartPad G7 Translated GX",
        .desiredBackend = BACKEND_METAL,
        .windowWidth = 640,
        .windowHeight = 480,
        .logCallback = &LogMessage,
        .logLevel = LOG_INFO,
    };
    const AuroraInfo info = aurora_initialize(argc, argv, &config);
    if (info.backend != BACKEND_METAL) {
      throw std::runtime_error("Aurora did not select Metal");
    }
    std::printf("Aurora sizes: window=%ux%u gx=%ux%u native=%ux%u scale=%.2f\n",
                info.windowSize.width, info.windowSize.height, info.windowSize.fb_width,
                info.windowSize.fb_height, info.windowSize.native_fb_width,
                info.windowSize.native_fb_height, static_cast<double>(info.windowSize.scale));

    aurora_request_frame_capture(8, argv[1]);
    unsigned int rendered_frames = 0;
    while (rendered_frames < 10) {
      const AuroraEvent* event = aurora_update();
      while (event != nullptr && event->type != AURORA_NONE) {
        if (event->type == AURORA_EXIT) {
          aurora_shutdown();
          return 2;
        }
        ++event;
      }
      if (!aurora_begin_frame()) {
        continue;
      }
      DrawTranslatedTriangle(command, info.windowSize);
      aurora_end_frame();
      ++rendered_frames;
    }
    aurora_shutdown();
    std::printf("G7 translated GX: function=0x80001000 backend=Metal frames=%u capture=%s\n",
                rendered_frames, argv[1]);
    return 0;
  } catch (const std::exception& error) {
    std::fprintf(stderr, "G7 translated GX failure: %s\n", error.what());
    return 1;
  }
}
