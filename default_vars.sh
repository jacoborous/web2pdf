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
export WEB2PDF_DIR="/usr/share/.web2pdf"

export WEB2PDF_TMP_DIR="/tmp/web2pdf/${PARENT_PID}"
export WEB2PDF_LOG_DIR="/var/log/web2pdf/${PARENT_PID}"
export WEB2PDF_LOG_FILE="${WEB2PDF_LOG_DIR}/web2pdf.log"

export WEB2PDF_PID_DIR="/var/run/web2pdf/${PARENT_PID}"
export WEB2PDF_PID_FILE="${WEB2PDF_PID_DIR}/web2pdf.pid"

export WEB2PDF_URLS="${WEB2PDF_TMP_DIR}/${BASHPID}.urls"
export WEB2PDF_URLS_DONE="${WEB2PDF_URLS}.done"

DIRS_LIST="${WEB2PDF_TMP_ROOT} ${WEB2PDF_LOG_ROOT} ${WEB2PDF_PID_ROOT} ${WEB2PDF_DIR} ${WEB2PDF_TMP_DIR} ${WEB2PDF_LOG_DIR} ${WEB2PDF_PID_DIR}"
FILES_LIST="${WEB2PDF_PID_FILE} ${WEB2PDF_URLS} ${WEB2PDF_URLS_DONE} ${WEB2PDF_LOG_FILE}"

export USER_AGENT_NULL=""
export HTTP_ACCEPT_HEADERS_NULL=""

export USER_AGENT_TOR="Mozilla/5.0 (Windows NT 10.0; rv:71.0) Gecko/20100101 Firefox/71.0"
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

function generate_dirs() {
	for i in ${DIRS_LIST} ; do
		echo "Making directory ${i}."
		mkdir -p "${i}"
		chmod -R ugo+rwx "${i}"
	done
	for i in ${FILES_LIST} ; do
                echo "Making file ${i}."
                touch "${i}"
		chmod ugo+rwx "${i}"
        done
}

generate_dirs

# END _DEFAULT_VARS BODY #
export _DEFAULT_VARS=1
fi

# END _DEFAULT_VARS #
