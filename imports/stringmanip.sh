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

SUBJECT="stringmanip.sh"

# BEGIN IMPORTS #
. ${WEB2PDF_ROOT}/shFlags/shflags
. ${WEB2PDF_ROOT}/default_vars.sh
. ${WEB2PDF_ROOT}/imports/stringmanip.h.sh
# END IMPORTS #

# BEGIN stringmanip.sh #


function remove_duplicate_lines() {
	local FILE=${1}
	cat $FILE | sed -f $_SED_RMDUPLICATES
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

function filter_links_from_latex() {
	local FILE="$(printf '%q\n' ${1})"
	local DOMAIN="$(str_escape ${2})"
	local COMMAND="cat $FILE | grep '\href{' | sed -e 's/.*\href{//g' | sed -e 's/}.*//g' | sed -e 's/${DOMAIN}//g' | grep -v '://' | sed -e 's/\//${DOMAIN}\//' " | sed -e "s/(.*)\//\1/g"
	_echo_err "$COMMAND"
	eval "$COMMAND"
}

function filter_ext_links_from_latex() {
        local FILE="$(printf '%q\n' ${1})"
        local DOMAIN="$(str_escape ${2})"
        echo $(cat $FILE | grep "\href{" | sed -e "s/.*\href{//g" | sed -e "s/}.*//g" | grep -v "${DOMAIN}" | grep "://")
}

function get_date() {
	echo $(date -u +%Y-%m-%d)
}
