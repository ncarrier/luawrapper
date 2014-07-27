/**
 * @file lw_dependencies.c
 * @brief This file must be updated each time a new dependency to a C lua
 * library is added.
 *
 * @date 24 juin 2014
 * @author nicolas.carrier@parrot.com
 * @copyright Copyright (C) 2013 Parrot S.A.
 */
#include <stdlib.h>

#include "lw_dependencies.h"

extern int luaopen_luasos(lua_State* L);
extern int luaopen_LuaXML_lib(lua_State* L);
extern int luaopen_socket_core(lua_State* L);
extern int luaopen_socket_unix(lua_State* L);

const struct luaL_Reg lw_dependencies[] = {
		{.name = "luasos", luaopen_luasos},
		{.name = "LuaXML_lib", luaopen_LuaXML_lib},
		/*
		 * we must translate the underscore into a dot for dealing with
		 * lua's hierarchical module handling
		 */
		{.name = "socket.core", luaopen_socket_core},
		{.name = "socket.unix", luaopen_socket_unix},

		{.name = NULL, .func = NULL} /* NULL guard */
};

