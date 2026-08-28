#include <aurora/aurora.h>
#include <aurora/event.h>
#include <aurora/main.h>
#include <dolphin/gx.h>

#include <stdio.h>
#include <stdlib.h>

static void log_message(AuroraLogLevel level, const char* module, const char* message,
                        unsigned int length) {
  (void)length;
  FILE* output = level >= LOG_ERROR ? stderr : stdout;
  fprintf(output, "[aurora:%s] %s\n", module, message);
  fflush(output);
  if (level == LOG_FATAL) {
    abort();
  }
}

int main(int argc, char* argv[]) {
  if (argc != 2) {
    fprintf(stderr, "usage: %s CAPTURE.bmp\n", argv[0]);
    return 64;
  }

  const AuroraConfig config = {
      .appName = "KartPad G7 Aurora Host Frame",
      .desiredBackend = BACKEND_METAL,
      .windowWidth = 640,
      .windowHeight = 480,
      .logCallback = &log_message,
      .logLevel = LOG_INFO,
  };
  const AuroraInfo info = aurora_initialize(argc, argv, &config);
  if (info.backend != BACKEND_METAL) {
    fprintf(stderr, "expected Metal backend, got %d\n", (int)info.backend);
    aurora_shutdown();
    return 1;
  }

  // GXSetCopyClear updates the clear state consumed by the following frame's
  // begin, so frame 2 is the first frame containing the requested test color.
  aurora_request_frame_capture(2, argv[1]);
  unsigned int rendered_frames = 0;
  while (rendered_frames < 3) {
    const AuroraEvent* event = aurora_update();
    while (event != NULL && event->type != AURORA_NONE) {
      if (event->type == AURORA_EXIT) {
        aurora_shutdown();
        return 2;
      }
      ++event;
    }
    if (!aurora_begin_frame()) {
      continue;
    }
    GXSetCopyClear(GXColor{.r = 18, .g = 52, .b = 86, .a = 255}, GX_MAX_Z24);
    aurora_end_frame();
    ++rendered_frames;
  }

  // Shutdown finishes an in-flight encode before joining the frame and
  // presentation workers. Waiting here would require beginning another frame.
  aurora_shutdown();
  printf("G7 Aurora host frame: backend=Metal frames=%u capture=%s\n", rendered_frames, argv[1]);
  return 0;
}
