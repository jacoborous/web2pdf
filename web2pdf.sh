#!/bin/bash

URL="${1}"
export WEB2PDF_DIR=/tmp/web2pdf
export EXTRACT_DIR="${WEB2PDF_DIR}/extract"
export OUTPUT_DIR="${HOME}/.web2pdf"
export LOG_DIR="${OUTPUT_DIR}/log"
export LOG_FILE="${LOG_DIR}/web2pdf.log"
export VERBOSE=true

function echo_log () {
	if [ ! -f "${LOG_FILE}" ] ; then
		touch "${LOG_FILE}"
	fi
	if [[ "${VERBOSE}" == "false" ]] ; then
		echo "$@" >> "${LOG_FILE}"
	else
		echo "$@" 1>&2;
	fi
}


function mkdirifnotexist () {
	local EXTRACT_DIR="${1}"
	if [ ! -d "${EXTRACT_DIR}" ] ; then
		mkdir "${EXTRACT_DIR}"
		chown -R ${USER}:${USER} "${EXTRACT_DIR}"
		chmod -R ugo+rwx "${EXTRACT_DIR}"
		echo_log "${EXTRACT_DIR} created"
	fi
}


mkdirifnotexist "${WEB2PDF_DIR}"
mkdirifnotexist "${EXTRACT_DIR}"
mkdirifnotexist "${OUTPUT_DIR}"
mkdirifnotexist "${LOG_DIR}"

function pylist_get() {
    local EXPR=${1}
    local INDEX=${2}
    if [ -z "${EXPR}" ] ; then
	echo_log "Error: expression does not exist!"
	exit;
    fi
    echo_log "Getting element $INDEX from: $EXPR"
    local PY_FILE="${WEB2PDF_DIR}/py_list.py"
    if [ -f "${PY_FILE}" ] ; then rm -rf "${PY_FILE}" ; fi
    local PY_SCRIPT="text_to_split = \"${EXPR}\"\nsplit_list = text_to_split.split()\nprint(split_list[${INDEX}])"
    touch "${PY_FILE}"
    chmod -R ugo+rwx "${PY_FILE}"
    printf "${PY_SCRIPT}" >> "${PY_FILE}"
    echo_log "$(python ${PY_FILE})"
}

function pylist_get_range() {
    local EXPR="${1}"
    local INDEX1="${2}"
    local INDEX2="${3}"
    if [ -z "${EXPR}" ] ; then
        echo_log "Error: expression does not exist!"
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
    echo_log "DIRS=${DIRS}"
    PATH_DIR=${OUTPUT_DIR}
    for i in ${DIRS} ; do
	PATH_DIR="${PATH_DIR}/$i"
	echo_log "Making directory ${PATH_DIR}"
	mkdirifnotexist "${PATH_DIR}"
    done
}


function convert() {
	local URL="$(echo ${1} | sed -e 's/http\:\/\//https\:\/\//g')"
	echo_log "URL=${URL}"
	URL_LIST="$(echo ${URL} | sed -e 's/\:\/\//\//g' | tr "\/" " ")"
	echo_log "URL_LIST=${URL_LIST}"

	LAST_FOLDER="$(pylist_get "${URL_LIST}" "-1")"

        create_dirs_from_list "$(pylist_get_range "${URL_LIST}" "0" "-1")"

	local OUTPUT_FILE="${OUTPUT_DIR}/$(echo ${URL_LIST} | sed -e 's/ /\//g')"
	local INTERMED=latex
	local ENGINE=xelatex
	local ENGINE_OPT=""
	echo_log "Called with:"
	echo_log "URL=${URL}"
	echo_log "OUTPUT_FILE=${OUTPUT_FILE}{.html,.tex,.pdf}"
	echo_log "running scurl..."

	scurl -s ${URL} -o "${OUTPUT_FILE}.html"

	echo_log "running html to latex"

	pandoc -f html -t ${INTERMED} \
	       -o "${OUTPUT_FILE}.tex" \
	       "${OUTPUT_FILE}.html"

	echo_log "running latex to pdf"

	cat "${OUTPUT_FILE}.tex" \
		| sed -e 's/\\LR/\\texttt/g' \
		| egrep -v gif  \
		| egrep -v 'posts.*ivc' \
		| pandoc -f ${INTERMED} \
	       		--pdf-engine=${ENGINE} --pdf-engine-opt="${ENGINE_OPT}" \
	       		-o "${OUTPUT_FILE}.pdf"

	echo_log "checking to see if file was successfully created..."

	if [ -f "${OUTPUT_FILE}.pdf" ] ; then
	    echo_log "Yes! Completed."
	else
	    echo_log "File not found! An error must have occurred when running pandoc."
	fi

}


function main() {
    convert "${URL}" 
}

main 
