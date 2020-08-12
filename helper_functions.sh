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

SUBJECT=helper_functions
VERSION=0.01

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
. ${THIS_DIR}/imports/stringmanip.sh
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

# _exec_pid
# args: command
#	A command to track with a pid file.
function exec_pid() {
	local PID_FILE="${WEB2PDF_PID_DIR}/web2pdf.pid"
	eval "$@" 2>&1 &
	echo $! >> ${PID_FILE}
}

#http://blog.n01se.net/blog-n01se-net-p-145.html
# redirect tty fds to /dev/null
function redirect-std() {
    [[ -t 0 ]] && exec </dev/null
    [[ -t 1 ]] && exec >/dev/null
    [[ -t 2 ]] && exec 2>/dev/null
}

# close all non-std* fds
function close-fds() {
    eval exec {3..255}\>\&-
}

# full daemonization of external command with setsid
function daemonize() {
    (                   # 1. fork
        redirect-std    # 2.1. redirect stdin/stdout/stderr before setsid
        cd /            # 3. ensure cwd isn't a mounted fs
        # umask 0       # 4. umask (leave this to caller)
        close-fds       # 5. close unneeded fds
        exec setsid "$@"
    ) &
    echo $! >> ${WEB2PDF_PID_DIR}/web2pdf.pid
}

# daemonize without setsid, keeps the child in the jobs table
function daemonize-job() {
    (                   # 1. fork
        redirect-std    # 2.2.1. redirect stdin/stdout/stderr
        trap '' 1 2     # 2.2.2. guard against HUP and INT (in child)
        cd /            # 3. ensure cwd isn't a mounted fs
        # umask 0       # 4. umask (leave this to caller)
        close-fds       # 5. close unneeded fds
        if [[ $(type -t "$1") != file ]]; then
            "$@"
        else
            exec "$@"
        fi
    ) &
    local PID=$!
    echo $PID >> ${WEB2PDF_PID_DIR}/web2pdf.pid
    disown -h $PID       # 2.2.3. guard against HUP (in parent)
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
	local LIST="${1}"
	for i in $LIST ; do
		shift 1
		if [ ! -z $1 ] ; then
			echo "$1"
			return;
		fi
	done
}

function pandoc_get_md() {
	local URL="${1}"
	local OUT_FILE="${1}"
	local MDN="${3}"
	pandoc -f html -t ${MDN} --standalone --self-contained -o "${OUT_FILE}" "${URL}"
}

