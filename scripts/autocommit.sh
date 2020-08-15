#!/bin/bash

WEB2PDF_ROOT=${1}
INTERVAL=${2}

cd ${WEB2PDF_ROOT}

if [ -f ${PWD}/autocommit.lock ] ; then
	echo "Already ongoing commit process here. Exiting."
	exit;
else
	git init
	REMOTE=$(git remote 2>&1 | grep -c fatal)
	if [ "$REMOTE" != "0" ] ; then
		REMOTE_REF=$(git remote get-url origin)
	else
		REMOTE_REF="local"
	fi
	touch ${PWD}/autocommit.lock
	trap "kill -s TERM $(cat ${PWD}/autocommit.lock) && rm -rf ${PWD}/autocommit.lock" ERR EXIT TERM KILL QUIT
fi

echo "Starting automated GitHub commit daemon. Interval $INTERVAL."
echo "Remote ref: $REMOTE_REF"

while [ 1 -lt 2 ] ; do
	git add -A
	git commit -a -m "Automated commit at: $(date)"
	if [ "$REMOTE" != "0" ] ; then git push -u origin master ; fi
	echo "Commit to $REMOTE_REF completed at $(date)."
	sleep $INTERVAL &
	echo $! >> ${PWD}/autocommit.lock
	wait
done
