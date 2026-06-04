# llama-ui - minimal stub (embedded UI disabled)

set(TARGET llama-ui)

# Generate a stub ui.h
set(UI_H "${CMAKE_CURRENT_BINARY_DIR}/ui.h")
set(UI_CPP "${CMAKE_CURRENT_BINARY_DIR}/ui.cpp")

file(WRITE ${UI_H}
"#ifndef LLAMA_UI_H\n"
"#define LLAMA_UI_H\n"
"#include <string>\n"
"namespace ui {\n"
"std::string get_content(const std::string &path);\n"
"}\n"
"#endif\n")

file(WRITE ${UI_CPP}
"#include \"ui.h\"\n"
"namespace ui {\n"
"std::string get_content(const std::string &path) { return \"\"; }\n"
"}\n")

add_library(${TARGET} STATIC ${UI_CPP})
target_include_directories(${TARGET} PUBLIC ${CMAKE_CURRENT_BINARY_DIR})
target_compile_features(${TARGET} PRIVATE cxx_std_17)

