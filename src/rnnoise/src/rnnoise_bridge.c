#include "rnnoise.h"
#include <stdint.h>
#include <math.h>

#ifndef FRAME_SIZE
#define FRAME_SIZE 480
#endif

void rnnoise_process_frame_int16(DenoiseState *st, int16_t *out, const int16_t *in) {
  float in_float[FRAME_SIZE];
  float out_float[FRAME_SIZE];
  int i;

  for (i = 0; i < FRAME_SIZE; i++) {
    in_float[i] = (float)in[i];
  }

  rnnoise_process_frame(st, out_float, in_float);

  for (i = 0; i < FRAME_SIZE; i++) {
    float x = out_float[i];
    if (x > 32767.f) x = 32767.f;
    if (x < -32768.f) x = -32768.f;
    out[i] = (int16_t)lrintf(x);
  }
}
