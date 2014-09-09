CC       ?= gcc
CFLAGS   ?= -Os
CPPFLAGS ?=
CPPFLAGS += \
            -I../include/ \
            -I../src/lua/
Q        ?= @

tests := both_dep \
	lua_dep \
	no_dep

bin := $(foreach t,$(tests),$(t)/$(t))

all: $(bin)

both_dep_OBJS := both_dep/bar.o
both_dep_LUA_DEPS := both_dep/foo.lua \
	both_dep/main.lua

lua_dep_LUA_DEPS := plop:lua_dep/foo.lua \
	lua_dep/main.lua

no_dep_LUA_DEPS := no_dep/main.lua

.SECONDEXPANSION:
$(bin): $$($$(notdir $$@)_OBJS) $$(notdir $$@)/lw_dependencies.o ../luawrapper.a
	$(Q) $(CC) -o $@ -static -Os $^ -lm
	$(Q) TARGET_OBJCOPY=$(TARGET_OBJCOPY) ../build_wrapper.sh \
		-o $@ $@ $($(notdir $@)_LUA_DEPS)

clean:
	$(Q) -rm -f $(bin)
	$(Q) -(rm -f $$(find -name '*.o'))
