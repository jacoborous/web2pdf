#!/bin/bash

PID_DIR=/var/run/web2pdf

echo "Stopping all running processes..."
for i in $(find ${PID_DIR} -iname '*.pid' ) ; do
	echo "Found job ID: ${i}."
	while IFS= read -r line ; do
		if [ ! -z "${line}" ] ; then
			echo "Killing job ${i}, process ${line}"
			kill -s TERM "${line}" >/dev/null 2>&1
		fi
	done < "${i}"
	rm -rf "${i}" >/dev/null 2>&1
done
echo "Stopped."
