LOCAL_PATH := $(call my-dir)

###############################################################################
# luawrapper-no_dep
###############################################################################

include $(CLEAR_VARS)

LOCAL_MODULE := luawrapper-no_dep
LOCAL_DESCRIPTION := Demonstration of building an autonomous lua script with no\
	dependency
LOCAL_CATEGORY_PATH := demo

LOCAL_SRC_FILES := luawrapper.c \
	test/no_dep/lw_dependencies.c \
	$(call all-c-files-under,lua)

$(LOCAL_MODULE)_BUILD_DIR := $(call local-get-build-dir)
$(LOCAL_MODULE) := $($(LOCAL_MODULE)_BUILD_DIR)/$(LOCAL_MODULE)
$(LOCAL_MODULE)_dependencies := \
	$($(LOCAL_MODULE)) \
	$(LOCAL_PATH)/test/no_dep/main.lua

LOCAL_LDFLAGS := -static -lm

# TODO replace by an embedded libelf
LOCAL_LIBRARIES := libelf

define LOCAL_CMD_PRE_INSTALL
	@echo "generate full wrapper for $(PRIVATE_MODULE)"
	$(Q) TARGET_OBJCOPY=$(TARGET_OBJCOPY) \
		$(PRIVATE_PATH)/build_wrapper.sh -o $($(PRIVATE_MODULE)).tmp \
		$($(PRIVATE_MODULE)_dependencies)
	$(Q) mv $($(PRIVATE_MODULE)).tmp $($(PRIVATE_MODULE))
endef

include $(BUILD_EXECUTABLE)

###############################################################################
# luawrapper-lua_dep
###############################################################################

include $(CLEAR_VARS)

LOCAL_MODULE := luawrapper-lua_dep
LOCAL_DESCRIPTION := Demonstration of building an autonomous lua script with a \
	lua dependency
LOCAL_CATEGORY_PATH := demo

LOCAL_SRC_FILES := luawrapper.c \
	test/lua_dep/lw_dependencies.c \
	$(call all-c-files-under,lua)

$(LOCAL_MODULE)_BUILD_DIR := $(call local-get-build-dir)
$(LOCAL_MODULE) := $($(LOCAL_MODULE)_BUILD_DIR)/$(LOCAL_MODULE)
$(LOCAL_MODULE)_dependencies := \
	$($(LOCAL_MODULE)) \
	plop:$(LOCAL_PATH)/test/lua_dep/foo.lua \
	$(LOCAL_PATH)/test/lua_dep/main.lua

LOCAL_LDFLAGS := -static -lm

# TODO replace by an embedded libelf
LOCAL_LIBRARIES := libelf

define LOCAL_CMD_PRE_INSTALL
	@echo "generate full wrapper for $(PRIVATE_MODULE)"
	$(Q) TARGET_OBJCOPY=$(TARGET_OBJCOPY) \
		$(PRIVATE_PATH)/build_wrapper.sh -o $($(PRIVATE_MODULE)).tmp \
		$($(PRIVATE_MODULE)_dependencies)
	$(Q) mv $($(PRIVATE_MODULE)).tmp $($(PRIVATE_MODULE))
endef

include $(BUILD_EXECUTABLE)

###############################################################################
# luawrapper-both_dep
###############################################################################

include $(CLEAR_VARS)

LOCAL_MODULE := luawrapper-both_dep
LOCAL_DESCRIPTION := Demonstration of building an autonomous lua script with a \
	lua dependency and a C dependency
LOCAL_CATEGORY_PATH := demo

LOCAL_SRC_FILES := luawrapper.c \
	test/both_dep/lw_dependencies.c \
	test/both_dep/bar.c \
	$(call all-c-files-under,lua)

$(LOCAL_MODULE)_BUILD_DIR := $(call local-get-build-dir)
$(LOCAL_MODULE) := $($(LOCAL_MODULE)_BUILD_DIR)/$(LOCAL_MODULE)
$(LOCAL_MODULE)_dependencies := \
	$($(LOCAL_MODULE)) \
	$(LOCAL_PATH)/test/both_dep/foo.lua \
	$(LOCAL_PATH)/test/both_dep/main.lua

LOCAL_LDFLAGS := -static -lm

# TODO replace by an embedded libelf
LOCAL_LIBRARIES := libelf

define LOCAL_CMD_PRE_INSTALL
	@echo "generate full wrapper for $(PRIVATE_MODULE)"
	$(Q) TARGET_OBJCOPY=$(TARGET_OBJCOPY) \
		$(PRIVATE_PATH)/build_wrapper.sh -o $($(PRIVATE_MODULE)).tmp \
		$($(PRIVATE_MODULE)_dependencies)
	$(Q) mv $($(PRIVATE_MODULE)).tmp $($(PRIVATE_MODULE))
endef

include $(BUILD_EXECUTABLE)
