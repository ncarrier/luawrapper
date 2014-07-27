/**
 * @file luawrapper.c
 * @brief Launcher for a luascript embedded at the end of the program's binary
 *
 * @date 21 juin 2014
 * @author nicolas.carrier@parrot.com
 * @copyright Copyright (C) 2013 Parrot S.A.
 */
#include <byteswap.h>

#include <inttypes.h>
#include <error.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "lw_dependencies.h"

/**
 * @var debug
 * @brief set to true for printing debug traces
 */
static bool debug;

/**
 * @def LUA_WRAPPER_DEBUG_ENV
 * @brief name of the environment variable use by luawrapper, in order to know
 * if he must print debug traces
 */
#define LUA_WRAPPER_DEBUG_ENV "LUA_WRAPPER_DEBUG"

/**
 * @def SELF_EXE
 * @brief path to the luawrapper executable
 */
#define SELF_EXE "/proc/self/exe"

/**
 * @def STOP
 * @brief uint64_t value used to mark the end of the scripts
 */
#define STOP 0L

/**
 * @struct lua_script
 * @brief pair name / code of a lua script
 */
struct lua_script {
	/** name of the script, as used in require */
	char *name;
	/** lua code */
	char *code;
};

/**
 * If the code of a script starts with a shebang, move the start of the code at
 * the end of the first line.
 * @note if the entire script is _only_ a shebang, code will be an empty string
 * @param code in input, points to the start of the code just read, in output,
 * points after the end of the first line, if it is a shebang
 */
static void remove_shebang(char **code)
{
	size_t len;
	char *c;

	if (code == NULL || *code == NULL)
		return;

	c = *code;
	len = strlen(c);
	if (len < 2)
		return;

	/* non shebang */
	if (c[0] != '#' || c[1] != '!')
		return;

	/* skip all chars until newline or end of string */
	while (*c != '\n' && *c != '\0')
		c++;

	/* don't strip the newline char so that the line indexes don't change */
	*code = c;
}

/**
 * Modifies the name passed so that each dots are replaced by underscores
 * @param name name to modify
 */
static void replace_dots_with_underscores(char *name)
{
	char *c = name + strlen(name);

	do {
		if (*c == '_')
			*c = '.';
	} while (--c > name);
}

/**
 * Reads a lua script section of the program file.
 * @param self file of the program
 * @param script in input, must point to a valid storage for a script, in
 * output, contains the script just loaded
 * @return false if there is no script anymore, in this case, both name and code
 * are set to NULL
 */
static bool load_script(FILE *self, struct lua_script *script)
{
	int ret;
	uint64_t script_size;

	script->code = script->name = NULL;

	ret = fread(&script_size, sizeof(uint64_t), 1, self);
	if (ret != 1)
		error(EXIT_FAILURE, 0, "can't read program size");
#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
	script_size = bswap_64(script_size);
#endif
	if (script_size == STOP)
		return false;

	script->name = calloc(1, script_size + 1);
	if (script->name == NULL)
		error(EXIT_FAILURE, errno, "can't allocate room for script");

	ret = fread(script->name, script_size - sizeof(uint64_t), 1, self);
	if (ret != 1)
		error(EXIT_FAILURE, 0, "can't read lua script");
	script->code = script->name + strlen(script->name) + 1;

	remove_shebang(&script->code);
	replace_dots_with_underscores(script->name);

	return true;
}

/* dumps a stack non-recursively, printing only the type of complex elements */
__attribute__((unused))
static void stack_dump(lua_State *L)
{
	int i;
	int top = lua_gettop(L);
	int t;

	fprintf(stderr, "%d elements : ", top);
	for (i = 1; i <= top; i++) {
		fprintf(stderr, "[%d] ", i);
		t = lua_type(L, i);
		switch (t) {
			case LUA_TSTRING:
				fprintf(stderr, "str \"%s\"",
						lua_tostring(L, i));
				break;

			case LUA_TBOOLEAN:
				fprintf(stderr, lua_toboolean(L, i)
						? "bool 'true'"
						: "bool 'false'");
				break;

			case LUA_TNUMBER:
				fprintf(stderr, "num '%g'", lua_tonumber(L, i));
				break;

			default:
				fprintf(stderr, "type '%s'",
						lua_typename(L, t));
				break;
		}
		if (i != top)
			fprintf(stderr, ", ");
	}
	fprintf(stderr, "\n");
}

