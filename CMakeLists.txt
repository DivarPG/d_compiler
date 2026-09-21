cmake_minimum_required(VERSION 3.16)
project(d_compiler CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# --- Flex ---
find_package(FLEX REQUIRED)

set(LEXER_SRC ${CMAKE_SOURCE_DIR}/src/lexer/d_lexer.l)
set(LEXER_OUT ${CMAKE_BINARY_DIR}/generated/d_lexer.yy.cc)

file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/generated)

FLEX_TARGET(DLexer ${LEXER_SRC} ${LEXER_OUT})

add_executable(d_compiler
        ${FLEX_DLexer_OUTPUTS}
)

target_include_directories(d_compiler PRIVATE ${CMAKE_SOURCE_DIR}/src/lexer)

# На некоторых системах libfl нужна явно (yywrap и т.п.),
# но у нас в .l указано "%option noyywrap", так что обычно не требуется.
# Если линковщик ругается на yywrap — раскомментируйте:
# find_library(FLEX_LIBRARY fl)
# target_link_libraries(d_compiler PRIVATE ${FLEX_LIBRARY})

enable_testing()
add_subdirectory(tests)