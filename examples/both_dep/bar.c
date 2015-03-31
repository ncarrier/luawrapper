/**
 * @file bar.c
 * @brief 
 *
 * @date 6 août 2014
 * @author carrier.nicolas0@gmail.com
 */
#include <lauxlib.h>
#include <lua.h>

static int l_baz(lua_State *L)
{
	int ret;
	const char *msg;

	msg = luaL_checkstring(L, 1);

	ret = puts(msg);
	if (ret == EOF)
		return luaL_error(L, "puts returned %d", ret);

	lua_pushinteger(L, ret);

	return 1;
}

static const struct luaL_Reg bar_reg[] = {
		{"baz", l_baz},

		{ NULL, NULL, } /* sentinel */
};

int luaopen_bar(lua_State *L)
{
	luaL_newlib(L, bar_reg);

	return 1;
}
