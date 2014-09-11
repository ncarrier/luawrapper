CC       ?= gcc
CFLAGS   ?= -Os
CPPFLAGS ?=
CPPFLAGS += \
            -I../include/ \
            -I../src/lua/
Q        ?= @

include examples.mk

bin := $(foreach t,$(examples),$(t)/$(t))

all: $(bin)

.SECONDEXPANSION:
$(bin): $$($$(notdir $$@)_OBJS) $$(notdir $$@)/lw_dependencies.o ../luawrapper.a
	@echo linking $@
	$(Q) ($(CC) -o $@.$$$$ -static -Os $^ -lm; \
		TARGET_OBJCOPY=$(TARGET_OBJCOPY) ../build_wrapper.sh \
			-o $@ $@.$$$$ $($(notdir $@)_LUA_DEPS); \
		rm $@.$$$$)

clean:
	$(Q) -rm -f $(bin)
	$(Q) -(rm -f $$(find -name '*.o'))
