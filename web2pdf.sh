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
. ${THIS_DIR}/helper_functions.sh
. ${THIS_DIR}/default_vars.sh
# END IMPORTS #

# BEGIN web2pdf.sh #

DEFINE_string 'url' '' 'The URL you wish to convert into a document' u
DEFINE_string 'markdown' 'gfm' 'Markdown type. Either markdown (pandoc style) or gfm (GitHub style).' m
DEFINE_string 'browser' 'default' 'The string(s) used to represent the browser type: tor, firefox, default, or null (empty).' b
DEFINE_boolean 'verbose' 'true' 'Turn on verbose messages.' v
DEFINE_boolean 'recurse' 'true' 'Recurse through sub-links.' r
DEFINE_boolean 'compile' 'true' 'Compile all collected TeX files into PDF documents. Recurses through your HOME/.web2pdf root directory.' c

# parse command line
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"

if [ "${FLAGS_verbose}" == "1" ] ; then
	export VERBOSE="true"
fi

if [ "${FLAGS_compile}" == "1" ] ; then
	recursive_compile
fi

export URL="${FLAGS_url}"
export MARKDOWN="${FLAGS_markdown}"

if [ -z "${URL}" ] ; then
	_echo_err "You must at least provide a URL string using the flag --url/-u."
	exit 1
fi

if [ "${FLAGS_recurse}" == "1" ] ; then
	export RECURSE="true"
else
	export RECURSE="false"
fi

mkdirifnotexist "${WEB2PDF_TMP_DIR}"
mkdirifnotexist "${WEB2PDF_DIR}"

OUTPUT_MD=$(generate_markdown ${URL} ${MARKDOWN} ${FLAGS_browser} ${FLAGS_browser})
OUTPUT_TEX=$(generate_latex_from_file ${OUTPUT_MD} ${MARKDOWN})
OUTPUT_PDF=$(compile_pdf ${OUTPUT_TEX} "xelatex")

if [ "$RECURSE" == "true" ] ; then
	search_sub_urls_from_file "$OUTPUT_TEX" "$URL"
fi




