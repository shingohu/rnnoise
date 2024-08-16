cmake_minimum_required(VERSION 3.10)
project(rnnoise)

option(RNNOISE_COMPILE_OPUS OFF)

if(RNNOISE_COMPILE_OPUS)
    add_definitions(-DCOMPILE_OPUS)
endif()

# Ignore CRT warnings on MSVC
if(MSVC)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
endif()


# Get source files

set(RN_NOISE_SRC
        rnnoise/src/_kiss_fft_guts.h
        rnnoise/src/arch.h
        rnnoise/src/celt_lpc.h
        rnnoise/src/common.h
        rnnoise/src/cpu_support.h
        rnnoise/src/denoise.h
        rnnoise/src/kiss_fft.h
        rnnoise/src/nnet_arch.h
        rnnoise/src/nnet.h
        rnnoise/src/opus_types.h
        rnnoise/src/pitch.h
        rnnoise/src/rnn.h
        rnnoise/src/rnnoise_data.h
        rnnoise/src/rnnoise.h
        rnnoise/src/vec.h

        rnnoise/src/celt_lpc.c
        rnnoise/src/nnet_default.c
        rnnoise/src/rnn.c
        rnnoise/src/rnnoise_tables.c
        rnnoise/src/denoise.c
        rnnoise/src/kiss_fft.c
        rnnoise/src/parse_lpcnet_weights.c
        rnnoise/src/rnnoise_data.c
        #write_weights.c
        #dump_features.c
        rnnoise/src/nnet.c
        rnnoise/src/pitch.c



        )

add_library(rnnoise SHARED
        "rnnoise.c"
        ${RN_NOISE_SRC})

add_definitions(-DRNNOISE_BUILD)



set_target_properties(rnnoise PROPERTIES
        PUBLIC_HEADER rnnoise.h
        OUTPUT_NAME "rnnoise"
        )


target_compile_definitions(rnnoise PUBLIC DART_SHARED_LIB)
