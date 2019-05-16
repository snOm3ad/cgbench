# Try to find the CPLEX, Concert, IloCplex and CP Optimizer libraries.
#
# Once done this will add the following imported targets:
#
#  cplex-library - the CPLEX library
#  cplex-concert - the Concert library
#  ilocplex - the IloCplex library
#  cplex-cp - the CP Optimizer library

include(FindPackageHandleStandardArgs)

# Check the operating system for which CMake is to build. 
if (UNIX)
    # Candidate root directories in UNIX
    set(CPLEX_ROOT_DIRS /opt/ibm/ILOG /opt/IBM/ILOG)
    # Check the architecture
    if (CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(CPLEX_ARCH x86-64)
    else ()
        set(CPLEX_ARCH x86)
    endif ()
    
    # Log the architecture type
    message(STATUS "ARCH: ${CPLEX_ARCH}")
    if (APPLE)
        # CPLEX default installation is at the user level for osx.
        set(CPLEX_ROOT_DIRS $ENV{HOME}/Applications/ ${CPLEX_ROOT_DIRS})
        # Older versions of cplex use 'darwin9_gcc4.0' as the suffix.
        foreach (suffix "osx" "darwin9_gcc4.0")
            # Append the two combinations to the list.
            set(CPLEX_LIB_PATH_SUFFIXES ${CPLEX_LIB_PATH_SUFFIXES} 
                lib/${CPLEX_ARCH}_${suffix}/static_pic)
        endforeach ()
    else ()
        # If you're on linux the naming is different.
        set(CPLEX_LIB_PATH_SUFFIXES
            lib/${CPLEX_ARCH}_sles10_4.1/static_pic 
            lib/${CPLEX_ARCH}_linux/static_pic
        )
    endif ()
    # Check the operating system
    message(STATUS "OS: ${CMAKE_SYSTEM_NAME}")
endif ()

# NOTE: This code is always executed because this variable hasn't been set.
if (NOT CPLEX_STUDIO_DIR)
    # For every candidate directory in the 'ILOG_DIRS' variable
    foreach (dir ${CPLEX_ROOT_DIRS})
        # GLOB will generate a list of files that match the <globbing-expressions>
        # that are passed as an argument and store them in the specified variable.
        file(GLOB CPLEX_STUDIO_DIRS "${dir}/CPLEX_Studio*")
        # CMake sorts alphabetically and orders in increasig order.
        list(SORT CPLEX_STUDIO_DIRS)
        # So reversing the list will put the latest version of CPLEX
        # as the first element in the list.
        list(REVERSE CPLEX_STUDIO_DIRS)
        if (CPLEX_STUDIO_DIRS)
            # Get the first element in the list
            list(GET CPLEX_STUDIO_DIRS 0 CPLEX_STUDIO_DIR_)
            message(STATUS "Found CPLEX Studio: ${CPLEX_STUDIO_DIR_}")
            break ()
        endif ()
    endforeach ()

    # In addition to normal variables, CMake also supports 'cache' variables. These
    # are stored in the special file called 'CMakeCache.txt' in the build directory
    # and they persist between CMake runs.
    #
    # Further, CMake allows cache variables to be manipulated directly via the comm-
    # and line options passed to 'cmake'.
    #
    # To do so, you use the '-D' option which allows CMake to understand you're trying
    # to set a cache variable. So, if the user wants to set the 'CPLEX_STUDIO_DIR' ma-
    # nually it is possible to do so, with
    #
    #               cmake -D CPLEX_STUDIO_DIR:PATH=/opt/IBM/ILOG/...
    #
    set(CPLEX_STUDIO_DIR ${CPLEX_STUDIO_DIR_} 
        CACHE PATH "Path to the CPLEX Studio directory"
    )

    # If you cannot find the root directory and the user did not specified one then abort.
    if (NOT CPLEX_STUDIO_DIR)
        message(FATAL_ERROR "Cannot find CPLEX root directory, abort required...")
    endif ()
endif ()


# This calls a CMake module, that first searches the file system for appropriate
# threads package for this platform, and then sets the CMAKE_THREAD_LIBS_INIT va-
# riable (and some other variables as well). 
#
# However, it does not tell CMake to link any executables against whatever threads
# library it finds. In order to do that you have to use the 'target_link_libraries'
# command as such
#
#          target_link_libraries(my_library ${CMAKE_THREAD_LIBS_INIT})
# 
# which is done further down this file.
find_package(Threads)


# Macro for finding a specific CPLEX library.
# Takes 3 arguments:
#           
#      1. the name of variable on which to store the location of the library.
#      2. the name of the library as seen in the folder structure.
#      3. the paths that hint CMake where to look for argument 2.
#
macro(find_cplex_library var name paths)
    find_library(${var} NAMES ${name}
        PATHS ${paths} 
        PATH_SUFFIXES ${CPLEX_LIB_PATH_SUFFIXES}
    )
    # If you're on UNIX then there are no specific debug libraries
    # so you just use the same as the release ones.
    if (UNIX)
        set(${var}_DEBUG ${${var}})
    else ()
    # On windows you have to look for the specific debug libraries.
        find_library(${var}_DEBUG NAMES ${name}
            PATHS ${paths} 
            PATH_SUFFIXES ${CPLEX_LIB_PATH_SUFFIXES_DEBUG}
        )
    endif ()
endmacro()

# ============================ CPLEX library ===============================
# The first thing to do is find the root directory of the cplex library.
set(CPLEX_DIR ${CPLEX_STUDIO_DIR}/cplex)

# Find the CPLEX include directory, these are the same regardless of the
# operating system. NOTE: the 'PATHS' parameter tells CMake where to look.
find_path(CPLEX_INCLUDE_DIR ilcplex/cplex.h PATHS ${CPLEX_DIR}/include)

# Find the 'cplex' library.
find_cplex_library(CPLEX_LIBRARY cplex ${CPLEX_DIR})

# Handle the QUIETLY and REQUIRED arguments and set CPLEX_FOUND to TRUE
# if all listed variables are TRUE.
find_package_handle_standard_args(CPLEX 
    DEFAULT_MSG 
    CPLEX_LIBRARY 
    CPLEX_LIBRARY_DEBUG 
    CPLEX_INCLUDE_DIR
)

if (NOT CPLEX_FOUND)
    message(FATAL_ERROR "Could not find one or more required paths for 'cplex' library")
endif()

# Cache variables have a property that allows them to be visible depending on the
# environment on which CMake is running. Normally, this only affects the way the
# variable is displayed in 'cmake-gui' which only shows non-advanced variables by
# default, note that it does not affect the way the variable is used in 'cmake'.
mark_as_advanced(CPLEX_LIBRARY CPLEX_LIBRARY_DEBUG CPLEX_INCLUDE_DIR)

# Gets executed if the CPLEX_FOUND variable was set by CMake when we called
# the 'find_package_handle_standard_args' function above. As well as if there
# is no target called 'cplex-library' defined.
if (CPLEX_FOUND AND NOT TARGET cplex-library)
    # Here we are putting the local threads library we found into a variable
    # called 'CPLEX_LINK_LIBRARIES'.
    set(CPLEX_LINK_LIBRARIES ${CMAKE_THREAD_LIBS_INIT})
    # The 'm' library is the math library!
    # NOTE: the function we extract from the math library is irrelevant.
    #       all we want to know is if the library is available to us.
    # 
    # Lastly, the 'HAVE_LIBM' is a variable in which the result of the 
    # search is stored. 
    check_library_exists(m floor "" HAVE_LIBM)
    # If the math library is available then we add it to the list of link
    # libraries that CPLEX must link to.
    if (HAVE_LIBM)
        set(CPLEX_LINK_LIBRARIES ${CPLEX_LINK_LIBRARIES} m)
    endif ()
    # On UNIX, '.a' files represent static libraries which are generated 
    # by the archive tool! Dynamic libraries on the other hand have a '.so'
    # extension on Linux and '.dylib' on OSX.
    add_library(cplex-library STATIC IMPORTED GLOBAL)
    set_target_properties(cplex-library PROPERTIES
        IMPORTED_LOCATION "${CPLEX_LIBRARY}"
        IMPORTED_LOCATION_DEBUG "${CPLEX_LIBRARY_DEBUG}"
        INTERFACE_INCLUDE_DIRECTORIES "${CPLEX_INCLUDE_DIR}"
        INTERFACE_LINK_LIBRARIES "${CPLEX_LINK_LIBRARIES}"
    )
endif ()

# ============================ Concert ===============================

set(CPLEX_CONCERT_DIR ${CPLEX_STUDIO_DIR}/concert)

# Find the Concert include directory.
find_path(CPLEX_CONCERT_INCLUDE_DIR ilconcert/ilosys.h
    PATHS ${CPLEX_CONCERT_DIR}/include
)

# Find the 'concert' library.
find_cplex_library(CPLEX_CONCERT_LIBRARY concert ${CPLEX_CONCERT_DIR})

# Handle the QUIETLY and REQUIRED arguments and set CPLEX_CONCERT_FOUND to
# TRUE if all listed variables are TRUE.
find_package_handle_standard_args(CPLEX_CONCERT 
    DEFAULT_MSG 
    CPLEX_CONCERT_LIBRARY 
    CPLEX_CONCERT_LIBRARY_DEBUG
    CPLEX_CONCERT_INCLUDE_DIR
)


if (NOT CPLEX_CONCERT_FOUND)
    message(FATAL_ERROR "Could not find one or more required paths for 'concert' library")
endif()

mark_as_advanced(CPLEX_CONCERT_LIBRARY CPLEX_CONCERT_LIBRARY_DEBUG CPLEX_CONCERT_INCLUDE_DIR)

if (CPLEX_CONCERT_FOUND AND NOT TARGET cplex-concert)
    add_library(cplex-concert STATIC IMPORTED GLOBAL)
    set_target_properties(cplex-concert PROPERTIES
        IMPORTED_LOCATION "${CPLEX_CONCERT_LIBRARY}"
        IMPORTED_LOCATION_DEBUG "${CPLEX_CONCERT_LIBRARY_DEBUG}"
        INTERFACE_COMPILE_DEFINITIONS IL_STD # Require standard compliance.
        INTERFACE_INCLUDE_DIRECTORIES "${CPLEX_CONCERT_INCLUDE_DIR}"
        INTERFACE_LINK_LIBRARIES "${CMAKE_THREAD_LIBS_INIT}"
    )
endif ()

# ============================ IloCplex ===============================

include(CheckCXXCompilerFlag)
check_cxx_compiler_flag(-Wno-long-long HAVE_WNO_LONG_LONG_FLAG)
if (HAVE_WNO_LONG_LONG_FLAG)
    # Required if -pedantic is used.
    set(CPLEX_ILOCPLEX_DEFINITIONS -Wno-long-long)
endif ()

# Find the IloCplex include directory - normally the same as the one for CPLEX
# but check if ilocplex.h is there anyway.
find_path(CPLEX_ILOCPLEX_INCLUDE_DIR ilcplex/ilocplex.h PATHS ${CPLEX_INCLUDE_DIR})

# Find the IloCplex library.
find_cplex_library(CPLEX_ILOCPLEX_LIBRARY ilocplex ${CPLEX_DIR})

# Handle the QUIETLY and REQUIRED arguments and set CPLEX_ILOCPLEX_FOUND to
# TRUE if all listed variables are TRUE.
find_package_handle_standard_args(CPLEX_ILOCPLEX 
    DEFAULT_MSG
    CPLEX_ILOCPLEX_LIBRARY 
    CPLEX_ILOCPLEX_LIBRARY_DEBUG
    CPLEX_ILOCPLEX_INCLUDE_DIR 
    CPLEX_FOUND 
    CPLEX_CONCERT_FOUND
)

mark_as_advanced(CPLEX_ILOCPLEX_LIBRARY CPLEX_ILOCPLEX_LIBRARY_DEBUG CPLEX_ILOCPLEX_INCLUDE_DIR)

if (CPLEX_ILOCPLEX_FOUND AND NOT TARGET ilocplex)
    add_library(ilocplex STATIC IMPORTED GLOBAL)
    set_target_properties(ilocplex PROPERTIES
        IMPORTED_LOCATION "${CPLEX_ILOCPLEX_LIBRARY}"
        IMPORTED_LOCATION_DEBUG "${CPLEX_ILOCPLEX_LIBRARY_DEBUG}"
        INTERFACE_INCLUDE_DIRECTORIES "${CPLEX_ILOCPLEX_INCLUDE_DIR}"
        INTERFACE_LINK_LIBRARIES "cplex-concert;cplex-library"
    )
endif ()
