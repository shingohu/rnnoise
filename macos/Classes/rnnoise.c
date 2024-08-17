// Relative import to be able to reuse the C sources.
// See the comment in ../rnnoise.podspec for more information.
#include "../../src/rnnoise.c"
#include "../../src/rnnoise/src/celt_lpc.c"
#include "../../src/rnnoise/src/nnet_default.c"
#include "../../src/rnnoise/src/rnn.c"
#include "../../src/rnnoise/src/rnnoise_tables.c"
#include "../../src/rnnoise/src/denoise.c"
#include "../../src/rnnoise/src/kiss_fft.c"
#include "../../src/rnnoise/src/parse_lpcnet_weights.c"
#include "../../src/rnnoise/src/rnnoise_data.c"
#include "../../src/rnnoise/src/nnet.c"
#include "../../src/rnnoise/src/pitch.c"
