#include <jni.h>

#include "kartpad/android/runtime_settings.hpp"

extern "C" JNIEXPORT void JNICALL
Java_dev_kartpad_android_KartPadActivity_nativeApplyDisplaySettings(
    JNIEnv*, jobject, jboolean show_fps, jint aspect_mode,
    jfloat resolution_scale) {
  kartpad::android::PublishDisplaySettings({
      .show_fps = show_fps == JNI_TRUE,
      .aspect_mode = static_cast<int>(aspect_mode),
      .resolution_scale = static_cast<float>(resolution_scale),
  });
}
