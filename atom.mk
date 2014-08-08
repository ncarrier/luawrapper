LOCAL_PATH := $(call my-dir)

###############################################################################
# luawrapper
###############################################################################

include $(CLEAR_VARS)

LOCAL_MODULE := luawrapper
LOCAL_DESCRIPTION := Static library for building an autonomous executable from \
	a lua script and it's dependencies
LOCAL_CATEGORY_PATH := scripting/lua

LOCAL_GENERATED_SRC_FILES := \
	libelf_msize.c \
	libelf_fsize.c \
	libelf_convert.c

LOCAL_SRC_FILES := luawrapper.c \
	$(call all-c-files-under,lua) \
	$(call all-c-files-under,libelf)

$(LOCAL_MODULE)_BUILD_DIR := $(call local-get-build-dir)
# no need to put native-elf-format.h, because it is already in prerequisites
LOCAL_CUSTOM_TARGETS := \
	$(LOCAL_GENERATED_SRC_FILES)
LOCAL_PREREQUISITES := \
	$($(LOCAL_MODULE)_BUILD_DIR)/native-elf-format.h

$(LOCAL_MODULE) := $($(LOCAL_MODULE)_BUILD_DIR)/$(LOCAL_MODULE)

LOCAL_C_INCLUDES := \
	$(LOCAL_PATH)/libelf/ \
	$(LOCAL_PATH)/libelf/common/ \
	$($(LOCAL_MODULE)_BUILD_DIR)

LOCAL_EXPORT_C_INCLUDES := \
	$(LOCAL_PATH)

LOCAL_EXPORT_LDLIBS := -static -lm

$($(LOCAL_MODULE)_BUILD_DIR)/libelf_%.c: $(LOCAL_PATH)/libelf/libelf_%.m4
	$(Q) echo "generate m4 generated $@ for $(PRIVATE_MODULE)"
	$(Q) (cd $(PRIVATE_PATH)/libelf/; m4 -D SRCDIR=. $^ > $@)

$($(LOCAL_MODULE)_BUILD_DIR)/native-elf-format.h:
	$(Q) echo "generate target specific header $@ for $(PRIVATE_MODULE)"
	$(Q) LANG=C $(PRIVATE_PATH)/libelf/common/native-elf-format > $@

include $(BUILD_STATIC_LIBRARY)

###############################################################################
# luawrapper-no_dep
###############################################################################

include $(CLEAR_VARS)

LOCAL_MODULE := luawrapper-no_dep
LOCAL_DESCRIPTION := Demonstration of building an autonomous lua script with no\
	dependency
LOCAL_CATEGORY_PATH := demo

LOCAL_SRC_FILES := \
	test/no_dep/lw_dependencies.c

$(LOCAL_MODULE)_BUILD_DIR := $(call local-get-build-dir)
$(LOCAL_MODULE) := $($(LOCAL_MODULE)_BUILD_DIR)/$(LOCAL_MODULE)
$(LOCAL_MODULE)_dependencies := \
	$($(LOCAL_MODULE)) \
	$(LOCAL_PATH)/test/no_dep/main.lua

define LOCAL_CMD_PRE_INSTALL
	@echo "generate full wrapper for $(PRIVATE_MODULE)"
	$(Q) TARGET_OBJCOPY=$(TARGET_OBJCOPY) \
		$(PRIVATE_PATH)/build_wrapper.sh -o $($(PRIVATE_MODULE)).tmp \
		$($(PRIVATE_MODULE)_dependencies)
	$(Q) mv $($(PRIVATE_MODULE)).tmp $($(PRIVATE_MODULE))
endef

LOCAL_LIBRARIES := luawrapper

include $(BUILD_EXECUTABLE)

###############################################################################
# luawrapper-lua_dep
###############################################################################

include $(CLEAR_VARS)

LOCAL_MODULE := luawrapper-lua_dep
LOCAL_DESCRIPTION := Demonstration of building an autonomous lua script with a \
	lua dependency
LOCAL_CATEGORY_PATH := demo

LOCAL_SRC_FILES := \
	test/lua_dep/lw_dependencies.c

$(LOCAL_MODULE)_BUILD_DIR := $(call local-get-build-dir)
$(LOCAL_MODULE) := $($(LOCAL_MODULE)_BUILD_DIR)/$(LOCAL_MODULE)
$(LOCAL_MODULE)_dependencies := \
	$($(LOCAL_MODULE)) \
	plop:$(LOCAL_PATH)/test/lua_dep/foo.lua \
	$(LOCAL_PATH)/test/lua_dep/main.lua

define LOCAL_CMD_PRE_INSTALL
	@echo "generate full wrapper for $(PRIVATE_MODULE)"
	$(Q) TARGET_OBJCOPY=$(TARGET_OBJCOPY) \
		$(PRIVATE_PATH)/build_wrapper.sh -o $($(PRIVATE_MODULE)).tmp \
		$($(PRIVATE_MODULE)_dependencies)
	$(Q) mv $($(PRIVATE_MODULE)).tmp $($(PRIVATE_MODULE))
endef

LOCAL_LIBRARIES := luawrapper

include $(BUILD_EXECUTABLE)

###############################################################################
# luawrapper-both_dep
###############################################################################

include $(CLEAR_VARS)

LOCAL_MODULE := luawrapper-both_dep
LOCAL_DESCRIPTION := Demonstration of building an autonomous lua script with a \
	lua dependency and a C dependency
LOCAL_CATEGORY_PATH := demo

LOCAL_SRC_FILES := \
	test/both_dep/bar.c \
	test/both_dep/lw_dependencies.c

$(LOCAL_MODULE)_BUILD_DIR := $(call local-get-build-dir)
$(LOCAL_MODULE) := $($(LOCAL_MODULE)_BUILD_DIR)/$(LOCAL_MODULE)
$(LOCAL_MODULE)_dependencies := \
	$($(LOCAL_MODULE)) \
	$(LOCAL_PATH)/test/both_dep/foo.lua \
	$(LOCAL_PATH)/test/both_dep/main.lua

define LOCAL_CMD_PRE_INSTALL
	@echo "generate full wrapper for $(PRIVATE_MODULE)"
	$(Q) TARGET_OBJCOPY=$(TARGET_OBJCOPY) \
		$(PRIVATE_PATH)/build_wrapper.sh -o $($(PRIVATE_MODULE)).tmp \
		$($(PRIVATE_MODULE)_dependencies)
	$(Q) mv $($(PRIVATE_MODULE)).tmp $($(PRIVATE_MODULE))
endef

LOCAL_LIBRARIES := luawrapper

include $(BUILD_EXECUTABLE)
