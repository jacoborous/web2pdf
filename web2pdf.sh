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
# END IMPORTS #

# BEGIN web2pdf.sh #

DEFINE_string 'url' 'https://www.gnu.org/licenses/gpl-3.0-standalone.html' 'The URL you wish to convert into a document' u

# parse command line
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"


export URL="${FLAGS_url}"

export WEB2PDF_DIR="${HOME}/.web2pdf"

mkdirifnotexist "$WEB2PDF_DIR"

generate_markdown ${URL}






