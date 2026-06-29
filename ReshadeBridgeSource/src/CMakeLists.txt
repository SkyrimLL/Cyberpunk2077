add_library(${CMAKE_PROJECT_NAME} SHARED "")

set(PROJECT_HEADER_FILES
    ReshadeManager.hpp
    ScriptBindings.hpp
)

set(PROJECT_SRC_FILES
    Main.cpp
    ReshadeManager.cpp
    ScriptBindings.cpp
)

# Add this line to force ReShade API version 18 globally
add_compile_definitions(RESHADE_API_VERSION=18)

source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}" FILES ${PROJECT_HEADER_FILES} ${PROJECT_SRC_FILES})

set(RESHADE_INCLUDE_DIR
    "G:/Games-data/CustomMods/_Github/ExternalRepos/reshade/include"
)

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${RESHADE_INCLUDE_DIR}
)

target_sources(${CMAKE_PROJECT_NAME} PRIVATE ${PROJECT_HEADER_FILES} ${PROJECT_SRC_FILES})

target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE RED4ext::SDK)

set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
    OUTPUT_NAME "ReshadeBridge"
)

set(DEPLOY_DIR "F:/_VORTEX_MODS/cyberpunk2077/ReshadeBridge/red4ext/plugins/ReshadeBridge")

add_custom_command(TARGET ${CMAKE_PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${DEPLOY_DIR}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE:${CMAKE_PROJECT_NAME}>"
        "${DEPLOY_DIR}/ReshadeBridge.dll"
    COMMENT "Deploying ReshadeBridge.dll to ${DEPLOY_DIR}"
)
