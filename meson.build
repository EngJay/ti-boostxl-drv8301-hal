# @file meson.build
# @brief Top-level Meson module for the TI BOOSTXL-DRV8301 HAL.
#
# This module:
#
#   - Defines the Meson project.
#   - Includes and specifies the options for the project.
#   - Includes and specifies the compiler and linker flags.
#   - Includes build support.
#   - Includes and specifies the sources files and includes.
#   - Includes and configures the executables.
#   - Includes and configures the tools used.
#
# This module depends on the presence of the the build-systems repo included as
# a submodule in the root of the project or symlinked into the root if this is
# a Meson subproject.
#
# @author Jason Scott <reachme@jasonpscott.com>
# @date 4 May 2024
#
# @copyright Copyright (c) 2024
#
project(
    'ti-drv8301-hal',
    ['c', 'cpp'],
    default_options: [
        'debug=false', # Defaults to release build.
        'warning_level=3',
        'optimization=2',
        # `build.*` options affect `native: true targets`,
        # plain options affect `native: false` targets.
        'c_std=c11',
        'build.c_std=c11',
        'cpp_std=c++11',
        'build.cpp_std=c++11',
    ],
    meson_version: '>=1.1.0',
    version: '0.1.0',
)

# Check for miniumum required GCC for ARM version.
#
if meson.is_cross_build()
    target_compiler = meson.get_compiler('c', native: false)
    if target_compiler.get_id() == 'gcc' and target_compiler.version().version_compare('<9.0') and target_architecture == 'arm'
        error(
            'This project requires gcc-arm-none-eabi v9.0 or later. See README.md for more information.',
        )
    endif
endif

# Get build properties from cross files.
#
#
#
vendor = meson.get_external_property('vendor', 'native', native: false)
board = meson.get_external_property('board', 'native', native: false)
os = meson.get_external_property('os', 'native', native: false)
compiler = meson.get_external_property('compiler', 'gcc-11', native: false)
lang = meson.get_external_property('language', 'c', native: false)

# Pick up common compiler variables.
#
# The compiler module provides:
#
#   - desired_common_warning_flags
#   - desired_common_compile_flags
#
# These flags are picked up by the check-and-apply-flags module and added
# directly to the build if the compiler supports them. The flags are listed in
# the console output during build configuration.
#
subdir('build-systems/meson/compiler')

# Pick-up C language module.
#
# The C module provides:
#
#   - native_c_compiler
#   - host_c_compiler
#   - native_c_compiler_id
#   - host_c_compiler_id
#   - desired_c_compile_flags
#   - desired_native_c_compile_flags
#   - l_flags (overridable defaults)
#
# The compiler variables are used by the check-and-apply-flags module for
# checking support for flags.
#
# The l_flags variable provides basic default linker flags and should be
# overriden by defining it in the build config. The linker flags are not checked
# for support because the linker too often provides false failures, so the
# linker flags must be checked and set manually.
#
subdir('build-systems/meson/compiler/c')

# Pick up C++ language module.
#
# The C++ module provides:
#
#   - native_cpp_compiler
#   - host_cpp_compiler
#   - native_cpp_compiler_id
#   - host_cpp_compiler_id
#   - desired_cpp_compile_flags
#   - desired_native_cpp_compile_flags
#   - l_flags (overridable defaults)
#
subdir('build-systems/meson/compiler/cpp')

# Create linker-related arrays.
#
# This provides arrays for linker flags for C and C++. They are provided by this
# top-level module to all included modules.
#
c_l_flags = []
cpp_l_flags = []
linker_script_path = ''

# Language Versions
#
# Sets the built-in compiler options for language versions with default of C11
# and C++11. The variables c_language_ver and cpp_language_ver are provided by
# the cxx and cppxx cross files, so these will be automatically set when a cross
# string is supplied.
#
c_language_ver = get_variable('c_language_ver', '11')
cpp_language_ver = get_variable('cpp_language_ver', '11')