function make_directory() {
	create_dirs_from_list "$(dir_to_folder_list ${1})"
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

function func_temp() {
	local FILE="${1}"
	touch $FILE
	chmod ugo+rwx $FILE
	trap "rm -rf $FILE" ERR EXIT QUIT KILL TERM
}


function pylist_get() {

    local EXPR=${1}
    local INDEX=${2}

    if [ -z "${EXPR}" ] ; then
	_echo_err "Error: expression does not exist!"
	exit 1;
    fi

    local RAND_NAME="${RANDOM}.py"
    local PY_FILE="${WEB2PDF_TMP_DIR}/${RAND_NAME}"
    _echo_debug "Creating temp py file: $PY_FILE"
    func_temp $PY_FILE
    local PY_SCRIPT="text_to_split = \"${EXPR}\"\nsplit_list = text_to_split.split()\nprint(split_list[${INDEX}])"
    printf "${PY_SCRIPT}" >> "${PY_FILE}"
    echo "$(python ${PY_FILE})"
}

function pylist_get_range() {
    	local EXPR="${1}"
    	local INDEX1="${2}"
    	local INDEX2="${3}"

    	if [ -z "${EXPR}" ] ; then
        	_echo_err "Error: missing argument"
		exit 1;
    	fi

    	local PY_FILE="${WEB2PDF_TMP_DIR}/${RANDOM}.py"
	_echo_debug "Creating temp py file: $PY_FILE"
	func_temp $PY_FILE
    	local PY_SCRIPT="text_to_split = \"${EXPR}\"\nsplit_list = text_to_split.split()\nprint(split_list[${INDEX1}:${INDEX2}])"
    	printf "${PY_SCRIPT}" >> "${PY_FILE}"
    	echo "$(echo $(python ${PY_FILE}) | sed -e 's/.*\[//g' | sed -e 's/\].*//g' | sed -e 's/,//g' | sed -e "s/'//g")"
}


function create_dirs_from_list() {
    local DIRS=${1}
    _echo_debug "DIRS=${DIRS}"
    local PATH_DIR=${2}
    for i in ${DIRS} ; do
	PATH_DIR="${PATH_DIR}/$i"
	mkdirifnotexist "${PATH_DIR}"
    done
}

function curl_to_file() {
	local URL="${1}"
	local OUTPUT_FILE="${2}"
	local USER_AGENT="${3}"
	local HTTP_HEADER="${4}"
	_echo_debug "curl -s -A \"${USER_AGENT}\" -H \"${HTTP_HEADER}\" --url \"${URL}\" -o ${OUTPUT_FILE}"
	curl -s -A "${USER_AGENT}" -H "${HTTP_HEADER}" --url "${URL}" -o "${OUTPUT_FILE}"
}

function url_to_dir_list() {
	local URL="${1}"
	URL_LIST="$(echo ${URL} | sed -e 's/\:\/\//\//g' | tr "\/" " ")" # breaking urls into lists by / separator
	echo "$URL_LIST"
}

function dir_to_folder_list() {
	local DIR="${1}"
	DIR_LIST="$(echo ${DIR} | tr "\/" " ")"
	echo "$DIR_LIST"
}

function create_dirs_from_url() {
	local URL="${1}"
	_echo_debug "Creating dirs from: $URL"
	local URL_LIST="$(url_to_dir_list $URL)"
	_echo_debug "URL_LIST: $URL_LIST"
	local LAST_FOLDER="$(pylist_get "${URL_LIST}" "-1")"
	_echo_debug "LAST_FOLDER: $LAST_FOLDER"
        create_dirs_from_list "$(pylist_get_range "${URL_LIST}" "0" "")" "$WEB2PDF_DIR"
	echo "${WEB2PDF_DIR}/$(echo $(pylist_get_range "${URL_LIST}" "0" "") | sed -e 's/ /\//g')"
}

function get_url_domain() {
	local URL="${1}"
	local LIST=$(url_to_dir_list ${URL})
	local FIRST=$(get_elem 1 "${LIST}")
	local SECOND=$(get_elem 2 "${LIST}")
	local DOMAIN="${FIRST}://${SECOND}"
	_echo_debug "DOMAIN=${DOMAIN}"
	echo "${DOMAIN}"
}


function generate_markdown() {
	local URL="${1}"
	local INTERMED=$(if [ "${2}" == "gfm" ] ; then echo "gfm" ; else echo "markdown" ; fi)
	local USER_AGENT=$(select_user_agent ${3})
	local HTTP_ACCEPT_HEADERS=$(select_http_accept ${4})
	local OUTPUT_FILE="$(create_dirs_from_url ${URL})"

	if [ -d "${OUTPUT_FILE}" ] ; then
		OUTPUT_FILE="${OUTPUT_FILE}.html"
	fi

	_echo_err "Pulling page from ${URL}, translating to ${INTERMED}, output: ${OUTPUT_FILE}"

	curl_to_file "${URL}" "${OUTPUT_FILE}" "${USER_AGENT}" "${HTTP_ACCEPT_HEADERS}"

	pandoc -f html -t "${INTERMED}" -o "${OUTPUT_FILE}.md" "${OUTPUT_FILE}"

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
	local FILE="${1}"
	local INTERMED="${2}"
	local OUTPUT_FILE="${FILE}.tex"

	_echo_err "Translating ${FILE} to LaTeX, output: ${OUTPUT_FILE}"

	pandoc -f "${INTERMED}" -t "latex" -o "${OUTPUT_FILE}" "${FILE}"

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

        pandoc -o "${OUTPUT_FILE}" --pdf-engine="${ENGINE}" "${TEX_FILE}"

        _echo_err "Checking to see if pdf was successfully created..."

        if [ -f "${OUTPUT_FILE}" ] ; then
            _echo_err "Yes! Completed."
            echo "${OUTPUT_FILE}"
        else
            _echo_err "File not found! An error must have occurred when running pandoc."
            echo "0"
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


function process_url() {
	local URL="${1}"
	local TODO="${2}"
	local DONE="${3}"

	while [ -f ${TODO}.lock ] ; do
                sleep 1 &
                wait
        done
        touch ${TODO}.lock && trap "rm -rf ${TODO}.lock" ERR EXIT TERM QUIT KILL

	mv ${TODO} ${TODO}.backup

	cat ${TODO}.backup | egrep -x -v "${URL}" | sed -f $_SED_RMDUPLICATES > ${TODO}

	append_to_file_ifnexists "${DONE}" "${URL}"

	rm -rf ${TODO}.backup
	rm -rf ${TODO}.lock
}

function append_to_file_ifnexists() {
	local FILE="${1}"
	local ELEM="${2}"
	while [ -f ${FILE}.lock ] ; do
		sleep 1 &
		wait
	done
	touch ${FILE}.lock && trap "rm -rf ${FILE}.lock" ERR EXIT TERM QUIT KILL

	EXISTS=$(($(cat ${FILE} | grep -c ${ELEM})))
	if [ $EXISTS -eq 0 ] ; then
		echo ${ELEM} >> ${FILE}
	fi
	rm -rf ${FILE}.lock
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

function random_digits() {
	local LEN=${1}
	local STR=""
	ID=$(($LEN))
	while [ $ID -gt 0 ] ; do
		STR="${RANDOM}${STR}"
		ID=$(($ID-1))
	done
	echo "$STR"
}

function get_elem() {
	local INDEX=$((${1}))
	local LIST=${2}
	local NAME="$(random_digits 4)"
	local TMP_FILE="${WEB2PDF_TMP_DIR}/${NAME}"
	func_temp $TMP_FILE
	for i in ${LIST} ; do
                echo "${i}" >> "${TMP_FILE}"
        done
	local ELEM=$(sed -n "${INDEX} p" "${TMP_FILE}")
	echo "$ELEM"
}

function str_len() {
	local STR="${1}"
	local LEN=$(echo $STR | grep -o . | egrep -c '.*')
	echo $((${LEN}))
}

function char_at() {
	local STR="${1}"
	local INDEX=$((${2}))
	local LEN=$(($(str_len $STR)))
	if [[ $INDEX -lt $LEN ]] ; then
		local ZIND=$(($INDEX+1))
		echo $STR | grep -o . | sed -n '$ZINDp'
		return;
	else
		_echo_err "Warning: Index out of bounds: string: $STR (length: $LEN), index: $INDEX. Reminder that char_at() uses 0-based indexing."
		echo ""
		return;
	fi
}

function str_get_substr() {
	local STR="${1}"
        local INDEX1=$((${2} + 1))
        local LEN=$(($(str_len $STR)))

	if [ ! -z ${3} ] ; then
		local INDEX2=$((${3} + 1))
		_echo_debug "STR: $STR LEN: $LEN INDEX1: $INDEX1 INDEX2: $INDEX2"
		_echo_debug $(echo "$STR" | grep -o . | sed -n '${INDEX1};${INDEX2}p)')
		echo "$STR" | grep -o . | sed -n '${INDEX1};${INDEX2}p'
		return
	fi

        if [[ $INDEX1 -lt $LEN ]] ; then
                echo "$STR" | grep -o . | sed -n "${INDEX1}p"
        else
                _echo_err "Warning: Index out of bounds: string: $STR (length: $LEN), index: $INDEX1. Reminder that char_at() uses 0-based indexing."
		exit 1
        fi
}

function str_begins_with() {
	local STR="${1}"
	local BEGINS_WITH="${2}"
	local LEN=$(($(str_len $STR)))
	local BEGINLEN=$(($(str_len $BEGINS_WITH)))
	if [ $BEGINLEN -gt $LEN ] ; then
		echo "false"
	else
		local BEGINSTR="$(echo $STR | grep -o . | head -$ENDLEN)"
		if [ "$BEGINSTR" == "$BEGINS_WITH" ] ; then
			echo "true"
		else
			echo "false"
		fi
	fi
}

function str_ends_with() {
        local STR="${1}"
        local ENDS_WITH="${2}"
        local LEN=$(($(str_len $STR)))
        local ENDLEN=$(($(str_len $ENDS_WITH)))
        if [ $ENDLEN -gt $LEN ] ; then
                echo "false"
        else
                local ENDSTR="$(echo $STR | grep -o . | tail -$ENDLEN)"
                if [ "$ENDSTR" == "$ENDS_WITH" ] ; then
                        echo "true"
                else
                        echo "false"
                fi
        fi
}

function str_split() {
	local STR="${1}"
	local SPLIT="${2}"
	echo $STR | sed -e "s/$SPLIT/ /g"
}

# Returns the first expression enclosed between
# an LH string and an RH string passed as args.
# If one or both can't be found then the full
# string will be returned.
function str_enclosed() {
	local LH="${1}"
	local RH="${2}"
	local STR="${3}"
	_echo_err "LH=$LH RH=$RH STR=$STR"
	_echo_err "${STR}" | sed -e "s/.*${LH}/ /g" | sed -e "s/${RH}.*/ /g"
	echo "$STR" | sed -e "s/.*${LH}/ /g" | sed -e "s/${RH}.*/ /g"
}

function _fold_1() {
	local CONTEXT=${1}
	shift 1
	while [ ! -z ${@} ] ; do
		exec sedsid "$CONTEXT ${@}"
		shift 1
	done
}

function _counter() {
	if [ $# == 0 ] ; then
		echo "_counter 0"
	elif [ $# == 1 ] ; then
		echo "_counter $(($1))"
	else
		local COUNT=$(($1+1))
		shift 1
		echo "_counter $COUNT $@"
	fi
}

function _map_1() {
	local CONTEXT=${1}
        shift 1
        while [ ! -z ${1} ] ; do
                exec sedsid "$CONTEXT ${1}"
                shift 1
        done
}

function str_has_substr() {
	local STR="${1}"
	local SUBSTR="${2}"
	local OCCURS=$(( $(echo $(str_split "$STR" "$SUBSTR") | egrep -c ".*") ))
	if [ $OCCURS -gt 0 ] ; then echo "true" ; else echo "false" ; fi
}

function str_escape() {
	local repled=$(echo "${1}" | sed -e "s/\//</g")
	local final=$(printf '%q\n' $repled | sed -e "s/</\//g")
	echo $final
}

function extract_href() {
	cat ${1} | grep -e "\\\href{" | sed -E 's/.*href\{(.*)\}\{(.*)/\1/g'
}

function remove_dup_lines() {
	cat ${1} | sed -n 'G; s/\n/&&/; /^\([ -~]*\n\).*\n\1/d; s/\n//; h; P'
}

function add_domain_ifne() {
	local DOMAIN="${1}"
	local FILE="${1}"
	echo $(cat ${FILE} | sed -E 's/^\/(.*)/${DOMAIN}\/\1/g')
}

function filter_links_from_latex() {
	local FILE="$(printf '%q\n' ${1})"
	local DOMAIN="$(str_escape ${2})"
	local CMD="cat $FILE | grep -e '\\href{' | sed -E 's/.*href\{(.*)\}\{(.*)/\1/g' | sed -n 'G; s/\n/&&/; /^\([ -~]*\n\).*\n\1/d; s/\n//; h; P' | sed -E 's/^\/(.*)/${DOMAIN}\/\1/g' | grep '${DOMAIN}'"
	_echo_debug "$CMD"
	echo $(eval "$CMD")
}

function filter_ext_links_from_latex() {
        local FILE="$(printf '%q\n' ${1})"
        local DOMAIN="$(str_escape ${2})"
        echo $(cat $FILE | grep "\href{" | sed -e "s/.*\href{//g" | sed -e "s/}.*//g" | grep -v "${DOMAIN}" | grep "://")
}

function get_date() {
	echo $(date -u +%Y-%m-%d)
}
