#!/bin/bash

OUTPUT_ROOT=${1}
URLS=${2}
BROWSER=${3}

WEB2PDF_VARS=../default_vars.sh

. ${WEB2PDF_VARS}

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
	web2pdf -r -o ${OUTPUT_ROOT} -u ${line} -b ${BROWSER} > ${WEB2PDF_LOG_DIR}/web2pdf_${ID}.log 2>&1 &
	PID=$!
	echo ${PID} >> ${PID_FILE}
	echo "Launched job ${RUNID} / ${ID} with process ID $PID"
	ID=$(($ID+1))
done < ${URLS}

echo "Started!"

echo "Starting automated commit process..."

${OUTPUT_ROOT}/autocommit.sh > ${WEB2PDF_LOG_DIR}/autocommit.log 2>&1 &
echo $! >> ${PID_FILE}

echo "Start-up complete. All tracked PIDs: "$(echo $(cat ${PID_FILE}))" "
