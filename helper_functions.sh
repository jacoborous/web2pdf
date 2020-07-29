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

function next() {
	local LIST=${1}
	for i in $LIST ; do
		if [ ! -z $i ] ; then
			echo "$i"
			return;
		fi
	done
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
	local URL_LIST="$(get_date) $(url_to_dir_list $URL)"
	local LAST_FOLDER="$(pylist_get "${URL_LIST}" "-1")"
        create_dirs_from_list "$(pylist_get_range "${URL_LIST}" "0" "-1")" "$WEB2PDF_DIR"
	echo "${WEB2PDF_DIR}/$(echo $(pylist_get_range "${URL_LIST}" "0" "") | sed -e 's/ /\//g')"
}



function generate_markdown() {
	local URL=${1}
	local INTERMED=$(if [ "${2}" == "gfm" ] ; then echo "gfm" ; else echo "markdown" ; fi)
	local USER_AGENT=$(select_user_agent ${3})
	local HTTP_ACCEPT_HEADERS=$(select_http_accept ${4})
	local OUTPUT_FILE="$(create_dirs_from_url ${URL})"
	if [[ ! "${OUTPUT_FILE}" =~ ".*.html" ]] ; then
		OUTPUT_FILE="${OUTPUT_FILE}.html"
	fi

	_echo_err "Generating markdown file from curled URL with:"
	_echo_err "URL=${URL}"
	_echo_err "INTERMED=${INTERMED}"
	_echo_err "OUTPUT_FILE=${OUTPUT_FILE}"

	curl_to_file "${URL}" "${OUTPUT_FILE}" "${USER_AGENT}" "${HTTP_ACCEPT_HEADERS}"

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
	    #exit 1
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
	    #exit 1
	fi
}

function compile_pdf() {
	local TEX_FILE=${1}
	local ENGINE=$(if [ -z "${2}" ] ; then echo "xelatex" ; else echo "${2}" ; fi)
	local OUTPUT_FILE="${TEX_FILE}.pdf"

        _echo_err "Generating PDF..."
        _echo_debug "TEX_FILE=${TEX_FILE}"
        _echo_debug "ENGINE=$ENGINE"
        _echo_err "OUTPUT_FILE=${OUTPUT_FILE}"
	_echo_debug "pandoc -o "${OUTPUT_FILE}" --pdf-engine="${ENGINE}" "${TEX_FILE}""

        pandoc -o "${OUTPUT_FILE}" \
        	--pdf-engine="${ENGINE}" \
               "${TEX_FILE}"

        _echo_err "Checking to see if pdf was successfully created..."

        if [ -f "${OUTPUT_FILE}" ] ; then
            _echo_err "Yes! Completed."
            echo "${OUTPUT_FILE}"
        else
            _echo_err "File not found! An error must have occurred when running pandoc."
            #exit 1
        fi

}

function generate_all() {
	local URL=${1}
	local MARKDOWN=${2}
	local BROWSER=${3}
	local ENGINE=${4}
	local DO_PDF=${5}
	local OUTPUT_MD=$(generate_markdown ${URL} ${MARKDOWN} ${BROWSER} ${BROWSER})
	local OUTPUT_TEX=$(generate_latex_from_file ${OUTPUT_MD} ${MARKDOWN})
	local OUTPUT_PDF=$(if [[ "${DO_PDF}" == "true" ]] ; then compile_pdf ${OUTPUT_TEX} ${ENGINE} ; fi)
	echo "${OUTPUT_MD} ${OUTPUT_TEX} ${OUTPUT_PDF}"
}

function recursive_compile() {
	local ROOT_DIR=$(if [ -z "${1}" ] ; then echo "${WEB2PDF_DIR}" ; else echo "${1}" ; fi)
	for i in $(ls ${ROOT_DIR}) ; do
		if [ -d "$ROOT_DIR/$i" ] ; then
			#we are in a directory, go down.
			recursive_compile "$ROOT_DIR/$i"
		else
			#Then it's a file. But, we need to make sure it is a TeX file.
			if [[ -f "$ROOT_DIR/$i" && "$(echo "$i" | grep -c tex)" != "0" ]] ; then
				if [[ "$(echo "$i" | grep -c pdf)" == "0"  ]] ; then
					compile_pdf "$ROOT_DIR/$i"
				fi
			fi
		fi
	done
}


function unique_set() {
	local LIST=${1}
	local TMP_FILE="${WEB2PDF_TMP_DIR}/unique_set"
	touch $TMP_FILE
	chmod +rw $TMP_FILE
	for i in ${LIST} ; do
                local COUNT=$(grep -c "${i}" "$TMP_FILE")
                if [ "$COUNT" == "0" ] ; then
                        _echo_debug "checking-in ${i}"
                        echo "${i}" >> "${TMP_FILE}"
                fi
        done
	local SET=""
	while IFS= read -r line ; do
		SET="$line $SET"
        done < "${TMP_FILE}"
	rm -rf $TMP_FILE
	echo "$SET"
}

function get_elem() {
	local INDEX=${1}
	local LIST=${2}
	local TMP_FILE="${WEB2PDF_TMP_DIR}/tmplist"
	touch $TMP_FILE
        chmod +rw $TMP_FILE
	for i in ${LIST} ; do
		_echo_debug "echo ${i} >> ${TMP_FILE}"
                echo "${i}" >> "${TMP_FILE}"
        done
	_echo_debug "sed -n \"${INDEX} p\" \"${TMP_FILE}\""
	local ELEM=$(sed -n "${INDEX} p" "${TMP_FILE}")
	_echo_debug "ELEM=$ELEM"
        rm -rf $TMP_FILE
	echo "$ELEM"
}

function filter_links_https() {
	local FILE=${1}
	echo $(cat $FILE | egrep "\href{https" | sed -e "s/.*\href{//g" | sed -e "s/}.*//g")
}


function filter_links_slash() {
        local FILE=${1}
        local LINKS=$(cat $FILE | egrep "\href{/" | sed -e "s/.*\href{//g" | sed -e "s/}.*//g")
	_echo_debug "LINKS=${LINKS}"
	echo "${LINKS}"
}


function get_date() {
	echo $(date -u +%Y-%m-%d)
}


function search_sub_urls_from_file() {
	local FILE=${1}
	local PREFIX=${2}
	_echo_debug "Searching through $FILE for sub-urls. Prefix: $PREFIX"
	local SUBURLS="${WEB2PDF_TMP_DIR}/sub_urls"
	while [ -f "${SUBURLS}" ] ; do
		SUBURLS="${SUBURLS}1"
	done
	_echo_debug "Creating temp file $SUBURLS"
	touch "${SUBURLS}"
	for i in $(filter_links_slash $FILE) ; do
                local COUNT=$(grep -c "${PREFIX}${i}" "$FILE")
                if [ "$COUNT" == "0" ] ; then
                        _echo_err "checking-in possible sub-url: ${PREFIX}${i}"
                        echo "${PREFIX}${i}" >> "${SUBURLS}"
                fi
        done
	for i in $(filter_links_https $FILE) ; do
		local COUNT=$(grep -c "${PREFIX}${i}" "$FILE")
                if [ "$COUNT" == "0" ] ; then
                        _echo_err "checking-in possible sub-url: ${i}"
                        echo "${i}" >> "${SUBURLS}"
                fi
	done
	while IFS= read -r line ; do
		echo "fetching url: $line"
		generate_all $line "gfm" ${3} ${4} ${5}
	done < "${SUBURLS}"
	rm -rf "${SUBURLS}"
}

