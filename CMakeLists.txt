#
# Copyright (C) 2005-2018 MaNGOS project <http://getmangos.com/>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

cmake_minimum_required(VERSION 3.13)

set(LIBRARY_NAME achievements)

# Base files
file(GLOB achievements_source
    ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src/*.h
)
source_group("achievements" FILES ${achievements_source})

# Define base source library
set(LIBRARY_SRCS
    ${achievements_source}
)

add_library(${LIBRARY_NAME} STATIC ${LIBRARY_SRCS})

# Define ENABLE_PLAYERBOTS if needed
if(BUILD_PLAYERBOTS)
    target_include_directories(${LIBRARY_NAME} PRIVATE
        ${CMAKE_SOURCE_DIR}/src/modules/PlayerBots
        ${CMAKE_SOURCE_DIR}/dep/g3dlite
    )
    target_compile_definitions(${LIBRARY_NAME} PRIVATE ENABLE_PLAYERBOTS)
endif()

# Module framework include and definitions
target_include_directories(${LIBRARY_NAME} PRIVATE
    ${CMAKE_SOURCE_DIR}/src/modules/modules/src
)
target_compile_definitions(${LIBRARY_NAME} PRIVATE
    ENABLE_MODULES
    ENABLE_ACHIEVEMENTS
)

# Expansion flag
if(${CMAKE_PROJECT_NAME} MATCHES "Classic")
    target_compile_definitions(${LIBRARY_NAME} PRIVATE EXPANSION=0)
elseif(${CMAKE_PROJECT_NAME} MATCHES "TBC")
    target_compile_definitions(${LIBRARY_NAME} PRIVATE EXPANSION=1)
elseif(${CMAKE_PROJECT_NAME} MATCHES "WoTLK")
    target_compile_definitions(${LIBRARY_NAME} PRIVATE EXPANSION=2)
endif()

target_link_libraries(${LIBRARY_NAME}
    modules
    shared
    RecastNavigation::Detour
)

if(UNIX)
    # FreeBSD and NetBSD do not have libdl
    if(NOT (CMAKE_SYSTEM_NAME STREQUAL "FreeBSD" OR CMAKE_SYSTEM_NAME STREQUAL "NetBSD"))
        target_link_libraries(${LIBRARY_NAME} dl)
    endif()
endif()

set_target_properties(${LIBRARY_NAME} PROPERTIES
    PROJECT_LABEL "Achievements"
    FOLDER        "Modules"
)

# Install config files
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/src/achievements.conf.dist.in
    ${CMAKE_CURRENT_BINARY_DIR}/achievements.conf.dist
)
if(NOT CONF_INSTALL_DIR)
    set(CONF_INSTALL_DIR ${CONF_DIR})
endif()
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/achievements.conf.dist
    DESTINATION ${CONF_INSTALL_DIR}
)