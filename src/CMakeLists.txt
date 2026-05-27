cmake_minimum_required(VERSION 3.10)
project(rnnoise)

option(RNNOISE_COMPILE_OPUS OFF)
option(MSVC ON)

if(RNNOISE_COMPILE_OPUS)
    add_definitions(-DCOMPILE_OPUS)
endif()

# Ignore CRT warnings on MSVC
if(MSVC)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
endif()


# Get source files

set(RN_NOISE_SRC
        rnnoise/src/celt_lpc.c
        rnnoise/src/nnet_default.c
        rnnoise/src/rnn.c
        rnnoise/src/rnnoise_tables.c
        rnnoise/src/denoise.c
        rnnoise/src/kiss_fft.c
        rnnoise/src/parse_lpcnet_weights.c
        rnnoise/src/rnnoise_data_little.c
        rnnoise/src/nnet.c
        rnnoise/src/pitch.c
        rnnoise/src/rnnoise_bridge.c
        )

add_library(rnnoise SHARED
        ${RN_NOISE_SRC})

add_definitions(-DRNNOISE_BUILD)



set_target_properties(rnnoise PROPERTIES
        OUTPUT_NAME "rnnoise"
        )


target_compile_definitions(rnnoise PUBLIC DART_SHARED_LIB)

target_compile_options(rnnoise PRIVATE -O3)

if (ANDROID)
  # Support Android 15 16k page size.
  target_link_options(rnnoise PRIVATE "-Wl,-z,max-page-size=16384")
endif()

if ((ANDROID OR OHOS) AND CMAKE_SYSTEM_PROCESSOR MATCHES "armv7")
  target_compile_options(rnnoise PRIVATE -mfpu=neon)
endif()
