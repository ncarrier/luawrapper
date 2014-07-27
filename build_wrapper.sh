#!/bin/sh

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

# append unsigned size in 8 bytes, big endian, to the end
append_size() {
	printf "%016x" $1 | xxd -revert -plain >> ${output}
}

end_string() {
	printf "00"  | xxd -r -p >> ${output}
}

append_string() {
	echo -n $1 >> ${output}
	end_string
}

output="/proc/self/fd/1"
if [ "$1" = "-o" ]; then
	shift
	output=$1
	echo "output to file $output"
	shift
	rm -f $output
fi

launcher=$1
first_lua_file=$2

if [ ! -f "${launcher}" ] || [ ! -f "${first_lua_file}" ]; then
	echo "usage : build_wrapper.sh [-o output_file] launcher [lua_deps] script"
	echo "\tif -o is omitted, the result is written to standard output"
	exit 1
fi

# header
cat ${launcher} >> ${output}

# output size | name | code
shift
for script in "$@" ; do
	name="$(basename $script | sed 's/\.lua*//g')"
	name_size=${#name}
	script_size=$(stat -c%s ${script})
	#    tot sz   name size     nul  script size
	size=$((8 + ${name_size} + 1 + ${script_size}))

	# SIZE_X
	append_size ${size}
	# module X name
	append_string ${name}
	# lua code
	cat ${script} >> ${output}
done

# footer : stop + launcher size (i.e. start of lua scripts)
append_size 0
launcher_size=$(stat -c%s ${launcher})
append_size ${launcher_size}

if [ -f ${output} ]; then
	chmod +x ${output}
fi