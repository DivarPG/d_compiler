file(GLOB D_TEST_FILES CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/lexer/*.d)

foreach(test_file ${D_TEST_FILES})
    get_filename_component(test_name ${test_file} NAME_WE)
    add_test(
            NAME lexer_${test_name}
            COMMAND $<TARGET_FILE:d_compiler> ${test_file}
    )
endforeach()