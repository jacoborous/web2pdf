#!/bin/bash

WEB2PDF_ROOT=${1}
INTERVAL=${2}

cd ${WEB2PDF_ROOT}

echo "Starting automated GitHub commit daemon. Interval $INTERVAL."
echo "Remote ref: $(git remote get-url origin)"

while [ 1 -lt 2 ] ; do
	git add -A 2>&1
	git commit -a -m "Automated commit at: $(date)" 2>&1
	git push origin master 2>&1
	echo "Commit to $(git remote get-url origin) completed at $(date)."
	sleep $INTERVAL 2>&1
done
