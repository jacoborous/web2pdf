#!/bin/bash

# Copyright (C) 2020 Tristan Miano <jacobeus@protonmail.com>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# 


SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
THIS_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"


# IMPORTS #
. ${THIS_DIR}/shFlags/shflags
# END IMPORTS #

# BEGIN helper_functions.sh #

export WEB2PDF_DIR="/tmp/web2pdf"

# _echo_err
# args:
#     An error string to pipe to stderr.
function _echo_err() {
        cat <<< "$@" 1>&2;
}

# _echo_debug
function _echo_debug() {
	if [[ "$VERBOSE" == "true" ]] ; then
		cat <<< "$@" 1>&2
	fi
}


function pandoc_get_md() {
	local URL=${1}
	local OUT_FILE=${1}
	pandoc -f html -t markdown -o $OUT_FILE "${URL}"
}

function mkdirifnotexist () {
	local EXTRACT_DIR="${1}"
	if [ ! -d "${EXTRACT_DIR}" ] ; then
		mkdir "${EXTRACT_DIR}"
		chown -R ${USER}:${USER} "${EXTRACT_DIR}"
		chmod -R ugo+rwx "${EXTRACT_DIR}"
		_echo_debug "${EXTRACT_DIR} created"
	fi
}


function pylist_get() {
    local EXPR=${1}
    local INDEX=${2}
    if [ -z "${EXPR}" ] ; then
	_echo_debug "Error: expression does not exist!"
	exit;
    fi
    _echo_debug "Getting element $INDEX from: $EXPR"
    local PY_FILE="${WEB2PDF_DIR}/py_list.py"
    if [ -f "${PY_FILE}" ] ; then rm -rf "${PY_FILE}" ; fi
    local PY_SCRIPT="text_to_split = \"${EXPR}\"\nsplit_list = text_to_split.split()\nprint(split_list[${INDEX}])"
    touch "${PY_FILE}"
    chmod -R ugo+rwx "${PY_FILE}"
    printf "${PY_SCRIPT}" >> "${PY_FILE}"
    _echo_debug "$(python ${PY_FILE})"
}

function pylist_get_range() {
    local EXPR="${1}"
    local INDEX1="${2}"
    local INDEX2="${3}"
    if [ -z "${EXPR}" ] ; then
        _echo_debug "Error: expression does not exist!"
        exit;
    fi
    local PY_FILE="${WEB2PDF_DIR}/pylist_get_range.py"
    local PY_SCRIPT="text_to_split = \"${EXPR}\"\nsplit_list = text_to_split.split()\nprint(split_list[${INDEX1}:${INDEX2}])"
    touch "${PY_FILE}"
    chmod -R ugo+rwx "${PY_FILE}"
    printf "${PY_SCRIPT}" >| "${PY_FILE}"
    echo "$(echo $(python ${PY_FILE}) | sed -e 's/.*\[//g' | sed -e 's/\].*//g' | sed -e 's/,//g' | sed -e "s/'//g")"
}


function create_dirs_from_list() {
    local DIRS=${1}
    _echo_debug "DIRS=${DIRS}"
    local PATH_DIR=${2}
    for i in ${DIRS} ; do
	PATH_DIR="${PATH_DIR}/$i"
	_echo_debug "Making directory ${PATH_DIR}"
	mkdirifnotexist "${PATH_DIR}"
    done
}