/**
 * Loads all the lua scripts present in the program file
 * @param scripts in output, contains an allocated array, containing all the
 * scripts loaded, ending with a {NULL, NULL} script. The array must be freed
 * with free_scripts() after usage.
 * @return total number of scripts loaded
 */
static int load_scripts(struct lua_script **scripts)
{
	FILE *self;
	int ret;
	uint64_t program_size;
	uint32_t nb_scripts = 0;

	self = fopen(SELF_EXE, "rbe");
	if (self == NULL)
		error(EXIT_FAILURE, errno, "can't open %s", SELF_EXE);

	ret = fseek(self, -sizeof(uint64_t), SEEK_END);
	if (ret == -1)
		error(EXIT_FAILURE, errno, "can't seek to program's size");

	ret = fread(&program_size, sizeof(uint64_t), 1, self);
	if (ret != 1)
		error(EXIT_FAILURE, 0, "can't read program size");
#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
	program_size = bswap_64(program_size);
#endif

	/* jump to the start of the first script */
	ret = fseek(self, program_size, SEEK_SET);
	if (ret == -1)
		error(EXIT_FAILURE, errno, "can't seek to lua script");

	*scripts = NULL;
	do {
		nb_scripts++;
		*scripts = realloc(*scripts,
				(nb_scripts + 1) * sizeof(struct lua_script));
		if (*scripts == NULL)
			error(EXIT_FAILURE, errno, "realloc");
	} while (load_script(self, (*scripts) + nb_scripts - 1));

	fclose(self);

	return nb_scripts - 1;
}

/**
 * Loads a C dependency when needed by a require
 * @param L Lua state
 * @return 1
 */
static int c_dependency_preloader(lua_State *L)
{
	const char *module_name;
	lua_CFunction func = lua_tocfunction(L, lua_upvalueindex(1));

	if (func == NULL) {
		lua_pushstring(L, "NULL function in upvalue");
		lua_error(L);
	}
	lua_pop(L, 1);

	module_name = luaL_checkstring(L, -1);
	if (module_name == NULL) {
		lua_pushstring(L, "missing module name");
		lua_error(L);
	}

	lua_pushcfunction(L, func);
	lua_pushstring(L, module_name);
	lua_call(L, 1, 1);
	if (debug)
		printf("loaded C dependency: %s\n", module_name);

	return 1;
}

/**
 * Installs a pre-loader for the C dependencies so that they are loaded on
 * demand, in the right order and only if needed.
 * @param L lua state
 */
static void install_c_preloaders(lua_State *L)
{
	const struct luaL_Reg *dep;

	lua_getglobal(L, "package");
	lua_getfield(L, -1, "preload");
	lua_remove(L, -2); /* remove package from the stack */

	for (dep = lw_dependencies; dep->func != NULL; dep++) {
		lua_pushcfunction(L, dep->func);
		lua_pushcclosure(L, c_dependency_preloader, 1);
		lua_setfield(L, -2, dep->name);
		if (debug)
			printf("installed C preloader for: %s\n", dep->name);
	}

	lua_remove(L, -2); /* remove package.preload from the stack */
}

/**
 * Loads a lua dependency when needed by a require
 * @param L Lua state
 * @return 1 if the module has been loaded, 0 if not
 */
static int lua_dependency_preloader(lua_State *L)
{
	int err;
	const char *code = luaL_checkstring(L, lua_upvalueindex(1));
	const char *module_name;

	lua_pop(L, 1);
	module_name = luaL_checkstring(L, -1);
	if (module_name == NULL) {
		lua_pushstring(L, "missing module name");
		lua_error(L);
	}

	/* load the script: creates a function on top of the stack */
	err = luaL_loadstring(L, code);
	if (err != LUA_OK)
		error(EXIT_FAILURE, 0, "can't load lua module: %s",
				lua_tostring(L, -1));
	lua_pushstring(L, module_name);
	lua_call(L, 1, 1);
	if (debug)
		printf("loaded lua dependency: %s\n", module_name);

	return 1;
}

/**
 * Installs a pre-loader for the lua dependencies so that they are loaded on
 * demand, in the right order and only if needed.
 * @param L lua state
 * @param script
 */
