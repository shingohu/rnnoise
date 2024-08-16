#include "rnnoise.h"
#include "rnnoise/src/rnnoise.h"

FFI_PLUGIN_EXPORT int get_frame_size() {
    return rnnoise_get_frame_size();
}

FFI_PLUGIN_EXPORT void *create() {
    return rnnoise_create(NULL);
}

FFI_PLUGIN_EXPORT void destroy(void *handle) {
    if (handle != NULL) {
        rnnoise_destroy(handle);
        handle = NULL;
    }
}


FFI_PLUGIN_EXPORT void process_frame(void *handle, float *out, const float *in, int64_t inSize) {
    struct DenoiseState *st = (struct DenoiseState *) handle;
    int blockLen = get_frame_size();
    int64_t totalLength = inSize;
    size_t nTotal = (totalLength / blockLen);

    for (size_t i = 0; i < nTotal; i++) {
        rnnoise_process_frame(st, out, in);
        in += blockLen;
        out += blockLen;
    }
}