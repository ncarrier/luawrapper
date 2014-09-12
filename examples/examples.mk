# list of the examples to build
examples := both_dep \
	lua_dep \
	no_dep

# dependencies for each example
both_dep_OBJS := both_dep/bar.o
both_dep_LUA_DEPS := both_dep/foo.lua \
	both_dep/main.lua
both_dep_CHECK_RESULT := "Hello World!"

lua_dep_LUA_DEPS := plop:lua_dep/foo.lua \
	lua_dep/main.lua
lua_dep_CHECK_RESULT := "Hello World!"

no_dep_LUA_DEPS := no_dep/main.lua
no_dep_CHECK_RESULT := "Hello luawrapper world !"
