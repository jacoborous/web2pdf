#!/bin/bash

# Copyright (C) 2020  Tristan Miano <jacobeus@protonmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

if [ -z ${1} ] ; then
	PREFIX='/usr/local'
else
	PREFIX='${1}'
fi

if [ ! -f ${PWD}/web2pdf.sh ] ; then
	echo "You can only run this script from the web2pdf directory."
	exit 1;
fi

echo "Installing to: ${PREFIX}/web2pdf"

if [ ! -d ${PREFIX}/web2pdf ] ; then
	mkdir -p ${PREFIX}/web2pdf
fi

cp -r ${PWD} ${PREFIX}

ln -sf ${PREFIX}/web2pdf/web2pdf.sh ${PREFIX}/bin/web2pdf
ln -sf ${PREFIX}/web2pdf/web2pdf_root.sh ${PREFIX}/bin/web2pdf_root
ln -sf ${PREFIX}/web2pdf/scripts/currdir.sh ${PREFIX}/bin/web2pdf_scripts

echo "web2pdf: $(which web2pdf) -> $(web2pdf_root)"
echo "to get script dir, run 'web2pdf_scripts' : $(web2pdf_scripts)"
