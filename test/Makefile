CC       ?= gcc
CFLAGS   ?= -Os
CPPFLAGS ?=
CPPFLAGS += \
            -I../include/ \
            -I../src/lua/
Q        ?= @

include tests.mk

bin := $(foreach t,$(tests),$(t)/$(t))

all: $(bin)

.SECONDEXPANSION:
$(bin): $$($$(notdir $$@)_OBJS) $$(notdir $$@)/lw_dependencies.o ../luawrapper.a
	@echo linking $@
	$(Q) $(CC) -o $@ -static -Os $^ -lm
	$(Q) TARGET_OBJCOPY=$(TARGET_OBJCOPY) ../build_wrapper.sh \
		-o $@ $@ $($(notdir $@)_LUA_DEPS) > /dev/null

clean:
	$(Q) -rm -f $(bin)
	$(Q) -(rm -f $$(find -name '*.o'))
