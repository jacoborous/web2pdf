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
. ${THIS_DIR}/default_vars.sh
# END IMPORTS #

# BEGIN helper_functions.sh #

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
	pandoc -f html -t markdown -o "$OUT_FILE" "${URL}"
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
    local PY_FILE="${WEB2PDF_TMP_DIR}/py_list.py"
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
    local PY_FILE="${WEB2PDF_TMP_DIR}/pylist_get_range.py"
    local PY_SCRIPT="text_to_split = \"${EXPR}\"\nsplit_list = text_to_split.split()\nprint(split_list[${INDEX1}:${INDEX2}])"
    touch "${PY_FILE}"
    chmod -R ugo+rwx "${PY_FILE}"
    printf "${PY_SCRIPT}" >| "${PY_FILE}"
    echo "$(echo $(python ${PY_FILE}) | sed -e 's/.*\[//g' | sed -e 's/\].*//g' | sed -e 's/,//g' | sed -e "s/'//g")"
}


function create_dirs_from_list() {
    local DIRS=${1}
    _echo_err "DIRS=${DIRS}"
    local PATH_DIR=${2}
    for i in ${DIRS} ; do
	PATH_DIR="${PATH_DIR}/$i"
	_echo_err "Making directory ${PATH_DIR}"
	mkdirifnotexist "${PATH_DIR}"
    done
}

function curl_to_file() {
	local URL=${1}
	local OUTPUT_FILE=${2}
	local USER_AGENT=${3}
	local HTTP_HEADER=${4}
	_echo_debug "curl -s -A \"${USER_AGENT}\" -H \"${HTTP_HEADER}\" --url \"${URL}\" -o ${OUTPUT_FILE}"
	curl -s -A "${USER_AGENT}" -H "${HTTP_HEADER}" --url "${URL}" -o "${OUTPUT_FILE}"
}

function url_to_dir_list() {
	local URL=${1}
	URL_LIST="$(echo ${URL} | sed -e 's/\:\/\//\//g' | tr "\/" " ")" # breaking urls into lists by / separator
	echo $URL_LIST
}

function create_dirs_from_url() {
	local URL=${1}
	local URL_LIST="$(url_to_dir_list $URL)"
	local LAST_FOLDER="$(pylist_get "${URL_LIST}" "-1")"
        create_dirs_from_list "$(pylist_get_range "${URL_LIST}" "0" "-1")" "$WEB2PDF_DIR"
	echo "${WEB2PDF_DIR}/$(echo $(pylist_get_range "${URL_LIST}" "0" "") | sed -e 's/ /\//g')"
}



function generate_markdown() {
	local URL=${1}
	local INTERMED=$(if [ "${2}" == "gfm" ] ; then echo "gfm" ; else echo "markdown" ; fi)
	local OUTPUT_FILE="$(create_dirs_from_url ${URL})"
	if [[ ! "${OUTPUT_FILE}" =~ ".*.html" ]] ; then
		OUTPUT_FILE="${OUTPUT_FILE}.html"
	fi

	_echo_err "Generating markdown file from curled URL with:"
	_echo_err "URL=${URL}"
	_echo_err "INTERMED=${INTERMED}"
	_echo_err "OUTPUT_FILE=${OUTPUT_FILE}"

	curl_to_file "${URL}" "${OUTPUT_FILE}" "${USER_AGENT_DEFAULT}" "${HTTP_ACCEPT_HEADERS_DEFAULT}"

	_echo_debug "running html to ${INTERMED}"

	pandoc -f html -t "${INTERMED}" \
	       -o "${OUTPUT_FILE}.md" \
	       "${OUTPUT_FILE}"

	_echo_err "Checking to see if file was successfully created..."

	if [ -f "${OUTPUT_FILE}.md" ] ; then
	    _echo_err "Yes! Completed."
	    echo "${OUTPUT_FILE}.md"
	else
	    _echo_err "File not found! An error must have occurred when running pandoc."
	    exit 1
	fi

}

