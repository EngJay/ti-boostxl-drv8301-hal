##
# @file Makefile
# @brief Standardized Makefile shim for Meson builds.
# 
# Usage
# 
# make [OPTIONS] <target>
#   Options:
#     > MESON Override meson tool - useful for testing meson prereleases and forks.
#     > VERBOSE Show verbose output for Make rules. Default: 0. Enable with 1.
#     > BUILD_DIR Directory for build results. Default: build.
#     > OPTIONS Configuration options to pass to a build. Default: empty.
#     > LTO Enable LTO builds. Default: 0. Enable with 1.
#     > DEBUG Enable a debug build. Default: 0 (release). Enable with 1.
#     > CROSS Enable a Cross-compilation build. Default is arm:cortex-m7-hardfloat-sp.
#          - Example: make CROSS=arm:cortex-m7-hardfloat-sp
#     > NATIVE Supply an alternative native toolchain by name.
#          - Example: make NATIVE=gcc-9
#          - Additional files can be layered by adding additional
#            args separated by ':'
#          - Example: make NATIVE=gcc-9:gcc-gold
#     > SANITIZER Compile with support for a Clang/GCC Sanitizer.
#          Options are: none (default), address, thread, undefined, memory,
#          and address,undefined' as a combined option
# Build Targets
#   default: build all default targets ninja knows about
#   test: build and run unit test programs
#   test-coverage: build and run unit test programs with coverage reporting
#   package: build the project, generate docs, and create a release package
#   clean: clean build artifacts, keeping build files in place
#   distclean: remove the configured build output directory
#   reconfig: reconfigure an existing build output folder with new settings
# Documentation Targets
#   docs: generate documentation
#   docs-ci: generate documentation for use in CI process for coverage reporting
#   docs-coverage: run documentation comment coverage and generate a report
#   docs-coverage-browsable: run documentation comment coverage and generate a browsable report
# Code Formating Targets
#   format: run clang-format on codebase
#   format-patch: generate a patch file with formatting changes
# Static Analysis Targets
#   cppcheck: run cppcheck
#   cppcheck-report: run cppcheck and generate a report
#   complexity: run complexity analysis with lizard, only print violations
#   complexity-full: run complexity analysis with lizard, print full results
#   complexity-report: run complexity analysis with lizard, generate a report
#   dups: run duplicates detection
#   dups-report: run duplicates detection, generate a report
#   dups-report-browsable: run duplicates detection, generate a browsable report
#   sloccount: run line of code and effort analysis
#   sloccount-full: run line of code and effort analysis, with results for every file
#   sloccount-report: run line of code and effort analysis + save to file for CI
#   sloccount-full-report: run line of code and effort analysis, with results for every file
#   tasks: run in-code task detection
#   tasks-report: run in-code task detection, generate a report
#   tidy: run clang-tidy linter
#   tidy-fix: run clang-tidy linter and apply fixes
#   tidy-report: run clang-tidy linter and generate a report
#   vale: lint project documentation against configured style guide
#   vale-report: lint project documentation and generate a report
# Verification Targets
#   frama-c-wp: run frama-c with the WP and RTE plugins
#   frama-c-wp-report: run frama-c with the WP and RTE plugins and generate a report
#   frama-c-eva: run frama-c with the Eva plugin
#   frama-c-eva-report: run frama-c with the Eva plugin and generate a report
# 
# @author Jason Scott <reachme@jasonpscott.com>
# @date 2024-09-02
# 

# Enables verbosity for this Makefile.
#
# Set this to see all commands and output.
#
VERBOSE ?= 0

ifeq ($(VERBOSE),1)
export Q :=
export VERBOSE := 1
else
export Q := @
export VERBOSE := 0
endif

# The meson executable to use.
#
# This can be changed to try out pre-releases or other versions of Meson.
#
MESON ?= meson

# Build directory.
#
# The directory to set as the Meson build directory.
#
BUILD_DIR ?= build

# Tests build directory.
#
# The directory to set as the Meson build directory for the tests build.
#
TESTS_BUILD_DIR ?= testsbuild

