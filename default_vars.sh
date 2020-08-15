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

# This is our "header guard" to make sure that we cannot source this file again.
# A bit like #ifndef in C.

if [ -z $_DEFAULT_VARS ] ; then

WEB2PDF_ROOT=$(web2pdf_root)
WEB2PDF_SCRIPTS=$(web2pdf_scripts)

PARENT_PID=$$

# BEGIN IMPORTS #
. ${WEB2PDF_ROOT}/shFlags/shflags
# END IMPORTS #

# BEGIN _DEFAULT_VARS BODY #

export WEB2PDF_TMP_ROOT="/tmp/web2pdf"
export WEB2PDF_LOG_ROOT="/var/log/web2pdf"
export WEB2PDF_PID_ROOT="/var/run/web2pdf"

export WEB2PDF_TMP_DIR="/tmp/web2pdf/${PARENT_PID}"
export WEB2PDF_LOG_DIR="/var/log/web2pdf/${PARENT_PID}"
export WEB2PDF_PID_DIR="/var/run/web2pdf/${PARENT_PID}"
export WEB2PDF_PID_FILE="${WEB2PDF_PID_DIR}/web2pdf.pid"

mkdir -p $WEB2PDF_TMP_DIR
mkdir -p $WEB2PDF_LOG_DIR
mkdir -p $WEB2PDF_PID_DIR

touch $WEB2PDF_PID_FILE
echo "${PARENT_PID}" >> $WEB2PDF_PID_FILE
trap "kill -s TERM $(cat ${WEB2PDF_PID_FILE}) && rm -rf ${WEB2PDF_PID_DIR}" ERR EXIT TERM KILL QUIT

export WEB2PDF_DIR="/usr/share/.web2pdf"

export USER_AGENT_NULL=
export HTTP_ACCEPT_HEADERS_NULL=

export USER_AGENT_TOR="Mozilla/5.0 (Windows NT 10.0; rv:68.0) Gecko/20100101 Firefox/68.0"
export HTTP_ACCEPT_HEADERS_TOR="text/html, */*; q=0.01 gzip, deflate, br en-US,en;q=0.5"
export USER_AGENT_FIREFOX="Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:78.0) Gecko/20100101 Firefox/78.0"
export HTTP_ACCEPT_HEADERS_FIREFOX="text/html, */*; q=0.01 gzip, deflate, br en-US,en;q=0.5"
export USER_AGENT_CHROME="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4215.0 Safari/537.36"
export HTTP_ACCEPT_HEADERS_CHROME="text/html, */*; q=0.01 gzip, deflate, br en-US,en;q=0.9"

export DEFAULT_TIMEZONE="UTC"
export DEFAULT_LANG="en-US"
export DEFAULT_PLATFORM="Linux x86_64"

export USER_AGENT_DEFAULT="${USER_AGENT_TOR}"
export HTTP_ACCEPT_HEADERS_DEFAULT="${HTTP_ACCEPT_HEADERS_TOR}"

# END _DEFAULT_VARS BODY #
export _DEFAULT_VARS=1
fi
# END _DEFAULT_VARS #
