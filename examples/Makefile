CC       ?= gcc
CFLAGS   ?= -Os
CPPFLAGS ?=
CPPFLAGS += \
            -I../include/ \
            -I../src/lua/
Q        ?= @

include examples.mk

bin := $(foreach t,$(examples),$(t)/$(t))
checks := $(foreach t,$(examples),$(t)_CHECK)

all: $(bin)

check: all $(checks)

.SECONDEXPANSION:
$(bin): $$($$(notdir $$@)_OBJS) $$(notdir $$@)/lw_dependencies.o ../luawrapper.a
	@echo linking $@
	$(Q) ($(CC) -o $@.$$$$ -static -Os $^ -lm; \
		TARGET_OBJCOPY=$(TARGET_OBJCOPY) ../build_wrapper.sh \
			-o $@ $@.$$$$ $($(notdir $@)_LUA_DEPS); \
		rm $@.$$$$)

$(checks): $$(patsubst %_CHECK,%,$$@)/$$(patsubst %_CHECK,%,$$@)
	$(Q) ./$< | grep $($(@)_RESULT) > /dev/null
	@echo "*** $@ TEST PASSED"

clean:
	$(Q) -rm -f $(bin)
	$(Q) -(rm -f $$(find -name '*.o'))

.PHONY: all $(checks) clean check