# Default location of the ninja build file.
#
# This is used in a Make rule below for running meson if the file needs to be
# created.
#
CONFIGURED_BUILD_DEP = $(BUILD_DIR)/build.ninja

# Location of the test coverage ninja build file.
# 
# This is used in a Make rule below for running meson if the file needs to be
# created.
#  
CONFIGURED_TESTS_BUILD_DEP = $(BUILD_DIR)/$(TESTS_BUILD_DIR)/build.ninja

# Provide additional Meson command options.
# 
# See the Meson commands reference for the command being run:
# https://mesonbuild.com/Commands.html
#
# Example:
# 
# 	> make OPTIONS="-Denable-pedantic=true"
# 
OPTIONS ?=

# Enables link-time optimization.
#
LTO ?= 0

# Cross-compile target.
#
# Cross files can be layered by providing a : delimited list. For
# example, arm:cortex-m7-hardfloat-sp will add the arm.txt and the 
# cortex-m7-hardfloat-sp.txt cross files in the order they appear in the list.
# 
# Options: 	See the supported cross targets in the main README.
#
CROSS ?=

# Sets the native compile target.
#
# Options: 	See the directory of native files in the build-systems repo.
#
NATIVE ?=

# Default to native gcc-14 build if neither CROSS nor NATIVE is set.
# 
ifeq ($(CROSS),)
  ifeq ($(NATIVE),)
    NATIVE := gcc-14
  endif
endif

# Enables debug build. 
#
# When set to 1, the buildtype is set to debug, debug = true, optimization = g,
# and the appropriate macros are defined.
#
DEBUG ?= 0

# Enables SEGGER SystemView.
#
# When set to 1, the enable-segger-systemview option is set to true, which swaps
# in patched files and sets the macro used to include SystemView in the sources.
#
SYSTEMVIEW ?= 0

# Set to use a santizer.
#
# Options: 	none (default)
# 			address
# 			thread
# 			undefined
# 			memory
#			address,undefined as a combined option
# 
# NOTE: Sanitizers are not supported by arm-none-eabi-gcc.
# 
SANITIZER ?= none

# Options internal to Meson.
#
# This is used to collect the internal options to be passed to Meson.
#
INTERNAL_OPTIONS =

ifeq ($(LTO),1)
	INTERNAL_OPTIONS += -Db_lto=true -Ddisable-builtins=true
endif

ifneq ($(CROSS),)
	# Split into two strings, first is arch, second is chip.
	CROSS_2 := $(subst :, ,$(CROSS))
	INTERNAL_OPTIONS += $(foreach FILE,$(CROSS_2),--cross-file=build-systems/meson/cross/$(FILE).txt)
endif

# TODO Figure out what to do with this, #18.
ifneq ($(NATIVE),)
	# Split into words delimited by :
	NATIVE_2 := $(subst :, ,$(NATIVE))
	INTERNAL_OPTIONS += $(foreach FILE,$(NATIVE_2),--native-file=build-systems/meson/native/$(FILE).txt)
endif

ifeq ($(DEBUG),1)
	INTERNAL_OPTIONS += -Ddebug=true -Doptimization=g
endif

ifeq ($(SYSTEMVIEW),1)
	INTERNAL_OPTIONS += -Denable-segger-systemview=true
endif

ifneq ($(SANITIZER),none)
	INTERNAL_OPTIONS += -Db_sanitize=$(SANITIZER) -Db_lundef=false
endif

all: default

.PHONY: default
default: | $(CONFIGURED_BUILD_DEP)
	$(Q)ninja -C $(BUILD_DIR)

.PHONY: test
test: | $(CONFIGURED_TESTS_BUILD_DEP)
	$(Q)ninja -C $(BUILD_DIR)/$(TESTS_BUILD_DIR) tests

.PHONY: test-coverage
test-coverage: | $(CONFIGURED_TESTS_BUILD_DEP)
	$(Q)ninja -C $(BUILD_DIR)/$(TESTS_BUILD_DIR) tests
	$(Q) ninja -C $(BUILD_DIR)/$(TESTS_BUILD_DIR) coverage

