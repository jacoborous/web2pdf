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

#set -x

if [ -z "${1}" ] ; then
	PREFIX=/usr/local
else
	PREFIX="${1}"
fi

if [ ! -f ${PWD}/web2pdf.sh ] ; then
	echo "You can only run this script from the web2pdf directory."
	exit 1;
fi

mkdir -p /home/web2pdf
useradd --system --home=/home/web2pdf web2pdf
chown -R web2pdf:web2pdf /home/web2pdf

INSTALLDIR="${PREFIX}/web2pdf"

echo "Installing to: ${INSTALLDIR}"

mkdir -p ${INSTALLDIR}
mkdir -p /etc/web2pdf
mkdir -p /var/log/web2pdf
mkdir -p /var/run/web2pdf
mkdir -p /tmp/web2pdf
mkdir -p "${PREFIX}/share/.web2pdf"
chown -R web2pdf:web2pdf ${INSTALLDIR}
chown -R web2pdf:web2pdf /var/log/web2pdf
chown -R web2pdf:web2pdf /var/run/web2pdf
chown -R web2pdf:web2pdf /tmp/web2pdf
chown -R web2pdf:web2pdf "${PREFIX}/share/.web2pdf"

for i in $(find ${PWD}) ; do
	if [[ $(echo "${i}" | grep -i -c "git") == "0" ]] ; then
	if [ -d ${i} ] ; then
		echo "mkdir -p ${INSTALLDIR}/${i}"
		mkdir -p "${INSTALLDIR}/${i}"
	fi
	echo "cp -r ${i} ${INSTALLDIR}/"
	cp -r "${i}" "${INSTALLDIR}/"
	fi
done

echo "chmod -R 755 ${INSTALLDIR}"
chmod -R 755 ${INSTALLDIR}

ln -sf ${PREFIX}/web2pdf/web2pdf.sh ${PREFIX}/bin/web2pdf
ln -sf ${PREFIX}/web2pdf/web2pdf_root.sh ${PREFIX}/bin/web2pdf_root
ln -sf ${PREFIX}/web2pdf/scripts/currdir.sh ${PREFIX}/bin/web2pdf_scripts

export PATH="${INSTALLDIR}:${PREFIX}/bin:${PATH}"

install $(web2pdf_scripts)/web2pdf.service -t /usr/lib/systemd/user/
install $(web2pdf_scripts)/web2pdf.conf -t /etc/web2pdf/

systemctl enable /usr/lib/systemd/user/web2pdf.service

echo "to get web2pdf root dir, run \`web2pdf_root' : $(which web2pdf) -> $(web2pdf_root)"
echo "to get script dir, run \`web2pdf_scripts' : $(web2pdf_scripts)"
