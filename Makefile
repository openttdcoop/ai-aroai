# Configuration
-include Makefile.local

FILENAME       := AroAI

shell          ?= /bin/sh
HG             ?= hg

REPO_REVISION  ?= $(shell $(HG) id -n | cut -d+ -f1)
REPO_REVISION  := $(shell let tmp = $$REPO_REVISION + 96; echo tmp)
REPO_TAGS      ?= $(shell $(HG) id -t | grep -v "tip")
REPO_LAST_TAG  ?= $(shell $(HG) tags | sed -e"1d;q" | cut -d" " -f1)
REPO_USE_TAG   := $(shell [ -n "$(REPO_TAGS)" ] && echo $(REPO_TAGS) || echo $(REPO_LAST_TAG))
MA_VERSION     := $(shell [ -n "$(REPO_USE_TAG)" ] && echo $(REPO_USE_TAG) | cut -d. -f1 || echo 0)
MI_VERSION     := $(shell [ -n "$(REPO_USE_TAG)" ] && echo $(REPO_USE_TAG) | cut -d. -f2 || echo 0)
VERSION_STRING := $(shell [ -n "$(REPO_TAGS)" ] && echo $(REPO_TAGS) || echo $(MA_VERSION).$(MI_VERSION).$(REPO_REVISION))
BUNDLE_NAME    := $(FILENAME)-$(VERSION_STRING)
VER_FILE       := $(BUNDLE_NAME)/version.nut
TAR_FILENAME   := $(BUNDLE_NAME).tar
# End of configuration

_E             := @echo
_V             := @

all: bundle_tar

bundle_tar:
	$(_E) "[TAR]"
	$(_V) $(shell $(HG) archive -X glob:.* -X path:Makefile $(BUNDLE_NAME))
	$(_V) echo "/* version.nut - $(shell date -u) */" > $(VER_FILE)
	$(_V) echo "_major_ver  <- $(MA_VERSION);" >> $(VER_FILE)
	$(_V) echo "_minor_ver  <- $(MI_VERSION);" >> $(VER_FILE)
	$(_V) echo "_repos_ver  <- $(REPO_REVISION);" >> $(VER_FILE)
	$(_V) tar -cf $(TAR_FILENAME) $(BUNDLE_NAME)

clean:
	$(_E) "[Clean]"
	$(_V) -rm -r -f $(BUNDLE_NAME)
	$(_V) -rm -r -f $(TAR_FILENAME)

test:
	$(_E) "HG:                           $(HG)"
	$(_E) "Last Tag:                     $(REPO_LAST_TAG)"
	$(_E) "Major Version:                $(MA_VERSION)"
	$(_E) "Minor Version:                $(MI_VERSION)"
	$(_E) "Revision:                     $(REPO_REVISION)"
	$(_E) "Build folder:                 $(BUNDLE_NAME)"
	$(_E) "Version file:                 $(VER_FILE)"
	$(_E) "Bundle filenames       tar:   $(TAR_FILENAME)"

help:
	$(_E) ""
	$(_E) "$(FILENAME) version $(REPO_REVISION) Makefile"
	$(_E) "Usage : make [option]"
	$(_E) ""
	$(_E) "options:"
	$(_E) "  all           bundle the files (default)"
	$(_E) "  clean         remove the files generated during bundling"
	$(_E) "  bundle_tar    create bundle $(TAR_FILENAME)"
	$(_E) "  test          test to check the value of environment"
	$(_E) ""

.PHONY: all test clean help
