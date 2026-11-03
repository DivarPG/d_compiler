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

# Подключаем Bison, когда появится файл грамматики.
set(PARSER_SRC ${CMAKE_SOURCE_DIR}/src/parser/d_parser.y)
if(EXISTS ${PARSER_SRC})
    find_package(BISON REQUIRED)

    BISON_TARGET(DParser
            ${PARSER_SRC}
            ${CMAKE_BINARY_DIR}/generated/d_parser.tab.cc
            DEFINES_FILE ${CMAKE_BINARY_DIR}/generated/d_parser.tab.hh
            COMPILE_FLAGS "-Wall -Wcounterexamples -v --report=lookahead,counterexamples"
    )

    ADD_FLEX_BISON_DEPENDENCY(DLexer DParser)

    # Run diagnostics on every IDE build, even when the grammar has not changed.
    add_custom_target(bison_diagnostics ALL
            COMMAND ${BISON_EXECUTABLE}
                    -Wcounterexamples
                    -v
                    --report=lookahead,counterexamples
                    -o ${CMAKE_BINARY_DIR}/generated/d_parser.diagnostics.cc
                    ${PARSER_SRC}
            COMMENT "Checking parser conflicts with Bison"
            VERBATIM
    )
endif()

add_executable(d_compiler
        ${FLEX_DLexer_OUTPUTS}
        ${BISON_DParser_OUTPUTS}
)

if(TARGET bison_diagnostics)
    add_dependencies(d_compiler bison_diagnostics)
endif()

target_include_directories(d_compiler PRIVATE
        ${CMAKE_SOURCE_DIR}/src/lexer
        ${CMAKE_BINARY_DIR}/generated
)

# На некоторых системах libfl нужна явно (yywrap и т.п.),
# но у нас в .l указано "%option noyywrap", так что обычно не требуется.
# Если линковщик ругается на yywrap — раскомментируйте:
# find_library(FLEX_LIBRARY fl)
# target_link_libraries(d_compiler PRIVATE ${FLEX_LIBRARY})

enable_testing()
add_subdirectory(tests)