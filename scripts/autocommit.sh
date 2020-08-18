#!/bin/bash

if [ -z "${1}" ] ; then
	echo "Error: Output root not specified."
	exit 1;
else
	OUTPUT_ROOT="${1}"
	if [ ! -d ${OUTPUT_ROOT} ] ; then
		echo "Error: Output root directory does not exist."
		exit 1;
	fi
fi

WEB2PDF_ROOT=$(web2pdf_root)
WEB2PDF_SCRIPTS=$(web2pdf_scripts)
INTERVAL=3600

if [ -f ${OUTPUT_ROOT}/autocommit.lock ] ; then
	echo "Already ongoing commit process here. Exiting."
	exit;
else
	REMOTE=$(git remote 2>&1 | grep -c fatal)
	if [ "$REMOTE" == "0" ] ; then
		REMOTE_REF=$(git remote get-url origin 2>&1)
	else
		REMOTE_REF="local"
	fi
	touch ${OUTPUT_ROOT}/autocommit.lock
	trap "kill -9 $(cat ${OUTPUT_ROOT}/autocommit.lock) && rm -rf ${OUTPUT_ROOT}/autocommit.lock" ERR EXIT TERM KILL QUIT
fi

echo "Starting automated GitHub commit daemon. Interval $INTERVAL."
echo "Remote ref: $REMOTE_REF"

while [ 1 -lt 2 ] ; do
	git add -A
	git commit -a -m "Automated commit at: $(date)"
	if [ "$REMOTE" != "0" ] ; then git push -u origin master ; fi
	echo "Commit to $REMOTE_REF completed at $(date)."
	sleep $INTERVAL &
	echo $! >> ${OUTPUT_ROOT}/autocommit.lock
	wait
done
