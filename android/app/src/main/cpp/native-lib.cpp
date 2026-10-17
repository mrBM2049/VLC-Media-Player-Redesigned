#include <jni.h>
#include <string>
#include "vlc_bridge.h"

extern "C" JNIEXPORT jint JNICALL
Java_org_videolan_vlcmodern_VLCBridge_init(JNIEnv* env, jobject /* this */) {
    return vlc_bridge_init();
}

extern "C" JNIEXPORT void JNICALL
Java_org_videolan_vlcmodern_VLCBridge_destroy(JNIEnv* env, jobject /* this */) {
    vlc_bridge_destroy();
}

extern "C" JNIEXPORT jint JNICALL
Java_org_videolan_vlcmodern_VLCBridge_open(JNIEnv* env, jobject /* this */, jstring mrl) {
    const char* native_mrl = env->GetStringUTFChars(mrl, 0);
    int res = vlc_bridge_open(native_mrl);
    env->ReleaseStringUTFChars(mrl, native_mrl);
    return res;
}

extern "C" JNIEXPORT jint JNICALL
Java_org_videolan_vlcmodern_VLCBridge_play(JNIEnv* env, jobject /* this */) {
    return vlc_bridge_play();
}

extern "C" JNIEXPORT jint JNICALL
Java_org_videolan_vlcmodern_VLCBridge_pause(JNIEnv* env, jobject /* this */) {
    return vlc_bridge_pause();
}

extern "C" JNIEXPORT jint JNICALL
Java_org_videolan_vlcmodern_VLCBridge_stop(JNIEnv* env, jobject /* this */) {
    return vlc_bridge_stop();
}
