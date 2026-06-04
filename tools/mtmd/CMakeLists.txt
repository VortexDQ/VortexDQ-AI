# mtmd - minimal build (library only)

find_package(Threads REQUIRED)

add_library(mtmd
            mtmd.cpp
            mtmd-audio.cpp
            mtmd-image.cpp
            mtmd.h
            mtmd-helper.cpp
            mtmd-helper.h
    clip.cpp
    clip.h
    clip-impl.h
    clip-model.h
    clip-graph.h
    models/models.h
    models/cogvlm.cpp
    models/conformer.cpp
    models/dotsocr.cpp
    models/exaone4_5.cpp
    models/gemma4a.cpp
    models/gemma4v.cpp
    models/gemma4ua.cpp
    models/gemma4uv.cpp
    models/glm4v.cpp
    models/granite-speech.cpp
    models/hunyuanvl.cpp
    models/internvl.cpp
    models/kimivl.cpp
    models/kimik25.cpp
    models/nemotron-v2-vl.cpp
    models/llama4.cpp
    models/llava.cpp
    models/minicpmv.cpp
    models/paddleocr.cpp
    models/pixtral.cpp
    models/qwen2vl.cpp
    models/qwen3vl.cpp
    models/mimovl.cpp
    models/qwen3a.cpp
    models/step3vl.cpp
    models/siglip.cpp
    models/whisper-enc.cpp
    models/deepseekocr.cpp
    models/deepseekocr2.cpp
    models/mobilenetv5.cpp
    models/youtuvl.cpp
    models/yasa2.cpp
            )

set_target_properties(mtmd PROPERTIES
    VERSION ${LLAMA_INSTALL_VERSION}
    SOVERSION 0
)

target_link_libraries     (mtmd PUBLIC ggml llama)
target_link_libraries     (mtmd PRIVATE Threads::Threads)
target_include_directories(mtmd PUBLIC  .)
target_include_directories(mtmd PRIVATE ../..)
target_include_directories(mtmd PRIVATE ../../vendor)
target_compile_features   (mtmd PRIVATE cxx_std_17)

if (BUILD_SHARED_LIBS)
    set_target_properties     (mtmd PROPERTIES POSITION_INDEPENDENT_CODE ON)
    target_compile_definitions(mtmd PRIVATE LLAMA_BUILD)
    target_compile_definitions(mtmd PUBLIC  LLAMA_SHARED)
endif()

if (NOT MSVC)
    target_compile_options(mtmd PRIVATE -Wno-cast-qual)
endif()

