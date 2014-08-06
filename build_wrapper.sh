#!/bin/bash

# Script for embedding a lua script with it's lua dependencies, into a launcher
# for the script, in order to allow to build a fully autonomous, statically
# "compiled" script. Dependencies don't need to be ordered, they are loaded on
# the fly.
#
# Objcopy is used to add sections containing the lua scripts. The sections names
# are the corresponding module name, prefixed by lw_.

#set -x
set -e

function usage {
	echo "usage : $(basename ${command}) -h"
	echo -e "\t\tDisplays this help."
		echo "        $(basename ${command}) [-o OUTPUT] LAUNCHER [LUA_DEP1 \
[LUA_DEP2 ... ]] SCRIPT"
	echo -e "\t\tCreates an autonomous executable from a lua script and it's \
dependencies."
	echo -e "\t\tOUTPUT: resulting executable's path, default is lw.out."
	echo -e "\t\tLAUNCHER: path to the precompiled luawrapper."
	echo -e "\t\tLUA_DEPX and SCRIPT are paths to the lua scripts to embed, \
SCRIPT being the main script which will be directly executed. To choose the \
module name associated to a script (the parameter to _require_) one can use the\
 syntax name:path. If no name is given, then the script's basename is used as \
the module name. The module name can't contain '/' or ':'."
	exit $1
}

if [ "$1" = "-h" ]; then
	usage 0
fi

if [ "$1" = "-o" ]; then
	shift
	output=$1
	shift
else
	output="lw.out"
fi
rm -f $output
echo "output to file $output"

command=$0
launcher=$1
first_lua_file=$2

if [ ! -f "${launcher}" ]; then
	echo "launcher '${script}' not found"
	usage 1
fi

shift
cp -f ${launcher} ${output}
for script in "$@" ; do
	# try to match the pattern name:path, if no match, use basename as the name
	pattern='^([^:/]+):(.*)$'
	if [[ ${script} =~ ${pattern} ]]; then
		name=lw_${BASH_REMATCH[1]}
		script=${BASH_REMATCH[2]}
	else
		pattern='^.*/([^/]+)\.lua$'
		[[ ${script} =~ ${pattern} ]]
		name="lw_${BASH_REMATCH[1]}"
	fi

	if [ ! -f "${script}" ]; then
		echo "script '${script}' not found"
		usage 1
	fi

	echo "add section ${name} for ${script}"
	${TARGET_OBJCOPY} --add-section ${name}=${script} ${output} ${output}
done
