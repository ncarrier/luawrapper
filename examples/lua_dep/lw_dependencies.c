/**
 * @file lw_dependencies.c
 * @brief This file must be updated each time a new dependency to a C lua
 * library is added. For this test, no C dependency is needed
 *
 * @date 27 july 2014
 * @author carrier.nicolas0@gmail.com
 */
#include <stdlib.h>

#include "lw_dependencies.h"

const struct luaL_Reg lw_dependencies[] = {
		{.name = NULL, .func = NULL} /* NULL guard */
};

