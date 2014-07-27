/**
 * @file lw_dependencies.c
 * @brief This file must be updated each time a new dependency to a C lua
 * library is added. For this test, no C dependency is needed
 *
 * @date 27 july 2014
 * @author nicolas.carrier@parrot.com
 * @copyright Copyright (C) 2013 Parrot S.A.
 */
#include <stdlib.h>

#include "lw_dependencies.h"

const struct luaL_Reg lw_dependencies[] = {
		{.name = NULL, .func = NULL} /* NULL guard */
};

