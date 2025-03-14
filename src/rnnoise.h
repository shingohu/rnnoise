#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif



FFI_PLUGIN_EXPORT int get_frame_size();
FFI_PLUGIN_EXPORT void process_frame(void *handle,float *out, const float *in,int64_t inSize);
FFI_PLUGIN_EXPORT void* create();
FFI_PLUGIN_EXPORT void destroy(void *handle);
