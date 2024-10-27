#if defined(__ANDROID__)
#include "coslog.h"

// https://android.googlesource.com/platform/system/core/+/jb-dev/include/android/log.h
void swift_android_log(android_LogPriority level, const char *tag, const char *msg) {
    __android_log_write(level, tag, msg);
}
#endif