static void install_lua_preloaders(lua_State *L,
		const struct lua_script *scripts)
{
	const struct lua_script *script;

	lua_getglobal(L, "package");
	lua_getfield(L, -1, "preload");
	lua_remove(L, -2); /* remove package from the stack */

	for (script = scripts; script->name != NULL; script++) {
		lua_pushstring(L, script->code);
		lua_pushcclosure(L, lua_dependency_preloader, 1);
		lua_setfield(L, -3, script->name);
		if (debug)
			printf("installed lua preloader for: %s\n",
					script->name);
	}

	lua_remove(L, -2); /* remove package.preload from the stack */
}


/**
 * Executes the main script.
 * @param L lua state
 * @param script Main script
 * @param argc number of arguments to pass to the script
 * @param argv vector of the arguments to pass
 * @return the main script's return status
 */
static int run_script(lua_State *L, const struct lua_script *script, int argc,
		char *argv[])
{
	int err;
	int res;
	int i = 0;

	/* build the global arg table */
	lua_getglobal(L, "_G");

	/* push all the arguments to the _G["arg"] variable */
	lua_createtable(L, argc, 0);
	do {
		lua_pushnumber(L, i);
		lua_pushstring(L, *argv);
		lua_rawset(L, -3);
		i++;
	} while (*(++argv) != NULL);
	lua_setfield(L, -2, "arg");

	/* load the main script and pass it the content of arg */
	err = luaL_loadstring(L, script->code);
	if (err != LUA_OK)
		error(EXIT_FAILURE, 0, "can't load lua module: %s",
				lua_tostring(L, -1));
	lua_getfield(L, -2, "arg");

	if (debug)
		printf("main script start\n");
	lua_call(L, 1, 1);
	res = luaL_checkint(L, -1);

	lua_settop(L, 0);

	return res;
}

/**
 * Releases the memory allocated to the scripts array in load_scripts()
 * @param scripts array of scripts to free, NULL in output
 */
static void free_scripts(struct lua_script **scripts)
{
	struct lua_script *script;

	if (scripts == NULL || *scripts == NULL)
		return;
	script = *scripts;

	do {
		free(script->name);
	} while((++script)->name != NULL);

	free(*scripts);
	*scripts = NULL;
}

/**
 * The program's main function, for nice lua errors handling
 * @param L Lua state
 * @return 1 (one returned value in L, the main scripts return status)
 */
static int pmain(lua_State *L)
{
	int res;
	int argc = lua_tointeger(L, 1);
	char **argv = lua_touserdata(L, 2);
	struct lua_script *scripts;
	int nb_scripts;
	struct lua_script main_script;

	lua_pop(L, 2);
	/* stack is empty */

	nb_scripts = load_scripts(&scripts);
	if (debug)
		printf("%d lua scripts embedded, counting main\n", nb_scripts);

	main_script = scripts[nb_scripts -1];
	scripts[nb_scripts -1].code = scripts[nb_scripts -1].name = NULL;
	luaL_openlibs(L);
	install_c_preloaders(L);
	install_lua_preloaders(L, scripts);

	res = run_script(L, &main_script, argc, argv);

	scripts[nb_scripts -1] = main_script;
	free_scripts(&scripts);

	lua_pushinteger(L, res);

	return 1;
}

/**
 * Error handling function used when loading the script
 * @param L Lua state
 * @return 1
 */
static int traceback(lua_State *L)
{
	lua_getglobal(L, "debug");
	lua_getfield(L, -1, "traceback");
	lua_pushvalue(L, 1);
	lua_pushinteger(L, 2);
	lua_call(L, 2, 1);

	return 1;
}

int main(int argc, char *argv[])
{
	int ret;
	int res = EXIT_FAILURE;
	lua_State *L;

	debug = getenv(LUA_WRAPPER_DEBUG_ENV) != NULL;

	L = luaL_newstate();
	if (L == NULL)
		error(EXIT_FAILURE, ENOMEM, "can't load lua script");

	/* call main in protected mode with a nice traceback on error */
	lua_pushcfunction(L, traceback);
	lua_pushcfunction(L, &pmain);
	lua_pushinteger(L, argc);
	lua_pushlightuserdata(L, argv);
	ret = lua_pcall(L, 2, 1, -4);
	if (ret != LUA_OK)
		fprintf(stderr, "luawrapper: %s\n", lua_tostring(L, -1));
	else
		res = luaL_checkint(L, -1);

	lua_close(L);

	return res;
}