.PHONY: docs
docs: | $(CONFIGURED_BUILD_DEP)
	$(Q)ninja -C $(BUILD_DIR) docs

.PHONY: docs-ci
docs-ci: | $(CONFIGURED_BUILD_DEP)
	$(Q)ninja -C $(BUILD_DIR) docs-ci

.PHONY: docs-coverage
docs-coverage: | $(CONFIGURED_BUILD_DEP)
	$(Q)ninja -C $(BUILD_DIR) docs-coverage

.PHONY: docs-coverage-browsable
docs-coverage-browsable: | $(CONFIGURED_BUILD_DEP)
	$(Q)ninja -C $(BUILD_DIR) docs-coverage-lcov
	$(Q)ninja -C $(BUILD_DIR) docs-coverage-browsable

.PHONY: package
package: default docs
	$(Q)ninja -C $(BUILD_DIR) package
	$(Q)ninja -C $(BUILD_DIR) package-native

# Manually Reconfigure a target, esp. with new options.
# 
.PHONY: reconfig
reconfig:
	$(Q) $(MESON) setup $(BUILD_DIR) --reconfigure $(INTERNAL_OPTIONS) $(OPTIONS)

# Runs whenever the build has not been configured successfully.
# 
$(CONFIGURED_BUILD_DEP):
	$(Q) $(MESON) setup $(BUILD_DIR) $(INTERNAL_OPTIONS) $(OPTIONS)

# Runs whenever the test build has not been configured successfully.
#
# A second test-specific build nested in the regular build. This allows
# test-specific flags and build settings to be enforced with configuring or
# rebuilding the regular build.
#
$(CONFIGURED_TESTS_BUILD_DEP): | $(CONFIGURED_BUILD_DEP)
	$(eval INTERNAL_OPTIONS += -Ddebug=true -Doptimization=0 -Db_coverage=true)
	$(Q) $(MESON) setup $(BUILD_DIR)/$(TESTS_BUILD_DIR) $(INTERNAL_OPTIONS) $(OPTIONS)

.PHONY: cppcheck
cppcheck: | $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) cppcheck

.PHONY: cppcheck-report
cppcheck-report: | $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) cppcheck-report

.PHONY: complexity
complexity: | $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) complexity

.PHONY: complexity-report
complexity-report: | $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) complexity-report

.PHONY: complexity-full
complexity-full: | $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) complexity-full

.PHONY: dups
dups: | $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) dups

.PHONY: dups-report
dups-report: | $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) dups-report

.PHONY: dups-report-browsable
dups-report-browsable: | $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) dups-report-browsable

.PHONY: tidy
tidy: $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) clang-tidy

.PHONY: tidy-fix
tidy-fix: $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) clang-tidy-fix

.PHONY: tidy-report
tidy-report: $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) clang-tidy-report

.PHONY: sloccount
sloccount: $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) sloccount

.PHONY: sloccount-full
sloccount-full: $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) sloccount-full

.PHONY: sloccount-report
sloccount-report: $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) sloccount-report

.PHONY: sloccount-full-report
sloccount-full-report: $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) sloccount-full-report

.PHONY: tasks
tasks: $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) tasks

.PHONY: tasks-report
tasks-report: $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) tasks-report

.PHONY: vale
vale: $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) vale

.PHONY: vale-report
vale-report: $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) vale-report

.PHONY: frama-c-wp
frama-c-wp: $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) frama-c-wp

.PHONY: frama-c-wp-report
frama-c-wp-report: $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) frama-c-wp-report

.PHONY: frama-c-eva
frama-c-eva: $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) frama-c-eva

.PHONY: frama-c-eva-report
frama-c-eva-report: $(CONFIGURED_BUILD_DEP)
	$(Q) ninja -C $(BUILD_DIR) frama-c-eva-report

.PHONY: format
format: $(CONFIGURED_BUILD_DEP)
	$(Q)ninja -C $(BUILD_DIR) format

.PHONY : format-patch
format-patch: $(CONFIGURED_BUILD_DEP)
	$(Q)ninja -C $(BUILD_DIR) format-patch