# Build type.
#
build_is_debug = get_option('debug')
if build_is_debug
    # Specify build as debug and leave C assertions enabled.
    add_project_arguments('-DDEBUG', language: ['c', 'cpp'])
    add_project_arguments('-DDEBUG', language: ['c', 'cpp'], native: true)
else
    # Specify build as release and disable C assertions.
    add_project_arguments('-DRELEASE -DNDEBUG', language: ['c', 'cpp'])
    add_project_arguments('-DRELEASE -DNDEBUG', language: ['c', 'cpp'], native: true)
endif

# Features to include.

# Enables SEGGER SystemView support.
#
segger_systemview_is_enabled = get_option('enable-segger-systemview')
if segger_systemview_is_enabled
    add_project_arguments('-DSEGGER_SYSTEMVIEW_ENABLED', language: ['c', 'cpp'])
    add_project_arguments(
        '-DSEGGER_SYSTEMVIEW_ENABLED',
        language: ['c', 'cpp'],
        native: true,
    )
endif

# Enables the UART logging sink.
#
uart_logging_is_enabled = get_option('enable-uart-logging')
if uart_logging_is_enabled
    # TODO Add uart logging flags and sources.
endif

#region FLAGS

# Disables compiler builtins.
#
if get_option('disable-builtins')
    desired_c_compile_flags += '-fno-builtin'
endif

# Disables the built-in stack protection.
#
if get_option('disable-stack-protection')
    desired_c_compile_flags += '-fno-stack-protector'
endif

# Enables pedantic compiler warnings.
#
if get_option('enable-pedantic')
    desired_c_compile_flags += '-pedantic'
else
    desired_c_compile_flags += '-Wno-pedantic'
endif

# Enables pedantic compiler errors.
#
if get_option('enable-pedantic-error')
    desired_c_compile_flags += '-pedantic-error'
endif

# Add additonal project-specific C compiler flags.
#
# NOTE: desired_c_compile_flags is provided by subdir('build-systems/meson/compiler/c').
#
# desired_c_compile_flags += [
#     '-MMD',
#     '-MP',
#     '--specs=nosys.specs',
#     '--specs=nano.specs',
# ]

# Include support for generating map file linker flag.
#
# This provides the map_file variable that supports .format('file_name_here') to
# generate the linker flag for generating a map file.
#
subdir('build-systems/meson/linker/linker-map')

# Board-specific configuration.
#
# NOTE: board is provided by the board cross file that was specified.
#
# if board == 'nucleo-f767zi'
#     desired_c_compile_flags += [
#         '-DSTM32F767xx',
#         '-DUSE_HAL_DRIVER',
#     ]
#     desired_cpp_compile_flags += [
#         '-DSTM32F767xx',
#         '-DUSE_HAL_DRIVER',
#     ]

#     # Add board-specific linker flags.
#     #
#     linker_script_path = meson.project_source_root() / 'src' / vendor / board / os / compiler / lang + c_language_ver / 'bsp/st/nucleo-f767zi/linker_scripts/STM32F767ZITX_FLASH.ld'
#     c_l_flags += [
#         '-T' + linker_script_path, map_file.format('stm32f767zi'), # The map file will be written to the root of the build directory.
#         '-static',
#         '--specs=nosys.specs',
#         '--specs=nano.specs',
#         '-lm',
#     ]
#     cpp_l_flags += [
#         '-T' + linker_script_path, map_file.format('stm32f767zi'), # The map file will be written to the root of the build directory.
#         '-static',
#         '--specs=nosys.specs',
#         '--specs=nano.specs',
#         '-lm',
#     ]
# endif

# Combine compile flags into structure expected by the check-and-apply-flags meson module.
#
compile_settings_list = [
    {
        'lang': 'c',
        'compiler': host_c_compiler,
        'flags': desired_c_compile_flags,
        'isnative': false,
    },
    {
        'lang': 'c',
        'compiler': native_c_compiler,
        'flags': desired_native_c_compile_flags,
        'isnative': true,
    },
    {
        'lang': 'cpp',
        'compiler': host_cpp_compiler,
        'flags': desired_cpp_compile_flags,
        'isnative': false,
    },
    {
        'lang': 'cpp',
        'compiler': native_cpp_compiler,
        'flags': desired_native_cpp_compile_flags,
        'isnative': true,
    },
]

