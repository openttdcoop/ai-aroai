
# This file is part of AroAI.
#
# Copyright (C) 2011 - Charles Pigott (aka Lord Aro)
#
# AroAI is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 2.
# AroAI is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with OpenTTD. If not, see <http://www.gnu.org/licenses/>.



# Configuration
-include Makefile.local

FILENAME       := AroAI

shell          ?= /bin/bash
HG             ?= hg
AWK            ?= awk

REPO_REVISION  := $(shell $(HG) id -n | cut -d+ -f1 | $(AWK) '{print $$(0)+96}')
REPO_TAGS      ?= $(shell $(HG) id -t | grep -v "tip")
REPO_LAST_TAG  ?= $(shell $(HG) tags | sed -e"1d;q" | cut -d" " -f1)
REPO_USE_TAG   := $(shell [ -n "$(REPO_TAGS)" ] && echo $(REPO_TAGS) || echo $(REPO_LAST_TAG))
MA_VERSION     := $(shell [ -n "$(REPO_USE_TAG)" ] && echo $(REPO_USE_TAG) | cut -d. -f1 || echo 0)
MI_VERSION     := $(shell [ -n "$(REPO_USE_TAG)" ] && echo $(REPO_USE_TAG) | cut -d. -f2 || echo 0)
VERSION_STRING := $(shell [ -n "$(REPO_TAGS)" ] && echo $(REPO_TAGS) || echo $(MA_VERSION).$(MI_VERSION).$(REPO_REVISION))
BUNDLE_NAME    := $(FILENAME)-$(VERSION_STRING)
VER_FILE       := $(BUNDLE_NAME)/version.nut
TAR_FILENAME   := $(BUNDLE_NAME).tar
DATE_STRING    := $(shell date -u +%Y-%m-%d)
# End of configuration

_E             := @echo
_V             := @

REPO_REVISION_DUMMY  := {{REPO_REVISION}}
VERSION_STRING_DUMMY := {{VERSION_STRING}}

all: bundle_tar

bundle:
	$(_E) "[BUNDLE]"
	$(_V) rm -rf $(BUNDLE_NAME)
	$(_V) mkdir $(BUNDLE_NAME)
	$(_V) sed -e "s/$(REPO_REVISION_DUMMY)/$(REPO_REVISION)/" \
	          -e "s/$(VERSION_STRING_DUMMY)/$(VERSION_STRING)/" readme.ptxt > readme.txt
	$(_V) cp changelog.ptxt changelog.txt
	$(_V) cp *.nut $(BUNDLE_NAME)/
	$(_V) cp *.txt $(BUNDLE_NAME)/
	$(_V) cp COPYING $(BUNDLE_NAME)/
	$(_E) "/* version.nut - $(shell date -u) */" > $(VER_FILE)
	$(_E) "_major_ver  <- $(MA_VERSION);" >> $(VER_FILE)
	$(_E) "_minor_ver  <- $(MI_VERSION);" >> $(VER_FILE)
	$(_E) "_repos_ver  <- $(REPO_REVISION);" >> $(VER_FILE)
	$(_E) "_date_str   <- \"$(DATE_STRING)\";" >> $(VER_FILE)

bundle_tar: bundle
	$(_E) "[TAR]"
	$(_V) tar -cf $(TAR_FILENAME) $(BUNDLE_NAME)
	$(_V) rm -rf $(BUNDLE_NAME)
	$(_V) rm -f readme.txt
	$(_V) rm -f changelog.txt

clean:
	$(_E) "[CLEAN]"
	$(_V) rm -rf $(BUNDLE_NAME)
	$(_V) rm -rf $(TAR_FILENAME)
	$(_V) rm -f readme.txt
	$(_V) rm -f changelog.txt

test:
	$(_E) "HG:                           $(HG)"
	$(_E) "Current date:                 $(DATE_STRING)"
	$(_E) "Last Tag:                     $(REPO_LAST_TAG)"
	$(_E) "Major Version:                $(MA_VERSION)"
	$(_E) "Minor Version:                $(MI_VERSION)"
	$(_E) "Revision:                     $(REPO_REVISION)"
	$(_E) "Bundle folder:                $(BUNDLE_NAME)"
	$(_E) "Version file:                 $(VER_FILE)"
	$(_E) "Bundle filenames       tar:   $(TAR_FILENAME)"

help:
	$(_E) ""
	$(_E) "$(FILENAME) version $(REPO_REVISION) Makefile"
	$(_E) "Usage: make [option]"
	$(_E) ""
	$(_E) "options:"
	$(_E) "  all           bundle the files into a tar archive (default)"
	$(_E) "  clean         remove the files generated during bundling"
	$(_E) "  bundle        create folder $(BUNDLE_NAME)"
	$(_E) "  bundle_tar    create tar archive $(TAR_FILENAME)"
	$(_E) "  test          test to check the values of the build environment"
	$(_E) ""

.PHONY: all bundle bundle_tar clean test help