.PHONY: clean
clean:
	$(Q) if [ -d "$(BUILD_DIR)" ]; then ninja -C build clean; fi

.PHONY: distclean
distclean:
	$(Q) rm -rf $(BUILD_DIR)

.PHONY : help
help :
	@echo "usage: make [OPTIONS] <target>"
	@echo "  Options:"
	@echo "    > MESON Override meson tool - useful for testing meson prereleases and forks."
	@echo "    > VERBOSE Show verbose output for Make rules. Default: 0. Enable with 1."
	@echo "    > BUILD_DIR Directory for build results. Default: build."
	@echo "    > OPTIONS Configuration options to pass to a build. Default: empty."
	@echo "    > LTO Enable LTO builds. Default: 0. Enable with 1."
	@echo "    > DEBUG Enable a debug build. Default: 0 (release). Enable with 1."
	@echo "    > CROSS Enable a Cross-compilation build. Default is arm:cortex-m7-hardfloat-sp."
	@echo "         - Example: make CROSS=arm:cortex-m7-hardfloat-sp"
	@echo "    > NATIVE Supply an alternative native toolchain by name."
	@echo "         - Example: make NATIVE=gcc-9"
	@echo "         - Additional files can be layered by adding additional"
	@echo "           args separated by ':'"
	@echo "         - Example: make NATIVE=gcc-9:gcc-gold"
	@echo "    > SANITIZER Compile with support for a Clang/GCC Sanitizer."
	@echo "         Options are: none (default), address, thread, undefined, memory,"
	@echo "         and address,undefined' as a combined option"
	@echo "Build Targets"
	@echo "  default: build all default targets ninja knows about"
	@echo "  test: build and run unit test programs"
	@echo "  test-coverage: build and run unit test programs with coverage reporting"
	@echo "  package: build the project, generate docs, and create a release package"
	@echo "  clean: clean build artifacts, keeping build files in place"
	@echo "  distclean: remove the configured build output directory"
	@echo "  reconfig: reconfigure an existing build output folder with new settings"
	@echo "Documentation Targets"
	@echo "  docs: generate documentation"
	@echo "  docs-ci: generate documentation for use in CI process for coverage reporting"
	@echo "  docs-coverage: run documentation comment coverage and generate a report"
	@echo "  docs-coverage-browsable: run documentation comment coverage and generate a browsable report"
	@echo "Code Formating Targets"
	@echo "  format: run clang-format on codebase"
	@echo "  format-patch: generate a patch file with formatting changes"
	@echo "Static Analysis Targets"
	@echo "  cppcheck: run cppcheck"
	@echo "  cppcheck-report: run cppcheck and generate a report"
	@echo "  complexity: run complexity analysis with lizard, only print violations"
	@echo "  complexity-full: run complexity analysis with lizard, print full results"
	@echo "  complexity-report: run complexity analysis with lizard, generate a report"
	@echo "  dups: run duplicates detection"
	@echo "  dups-report: run duplicates detection, generate a report"
	@echo "  dups-report-browsable: run duplicates detection, generate a browsable report"
	@echo "  sloccount: run line of code and effort analysis"
	@echo "  sloccount-full: run line of code and effort analysis, with results for every file"
	@echo "  sloccount-report: run line of code and effort analysis + save to file for CI"
	@echo "  sloccount-full-report: run line of code and effort analysis, with results for every file"
	@echo "  tasks: run in-code task detection"
	@echo "  tasks-report: run in-code task detection, generate a report"
	@echo "  tidy: run clang-tidy linter"
	@echo "  tidy-fix: run clang-tidy linter and apply fixes"
	@echo "  tidy-report: run clang-tidy linter and generate a report"
	@echo "  vale: lint project documentation against configured style guide"
	@echo "  vale-report: lint project documentation and generate a report"
	@echo "Verification Targets"
	@echo "  frama-c-wp: run frama-c with the WP and RTE plugins"
	@echo "  frama-c-wp-report: run frama-c with the WP and RTE plugins and generate a report"
	@echo "  frama-c-eva: run frama-c with the Eva plugin"
	@echo "  frama-c-eva-report: run frama-c with the Eva plugin and generate a report"
