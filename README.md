# Luawrapper

## Overview

Luawrapper is a way to build a fully autonomous statically precompiled binary
from a lua script. To do so, it must contain both the C and lua libraries the
lua script depends on.

## Description

Luawrapper implements a small lua interpreter. The needed lua scripts,
dependencies and the main lua script, are embedded in the final executable, as
elf sections. The C dependencies are compiled into the main executable so that
their corresponding module initialization functions are accessible
(luaopen\_XXX).

Both lua and C dependencies are preloaded with the package.preload lua facility.
So, when the main lua executable is interpreted, the needed dependencies, be
they C, or lua, are loaded on demand, i.e. when they are "require"-d.

## Usage

### With the provided build system

The **examples** directory contains some use cases which can be used as
examples. These can be modified or a new example can be created easily by
tweaking examples.mk and adding the corresponding directory and files in the
examples folder.

The process to do this by hand is explained in the following sections.

### Building the executable

C libraries must be compiled into the main executable. They must also be
declared in a lw\_dependencies array. Each entry must list the module name, as
when referenced by a call to require and the luaopen\_ function, responsible of
loading the module.

To build the executable, just :

1. build the luawrapper static library:  
   `$ make`  
   this produces luawrapper.a at the root
2. build all your C dependencies as object files or static libraries, e.g.:  
   `$ gcc foo.c -c -o foo.o # plus relevant flags`  
   `$ gcc bar.c -c -o bar.o # plus relevant flags ...`
3. build your C dependencies declaration module (a C file declaring a  
   `struct luaL_Reg lw_dependencies` NULL-terminated array) :  
   `$ gcc lw_dependencies.c -o lw_dependencies.o -I src/lua/ -I include`  
4. link all:  
   `$ gcc -o my_program -static luawrapper.a foo.o bar.o lw_dependencies.o -lm`  

### Wrapping the lua scripts

Once the wrapper has been compiled, the lua script and it's lua dependencies
must be wrapped into it. For this purpose, one must use the build\_wrapper.sh
script provided. It will store the lua dependencies in elf sections in the
wrapper, in a way suitable for it to retrieve them. It's usage is:

`./build_wrapper.sh -o outfile my_program dep1.lua dep2.lua [...] main.lua`

Then one can use *outfile* like he would use main.lua, but it doesn't rely on
external dependencies anymore. The resulting executable can then be used on any
similar platform. Cross-compilation is also possible by specifying the compiler
to the Makefile and the objcopy utility to the build\_wrapper.sh script via the
TARGET\_OBJCOPY environment variable.

*Note*: lw\_dependency is needed because we can't load luaopen\_XXX functions
with dlopen, when the executable is built statically.
