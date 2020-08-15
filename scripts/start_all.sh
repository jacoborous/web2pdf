#!/bin/bash

WEB2PDF_TARGETS=${1}
WEB2PDF_ROOT=$(web2pdf_root)
WEB2PDF_SCRIPTS=$(web2pdf_scripts)

#. /etc/web2pdf/web2pdf.conf

. ${WEB2PDF_ROOT}/default_vars.sh

echo "Starting..."

RUNID=$$

echo "Assigned ID ${RUNID}."

echo "WEB2PDF_TMP_DIR=${WEB2PDF_TMP_DIR}"
echo "WEB2PDF_PID_DIR=${WEB2PDF_PID_DIR}"
echo "WEB2PDF_LOG_DIR=${WEB2PDF_LOG_DIR}"
echo "WEB2PDF_PID_FILE=${WEB2PDF_PID_FILE}"

#if [ ! -f ${WEB2PDF_PID_FILE} ] ; then
#       echo "${RUNID}" > ${WEB2PDF_PID_FILE}
#else
#       echo "Error: Process with the same ID $RUNID is still running."
#       exit 1;
#fi

ID=0
while IFS= read -r line ; do
        URL=$(echo $line | sed -E 's/(.*) (.*) (.*)/\1/g')
        OUTPUT_ROOT=$(echo $line | sed -E 's/(.*) (.*) (.*)/\2/g')
        BROWSER=$(echo $line | sed -E 's/(.*) (.*) (.*)/\3/g')
        echo "Got job: URL=$URL OUTPUT_ROOT=$OUTPUT_ROOT"
        web2pdf -r -o ${OUTPUT_ROOT} -u ${URL} -b ${BROWSER} > ${WEB2PDF_LOG_DIR}/web2pdf_${ID}.log 2>&1 &
        PID=$!
        echo ${PID} >> ${WEB2PDF_PID_FILE}
        echo "Launched job ${RUNID} / ${ID} with process ID $PID"
        ${WEB2PDF_SCRIPTS}/autocommit.sh ${OUTPUT_ROOT} 3600 > ${WEB2PDF_LOG_DIR}/autocommit_${ID}.log 2>&1 &
        PID=$!
        echo ${PID} >> ${WEB2PDF_PID_FILE}
        echo "Launched autocommit task for job ${ID} with process ID $PID"
        ID=$(($ID+1))
done < ${WEB2PDF_TARGETS}

echo "Start-up complete. All tracked PIDs: "$(echo $(cat ${WEB2PDF_PID_FILE}))" "