function generate_latex_from_file() {
	local FILE=${1}
	local INTERMED=${2}
	local OUTPUT_FILE="${FILE}.tex"

	_echo_err "Generating Latex with:"
	_echo_err "FILE=${FILE}"
	_echo_err "INTERMED=$INTERMED"
	_echo_err "OUTPUT_FILE=${OUTPUT_FILE}"

	_echo_debug "running ${INTERMED} to latex..."

	pandoc -f "${INTERMED}" -t "latex" \
	       -o "${OUTPUT_FILE}" \
	       "${FILE}"

	_echo_err "Checking to see if file was successfully created..."

	if [ -f "${OUTPUT_FILE}" ] ; then
	    _echo_err "Yes! Completed."
	    echo "${OUTPUT_FILE}"
	else
	    _echo_err "File not found! An error must have occurred when running pandoc."
	    exit 1
	fi
}

function compile_pdf() {
	local TEX_FILE=${1}
	local ENGINE=$(if [ -z "${2}" ] ; then echo "xelatex" ; else echo "${2}" ; fi)
	local OUTPUT_FILE="${TEX_FILE}.pdf"

        _echo_err "Generating PDF with:"
        _echo_err "TEX_FILE=${TEX_FILE}"
        _echo_err "ENGINE=$ENGINE"
        _echo_err "OUTPUT_FILE=${OUTPUT_FILE}"
	_echo_err "pandoc -o "${OUTPUT_FILE}" --pdf-engine="${ENGINE}" "${TEX_FILE}""

        pandoc -o "${OUTPUT_FILE}" \
        	--pdf-engine="${ENGINE}" \
               "${TEX_FILE}"

        _echo_err "Checking to see if pdf was successfully created..."

        if [ -f "${OUTPUT_FILE}" ] ; then
            _echo_err "Yes! Completed."
            echo "${OUTPUT_FILE}"
        else
            _echo_err "File not found! An error must have occurred when running pandoc."
	    #Since this is called with recursive_compile, we do not exit on error. We assume we should keep going.
            #exit 1
        fi

}

function recursive_compile() {
	local ROOT_DIR=$(if [ -z "${1}" ] ; then echo "${WEB2PDF_DIR}" ; else echo "${1}" ; fi)
	for i in $(ls $ROOT_DIR) ; do
		if [ -d "$ROOT_DIR/$i" ] ; then
			#we are in a directory, go down.
			recursive_compile "$ROOT_DIR/$i"
		else
			#Then it's a file. But, we need to make sure it is a TeX file.
			if [[ -f "$ROOT_DIR/$i" && "$(echo "$i" | grep -c tex)" != "0" ]] ; then
				compile_pdf "$ROOT_DIR/$i"
			fi
		fi
	done
}

function search_sub_urls_from_file() {
	local FILE=${1}
	local PREFIX=${2}
	local SUBURLS="${WEB2PDF_TMP_DIR}/sub_urls.txt"
	if [ -f "${SUBURLS}" ] ; then
		rm -rf "${SUBURLS}"
		touch "${SUBURLS}"
	fi
	for i in $(cat $FILE | grep ".html" | sed -e "s/.html.*/.html/g" | sed -e "s/.*(\//\//g") ; do
		local COUNT=$(grep -c "${PREFIX}${i}" "$FILE")
		if [ "$COUNT" == "0" ] ; then
			_echo_err "checking-in possible sub-url: ${PREFIX}${i}"
			echo "${PREFIX}${i}" >> "${SUBURLS}"
		fi
	done
	while IFS= read -r line ; do
		echo "fetching url: $line"
		local MKDN=$(generate_markdown $line "gfm")
		generate_latex_from_file $MKDN "gfm"
	done < "${SUBURLS}"
	rm -rf "${SUBURLS}"
}
