#!/bin/bash

BODY=499
START_DATE="1900-Jan-04 00:00"
END_DATE="1901-Jan-04 00:00"
INTERVAL="1 month"

echo ${BODY}
echo ${START_DATE}
echo ${END_DATE}
echo ${INTERVAL}

wget $(expect farm-nasa-jpl-horizon.exp ${BODY} "${START_DATE}" "${END_DATE}" "${INTERVAL}" | grep -o 'ftp:.*' | tr -d '\r') --append-output=download-status.log -O ${BODY}.data
BODY_NAME=`cat ${BODY}.data | grep "Target body name" | cut -d' ' -f4`
mv ${BODY}.data ${BODY_NAME}.data

# Get Only CSV data:   cat Mars.data | awk '/\$\$SOE/{flag=1;next}/\$\$EOE/{flag=0}flag'
