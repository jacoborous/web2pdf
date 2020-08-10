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


SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
THIS_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

SUBJECT="generate_all.sh"

# BEGIN IMPORTS #
. ${THIS_DIR}/shFlags/shflags
. ${THIS_DIR}/helper_functions.sh
# END IMPORTS #

# BEGIN CMDLINE ARGS #
DEFINE_string "arg_url" "" "arg_url string"
DEFINE_string "arg_intermed" "gfm" "arg_intermediary, gfm or markdown"
DEFINE_string "arg_browser" "default" "browser type"
DEFINE_boolean "arg_makepdf" "1" "set this flag to make PDF after generation of TeX file."
DEFINE_boolean "arg_recurse" "1" "set this flag to recursively fetch links."

# parse command line
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"

arg_url="${FLAGS_arg_url}"

arg_intermed="${FLAGS_arg_intermed}"

arg_browser="${FLAGS_arg_browser}"

if [ "${FLAGS_arg_makepdf}" == "0" ] ; then
		arg_makepdf="true"
else
		arg_makepdf="false"
fi

if [ "${FLAGS_arg_recurse}" == "0" ] ; then
		arg_recurse="true"
else
		arg_recurse="false"
fi
# END CMDLINE ARGS #

# BEGIN generate_all.sh #

function check_in_links() {
	local FILE="${1}"
	if [ ! -f $FILE ] ; then
		_echo_err "Error: $FILE does not exist."
		exit 1;
	fi
	for i in $(filter_links_from_latex $FILE) ; do
                NEW_URL="${i}"
                COUNT=$(grep -c ${NEW_URL} ${WEB2PDF_URLS}) # not checked in yet
                COUNT_DONE=$(grep -c ${NEW_URL} ${WEB2PDF_URLS_DONE}) # and not already finished
                if [ "${COUNT_DONE}" == "0" ] ; then
                        if [ "${COUNT}" == "0" ] ; then
                                _echo_err "checking-in possible sub-arg_url: ${NEW_URL}"
                                echo "${NEW_URL}" >> "${WEB2PDF_URLS}"
                        fi
                fi
        done
}


function search_sub_urls_from_file() {
        local FILE=${1}
        local PREFIX=$(get_url_domain ${2})
        local CONTINUE="false"
        _echo_err "Searching through $FILE for sub-arg_urls. Prefix: $PREFIX"
	check_in_links $FILE
        local TODO_COUNT=$(grep -c ".*" "${WEB2PDF_URLS}")
        local DONE_COUNT=$(grep -c ".*" "${WEB2PDF_URLS_DONE}")
        _echo_err "To-do: ${TODO_COUNT}; Done: ${DONE_COUNT}"
        if [ "${TODO_COUNT}" != "0" ] ; then
                while IFS= read -r line ; do
                        _echo_debug "fetching arg_url: $line"
                        process_url "$line"
                        generate_all $line "gfm" ${3} ${4} ${5} ${6}
                done < "${WEB2PDF_URLS}"
        else
                _echo_err "None left to process, program complete."
                clean_tmps
                exit 0
        fi
}

function generate_all() {
        local arg_url=${1}
        local MARKDOWN=${2}
        local arg_browser=${3}
        local ENGINE=${4}
        local DO_PDF=${5}
        local DO_arg_recurse=${6}
        local OUTPUT_MD=$(generate_markdown ${arg_url} ${MARKDOWN} ${arg_browser} ${arg_browser})
        local OUTPUT_TEX=$(generate_latex_from_file ${OUTPUT_MD} ${MARKDOWN})
        local OUTPUT_PDF=$(if [[ "${DO_PDF}" == "true" ]] ; then compile_pdf ${OUTPUT_TEX} ${ENGINE} ; fi)
        if [ "${DO_arg_recurse}" == "true" ] ; then
                search_sub_urls_from_file "${OUTPUT_TEX}" "${arg_url}" "${arg_browser}" "${ENGINE}" "${DO_PDF}" "${DO_arg_recurse}"
        fi
}

generate_all ${arg_url} ${arg_intermed} ${arg_browser} "xelatex" ${arg_makepdf} ${arg_recurse}

# END generate_all.sh #