# Process the compilation flags.
#
subdir('build-systems/meson/compiler/check-and-apply-flags')

#endregion FLAGS

#region BUILD SUPPORT

# Provides support for unit testing.
#
# subdir('meson/test/cmocka')

# Provides the commands for conversion of .elf to .hex and .bin.
#
subdir('build-systems/meson/objcopy')

#endregion BUILD SUPPORT

#region PROJECT TOOLS

# Override default format dirs.
#
clangformat_targets = [meson.project_source_root()]
clangformat_excludes = []

# Directories and files to be analyzed by vale.
#
vale_files = [
    meson.project_source_root() / 'docs',
    meson.project_source_root() / 'README.md',
]

# Vale exits with an error code when an error is found but that breaks the Meson
# capture, so set Vale to exit nicely.
#
vale_exit_nicely = true

# Configure Doxygen description, inputs, output dir, and excludes.
#
doxygen_description = 'TI BOOSTXL-DRV8301 HAL.'
doxygen_input = [
    meson.project_source_root() / 'README.md',
]
doxygen_output_dir = meson.project_source_root() / 'docs/doxygen'

# Exclude the monorepo files that are considered external to the subprojects.
#
doxygen_excludes = [
    '*/ext/*',
]

# Configure coverxygen for doc coverage reporting.
#
coverxygen_src_dir = meson.project_source_root()

# Paths for complexity analysis.
#
lizard_paths = [meson.project_source_root() / 'src']

# Directories to be analyzed by sloccount.
#
sloccount_dirs = [
    meson.project_source_root() / 'src',
]

# Reduce dup detection since this project is not critical.
#
jscpd_mode = 'mild'

# Specify paths to be analyzed for duplicated code.
#
jscpd_dirs = [meson.project_source_root() / 'src']

#endregion PROJECT TOOLS

#region VARIANT TOOLS

# Override default cppcheck dirs.
#
cppcheck_paths = [
    meson.current_source_dir() / 'src',
]

# Add all project include paths to cppcheck.
#
cppcheck_includes = []

# Exclude dirs from cppcheck, if needed.
#
cppcheck_excludes = []

# Set cppchecks to run.
#
# Options:  all (only recommended when the whole program is scanned)
#           warning
#           style (default) (enables style, warning, performance, portability)
#           performance
#           portability
#           information
#           unusedFunction
#           missingInclude
#
# cppcheck_checks = ['style']

# Files to be analyzed by clang-tidy.
#
clangtidy_files = [
    meson.current_source_dir() / 'src/**/*.c',
    meson.current_source_dir() / 'src/**/*.h',
]

#endregion VARIANT TOOLS

#region SOURCES

# Include abstract sources.
#
# These are the abstract sources of the application and do not have a concrete
# implementation for specific hardware. The specific variant sources that
# provide appropriate implementations are included based on the cross string
# provided to Meson.
# subdir('src')

# Including the specific variant of sources based on the cross argument string.
#
# This module is respionsible for providing the tool arrays and settings to the
# src module subdir-ed here. These arrays and settings are added to by the
# modules included through the source dirs so a full set of sources for the
# particular version specified are included.
#
# subdir('src' / vendor / board / os / compiler / lang + c_language_ver)

#endregion SOURCES

# Include tool modules now that configuration is set and soures are included.
#
# Including these must come after the creation of the override
# arrays and settings so they are picked up by these tool modules.
#
subdir('build-systems/meson/analysis/clang-tidy')
subdir('build-systems/meson/analysis/complexity')
subdir('build-systems/meson/analysis/cppcheck')
subdir('build-systems/meson/analysis/jscpd')
subdir('build-systems/meson/analysis/leasot')
subdir('build-systems/meson/analysis/sloccount')
subdir('build-systems/meson/analysis/vale')
subdir('build-systems/meson/docs/doxygen')
subdir('build-systems/meson/docs/coverxygen')
subdir('build-systems/meson/format')

#region TESTS

subdir('src/test')

#endregion TESTS
