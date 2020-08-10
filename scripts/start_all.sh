#!/bin/bash

. /etc/web2pdf/web2pdf.conf
. ${WEB2PDF_SCRIPTS}/default_vars.sh

echo "Starting..."

RUNID=$$

echo "Assigned ID ${RUNID}."

echo "WEB2PDF_TMP_DIR=${WEB2PDF_TMP_DIR}"
echo "WEB2PDF_PID_DIR=${WEB2PDF_PID_DIR}"
echo "WEB2PDF_LOG_DIR=${WEB2PDF_LOG_DIR}"

mkdir -p ${WEB2PDF_TMP_DIR}
mkdir -p ${WEB2PDF_PID_DIR}
mkdir -p ${WEB2PDF_LOG_DIR}
PID_FILE="${WEB2PDF_PID_DIR}/web2pdf.pid"
echo "PID_FILE=$PID_FILE"
if [ ! -f ${PID_FILE} ] ; then
	echo "${RUNID}" > ${PID_FILE}
else
	echo "Error: Process with the same ID $RUNID is still running."
	exit 1;
fi


ID=0
while IFS= read -r line ; do
	OUTPUT_ROOT=$(echo $line | sed -e "s/.* //g")
	URL=$(echo $line | sed -e "s/ .*//g")
	${WEB2PDF_SCRIPTS}/web2pdf.sh -r -o ${OUTPUT_ROOT} -u ${URL} -b ${BROWSER} > ${WEB2PDF_LOG_DIR}/web2pdf_${ID}.log 2>&1 &
	PID=$!
	echo ${PID} >> ${PID_FILE}
	echo "Launched job ${RUNID} / ${ID} with process ID $PID"
	${WEB2PDF_AUTOCOMMIT} ${OUTPUT_ROOT} 3600 > ${WEB2PDF_LOG_DIR}/autocommit_${ID}.log 2>&1 &
	PID=$!
	echo ${PID} >> ${PID_FILE}
	echo "Launched autocommit task for job ${ID} with process ID $PID"
	ID=$(($ID+1))
done < ${WEB2PDF_TARGETS}

echo "Start-up complete. All tracked PIDs: "$(echo $(cat ${PID_FILE}))" "
