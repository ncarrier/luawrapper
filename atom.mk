LOCAL_PATH := $(call my-dir)

###############################################################################
# luawrapper-no_dep
###############################################################################

# TODO doesn't work as is, because make final strips (and breaks) the executable

include $(CLEAR_VARS)

LOCAL_MODULE := luawrapper-no_dep
LOCAL_DESCRIPTION := Demonstration of building an autonomous lua script with no\
	dependency
LOCAL_CATEGORY_PATH := demo

LOCAL_SRC_FILES := luawrapper.c \
	test/no_dep/lw_dependencies.c \
	$(call all-c-files-under,lua)

luawrapper_no_dep_BUILD_DIR := $(call local-get-build-dir)
luawrapper_no_dep := $(luawrapper_no_dep_BUILD_DIR)/$(LOCAL_MODULE)
luawrapper_no_dep_staging := $(TARGET_OUT_STAGING)/usr/bin/$(LOCAL_MODULE)
luawrapper_no_dep_done := $(luawrapper_no_dep_BUILD_DIR)/$(LOCAL_MODULE).done
luawrapper_no_dep_absolute_scr_files := \
	$(foreach s,$(LOCAL_SRC_FILES),$(LOCAL_PATH)/$(s))
luawrapper_no_dep_dependencies := \
	$(luawrapper_no_dep)-empty \
	$(LOCAL_PATH)/test/no_dep/main.lua

$(luawrapper_no_dep_done): $(luawrapper_no_dep_staging)
	$(Q) touch $@

$(luawrapper_no_dep_staging): $(luawrapper_no_dep)
	$(Q) cp -f $< $@

$(luawrapper_no_dep)-empty: $(luawrapper_no_dep_absolute_scr_files)
	@echo "compile empty wrapper for $(PRIVATE_MODULE)"
	$(Q) mkdir -p $(luawrapper_no_dep_BUILD_DIR)
	$(Q) $(CCACHE) $(TARGET_CC) \
		-I$(PRIVATE_PATH) -I$(PRIVATE_PATH)/lua -Os \
		$^ -o $@ \
		-static -lm -Wl,--gc-sections
	$(Q) $(TARGET_STRIP) $@

$(luawrapper_no_dep):$(luawrapper_no_dep_dependencies)
	@echo "generate full wrapper for $(PRIVATE_MODULE)"
	$(Q) $(PRIVATE_PATH)/build_wrapper.sh -o $@ $< \
		$(PRIVATE_PATH)/test/no_dep/main.lua

.PHONY: $(PACKAGE_NAME)-clean
# TODO does remove only luawrapper_no_dep_done, why ?
$(PACKAGE_NAME)-clean:
	$(Q) rm -Rf $(luawrapper_no_dep_staging)
	$(Q) rm -Rf $(luawrapper_no_dep_done)
	$(Q) rm -Rf $(luawrapper_no_dep)-empty
	$(Q) rm -Rf $(luawrapper_no_dep)

include $(BUILD_CUSTOM)
