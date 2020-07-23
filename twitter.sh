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


# BEGIN IMPORTS #
. ${THIS_DIR}/shFlags/shflags
. ${THIS_DIR}/helper_functions.sh
. ${THIS_DIR}/default_vars.sh
# END IMPORTS #

# BEGIN twitter.sh #

export USER=${1}
export DEPTH=${2}
export TWITTER_URL="https://mobile.twitter.com/$USER/with_replies.html"

function next_page() {
	local CURPAGE=${1}
	local NEXTPAGE=$(cat $CURPAGE | grep 'Load older Tweets' | sed -e 's/.*\href{//g' | sed -e 's/}{Load older Tweets}.*//g')
	_echo_err "NEXTPAGE=${NEXTPAGE}"
	echo "$NEXTPAGE"
}

function next_url() {
	local NEXTPAGE=${1}
	local NEXTURL="https://mobile.twitter.com${NEXTPAGE}/with_replies.html"
	_echo_err "NEXTURL=${NEXTURL}"
	echo "${NEXTURL}"
}


for i in $(seq 1 $DEPTH) ; do
	if [ "$i" == "1" ] ; then
		export OUTPUT_MD=$(generate_markdown ${TWITTER_URL} "gfm" "" "")
		export OUTPUT_TEX=$(generate_latex_from_file ${OUTPUT_MD} "gfm")
#		export OUTPUT_PDF=$(compile_pdf ${OUTPUT_TEX} "xelatex")
	else
		NEXTPAGE=$(next_page ${OUTPUT_TEX})
		NEXTURL=$(next_url $NEXTPAGE)
		export OUTPUT_MD=$(generate_markdown ${NEXTURL} "gfm" "" "")
                export OUTPUT_TEX=$(generate_latex_from_file ${OUTPUT_MD} "gfm")
 #               export OUTPUT_PDF=$(compile_pdf ${OUTPUT_TEX} "xelatex")
	fi
done


# END twitter.sh #
