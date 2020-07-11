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
# END IMPORTS #

# BEGIN default_vars.sh #
export WEB2PDF_TMP_DIR="/tmp/web2pdf"
export WEB2PDF_DIR="${HOME}/.web2pdf"

export USER_AGENT_TOR="Mozilla/5.0 (Windows NT 10.0; rv:68.0) Gecko/20100101 Firefox/68.0"
export HTTP_ACCEPT_HEADERS_TOR="text/html, */*; q=0.01 gzip, deflate, br en-US,en;q=0.5"
export USER_AGENT_FIREFOX="Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:78.0) Gecko/20100101 Firefox/78.0"
export HTTP_ACCEPT_HEADERS_FIREFOX="text/html, */*; q=0.01 gzip, deflate, br en-US,en;q=0.5"

export DEFAULT_TIMEZONE="UTC"
export DEFAULT_LANG="en-US"
export DEFAULT_PLATFORM="Linux x86_64"

export USER_AGENT_DEFAULT="${USER_AGENT_TOR}"
export HTTP_ACCEPT_HEADERS_DEFAULT="${HTTP_ACCEPT_HEADERS_TOR}"
