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

SUBJECT=web2pdf
VERSION=0.1

WEB2PDF_ROOT=$(web2pdf_root)
WEB2PDF_SCRIPTS=$(web2pdf_scripts)

PARENT_PID=$$

# IMPORTS #
. ${WEB2PDF_ROOT}/shFlags/shflags
. ${WEB2PDF_ROOT}/helper_functions.sh
. ${WEB2PDF_ROOT}/default_vars.sh
# END IMPORTS #

echo ${PARENT_PID} >> ${WEB2PDF_PID_FILE}

KILL_COMMAND="while IFS= read -r line ; do kill -s TERM ${line} >/dev/null 2>&1 ; done < ${WEB2PDF_PID_FILE}"

trap "${KILL_COMMAND}" ERR EXIT TERM KILL QUIT

# BEGIN web2pdf.sh #

DEFINE_string 'url' '' 'The URL you wish to convert into a document' u
DEFINE_string 'markdown' 'gfm' 'Markdown type. Either markdown (pandoc style) or gfm (GitHub style).' m
DEFINE_string 'browser' 'default' 'The string(s) used to represent the browser type: tor, firefox, chrome, default, or null (empty).' b
DEFINE_boolean 'verbose' '1' 'Turn on verbose messages.' v
DEFINE_string 'outroot' "${WEB2PDF_DIR}" "The root directory that documents will be placed under." o
DEFINE_boolean "sepdate" "1" "Whether to create an extra folder using the current date at the top of the output root." s
DEFINE_boolean 'recurse' "1" 'Recurse through sub-links.' r
DEFINE_boolean 'outpdf' "1" 'Use this flag to specify that a PDF document should be generated after the markdown and latex files. Expensive!' p
DEFINE_boolean 'compile' "1" "Compile all collected TeX files into PDF documents. Recurses through your \"\-\-compiledir\" directory." c
DEFINE_string 'compiledir' "${WEB2PDF_DIR}" 'Root directory to recurse through for compilation.' d

# parse command line
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"

RUNID=$(date +%s)

if [ "${FLAGS_verbose}" == "0" ] ; then
	export VERBOSE="true"
fi

if [ ! -z "${FLAGS_outroot}" ] ; then
	_echo_err "Setting output root to ${FLAGS_outroot}"
	export WEB2PDF_DIR="${FLAGS_outroot}"
fi

if [ "${FLAGS_sepdate}" == "0" ] ; then
	_echo_err "Placing dirs under ${WEB2PDF_DIR}/$(get_date)"
        export WEB2PDF_DIR="${WEB2PDF_DIR}/$(get_date)"
fi

if [ "${FLAGS_compile}" == "0" ] ; then
	recursive_compile "${FLAGS_compiledir}"
fi

export URL="${FLAGS_url}"
export MARKDOWN="${FLAGS_markdown}"

if [ -z "${URL}" ] ; then
	_echo_err "You must at least provide a URL string using the flag --url/-u."
	exit 1
fi

if [ "${FLAGS_recurse}" == "0" ] ; then
	RECURSE=--arg_recurse
else
	RECURSE=--noarg_recurse
fi
_echo_debug "RECURSE=$RECURSE"

if [ "${FLAGS_outpdf}" == "0" ] ; then
        OUTPDF=--arg_makepdf
else
        OUTPDF=--noarg_makepdf
fi
_echo_debug "OUTPDF=$OUTPDF"

make_directory "${WEB2PDF_DIR}"

${WEB2PDF_ROOT}/generate_all.sh --arg_url="${URL}" --arg_intermed="${MARKDOWN}" --arg_browser="${FLAGS_browser}" ${OUTPDF} ${RECURSE}
