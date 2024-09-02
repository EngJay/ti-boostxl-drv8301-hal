##
# @file meson.build
# @brief Meson module for test executables.
# 

# Include the CppUTest subproject to get cpputest_dep.
# 
cpputest_subproject = subproject('cpputest')
cpputest_dep = cpputest_subproject.get_variable('cpputest_dep')

#region FLAGS

test_compiler_flags = native_cpp_compiler.get_supported_arguments(
	'-Wno-unused-parameter',
)

#endregion FLAGS

#region SOURCES

test_files = files(
	'all_tests.cpp',
    'sanity_check.cpp',
)

#endregion SOURCES

#region EXECUTABLES

tests_exe = executable('tests_exe',
	test_files,
	dependencies: cpputest_dep,
	link_args: [],
	cpp_args: test_compiler_flags,
	native: true,
	build_by_default: false, # This option has no effect, see: https://github.com/mesonbuild/meson/issues/2518
    # override_options: [
    #     'cpp_std=c++' + cpp_language_ver, 
    #     'build.cpp_std=c++' + cpp_language_ver
    # ]
)

# Workaround to prevent the tests from being compiled by default.
# 
# This custom target prevents the tests_exe executable from being
# compiled by default. The build_by_default key above has no effect, so this
# achieves the desired effect. 
# 
custom_target('project_tests',
	output: 'dummy', # Dummy output, since custom_target needs an output.
	command: [tests_exe],
	build_by_default: false
)

run_target('tests',
	command: [tests_exe]
)

# For making a a tests-report target.
# 
# clangtidy_txt = custom_target('clangtidy.txt',
# 	output: 'clangtidy.txt',
# 	command: [
# 		clangtidy_script,
# 		# Optional user overrides.
# 		get_variable('clangtidy_options', ''),
# 		clangtidy_files
# 	],
# 	capture: true,
# 	build_always_stale: true,
# 	build_by_default: false,
# )

# # Convenience target to generate the file via a command, instead of referencing the file
# # directly (e.g., ninja -C buildresults/meson/analysis/clang-tidy/clangtidy.txt).
# alias_target('clang-tidy-report', clangtidy_txt)
