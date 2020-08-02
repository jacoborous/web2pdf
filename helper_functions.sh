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

function select_user_agent() {
        case ${1} in
        "tor")
                echo "${USER_AGENT_TOR}"
        ;;
        "firefox")
                echo "${USER_AGENT_FIREFOX}"
        ;;
        "default")
                echo "${USER_AGENT_DEFAULT}"
        ;;
        "chrome")
                echo "${USER_AGENT_CHROME}"
        ;;
        *)
                echo "${USER_AGENT_NULL}"
        ;;
        esac
}

function select_http_accept() {
        case ${1} in
        "tor")
                echo "${HTTP_ACCEPT_HEADERS_TOR}"
        ;;
        "firefox")
                echo "${HTTP_ACCEPT_HEADERS_FIREFOX}"
        ;;
        "chrome")
                echo "${HTTP_ACCEPT_HEADERS_CHROME}"
        ;;
        "default")
                echo "${HTTP_ACCEPT_HEADERS_DEFAULT}"
        ;;
        *)
                echo "${HTTP_ACCEPT_HEADERS_NULL}"
        ;;
        esac
}

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
	_echo_err "Error: expression does not exist!"
	exit;
    fi
    local PY_FILE="${WEB2PDF_TMP_DIR}/py_list.py"
    if [ -f "${PY_FILE}" ] ; then rm -rf "${PY_FILE}" ; fi
    local PY_SCRIPT="text_to_split = \"${EXPR}\"\nsplit_list = text_to_split.split()\nprint(split_list[${INDEX}])"
    touch "${PY_FILE}"
    chmod -R ugo+rwx "${PY_FILE}"
    printf "${PY_SCRIPT}" >> "${PY_FILE}"
}

function pylist_get_range() {
    local EXPR="${1}"
    local INDEX1="${2}"
    local INDEX2="${3}"
    if [ -z "${EXPR}" ] ; then
        _echo_err "Error: expression does not exist!"
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
    _echo_debug "DIRS=${DIRS}"
    local PATH_DIR=${2}
    for i in ${DIRS} ; do
	PATH_DIR="${PATH_DIR}/$i"
	_echo_debug "Making directory ${PATH_DIR}"
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
        create_dirs_from_list "$(pylist_get_range "${URL_LIST}" "0" "")" "$WEB2PDF_DIR"
	echo "${WEB2PDF_DIR}/$(echo $(pylist_get_range "${URL_LIST}" "0" "") | sed -e 's/ /\//g')"
}

function get_url_domain() {
	local URL=${1}
	local LIST=$(url_to_dir_list ${URL})
	local FIRST=$(get_elem 1 "${LIST}")
	local SECOND=$(get_elem 2 "${LIST}")
	local DOMAIN="${FIRST}://${SECOND}"
	_echo_debug "DOMAIN=${DOMAIN}"
	echo "${DOMAIN}"
}


function generate_markdown() {
	local URL=${1}
	local INTERMED=$(if [ "${2}" == "gfm" ] ; then echo "gfm" ; else echo "markdown" ; fi)
	local USER_AGENT=$(select_user_agent ${3})
	local HTTP_ACCEPT_HEADERS=$(select_http_accept ${4})
	local OUTPUT_FILE="$(create_dirs_from_url ${URL})"

	if [ -d "${OUTPUT_FILE}" ] ; then
		OUTPUT_FILE="${OUTPUT_FILE}.html"
	fi

	_echo_err "Pulling page from ${URL}, translating to ${INTERMED}, output: ${OUTPUT_FILE}"

	curl_to_file "${URL}" "${OUTPUT_FILE}" "${USER_AGENT}" "${HTTP_ACCEPT_HEADERS}"

	pandoc -f html -t "${INTERMED}" \
	       -o "${OUTPUT_FILE}.md" \
	       "${OUTPUT_FILE}"

	if [ -f "${OUTPUT_FILE}.md" ] ; then
	    _echo_err "${INTERMED} file successfully generated."
	    rm -rf "${OUTPUT_FILE}" #delete HTML webpage, takes up unneccessary space.
	    echo "${OUTPUT_FILE}.md"
	else
	    _echo_err "File not found! An error must have occurred when running pandoc."
	    echo "0"
	fi

}

function generate_latex_from_file() {
	local FILE=${1}
	local INTERMED=${2}
	local OUTPUT_FILE="${FILE}.tex"

	_echo_err "Translating ${FILE} to LaTeX, output: ${OUTPUT_FILE}"

	pandoc -f "${INTERMED}" -t "latex" \
	       -o "${OUTPUT_FILE}" \
	       "${FILE}"

	if [ -f "${OUTPUT_FILE}" ] ; then
	    _echo_err "LaTeX file successfully generated."
	    echo "${OUTPUT_FILE}"
	else
	    _echo_err "Error: LaTeX file failed to generate. An error must have occurred when running pandoc."
	    echo "0"
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


function clean_tmps() {
	if [ -f "$WEB2PDF_URLS" ] ; then
        	_echo_debug "Removing previous $WEB2PDF_URLS"
        	rm -rf "$WEB2PDF_URLS"
	fi
	touch "$WEB2PDF_URLS"
	if [ -f "$WEB2PDF_URLS_DONE" ] ; then
        	_echo_debug "Removing previous $WEB2PDF_URLS_DONE"
        	rm -rf "$WEB2PDF_URLS_DONE"
	fi
	touch "$WEB2PDF_URLS_DONE"
}

function process_url() {
	local URL=${1}
	local TODO="$WEB2PDF_URLS"
	local DONE="$WEB2PDF_URLS_DONE"

	mv "$TODO" "${TODO}.backup"

	cat "${TODO}.backup" | egrep -x -v "$URL" > "${TODO}"

	echo "$URL" >> "$DONE"

	rm -rf "${TODO}.backup"
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
                echo "${i}" >> "${TMP_FILE}"
        done
	local ELEM=$(sed -n "${INDEX} p" "${TMP_FILE}")
        rm -rf $TMP_FILE
	echo "$ELEM"
}

function filter_links_https() {
	local FILE=${1}
	echo $(cat $FILE | egrep "\href{http" | egrep -v "?=|@|\(|\)|\%|\#" | sed -e "s/.*\href{//g" | sed -e "s/}.*//g")
}

function filter_links_none() {
        local FILE=${1}
        echo $(cat $FILE | egrep "\href{[a-zA-Z0-9]" | egrep -v "http|?=|@|\(|\)|\%|\#" | sed -e "s/.*\href{//g" | sed -e "s/}.*//g")
}

function filter_links_slash() {
        local FILE=${1}
        local LINKS=$(cat $FILE | egrep "\href{/[a-zA-Z0-9]" | egrep -v "?=|@|\(|\)|\%|\#" | sed -e "s/.*\href{//g" | sed -e "s/}.*//g")
	echo "${LINKS}"
}


function get_date() {
	echo $(date -u +%Y-%m-%d)
}
