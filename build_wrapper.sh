#!/bin/sh

# TODO update documentation

# Script for embedding a lua script into a launcher for the script, in order to
# allow to build a fully autonomous, statically "compiled" script. The final
# wrapped "script" is written to standard output, or to the file passed in the
# -o option. Dependencies don't need to be ordered, they are loaded when needed.
#
# The layout of the output file is the following, sizes in bytes :
#
# +----------+--------+--------+------+- ... -+------+--------+------+------+---------+
# | header   |  lua dependency modules   ...  |   main lua program   |     footer     |
# +----------+--------+--------+------+- ... -+------+--------+------+------+---------+
# | launcher | SIZE_1 | mod. 1 | lua  |  ...  | SIZE | script | lua  | stop | launch. |
# |          |        | name   | code |  ...  |      |  name  | code |      | size LS |
# +----------+--------+--------+------+- ... -+------+--------+------+------+---------+
# |    LS    |          SIZE_1        |  ...  |         SIZE         |  8   |    8    |
# +----------+------------------------+- ... -+----------------------+------+---------+
#
# All sizes are unsigned and written in 8 bytes, big endian.
# Strings end with one nul byte.
# All sizes of lua scripts do count the SIZE_X an script name.

#set -x

if [ "$1" = "-o" ]; then
	shift
	output=$1
	shift
else
	output="lw.out"
fi
rm -f $output
echo "output to file $output"

launcher=$1
first_lua_file=$2

if [ ! -f "${launcher}" ] || [ ! -f "${first_lua_file}" ]; then
	echo "usage : build_wrapper.sh [-o output_file] launcher [lua_deps] script"
	echo "\tif -o is omitted, the result is written to standard output"
	exit 1
fi

shift
cp -f ${launcher} ${output}
for script in "$@" ; do
	name="lw_$(basename $script | sed 's/\.lua*//g')"
	echo "add section ${name} for ${script}"
	objcopy --add-section ${name}=${script} ${output} ${output}
done
