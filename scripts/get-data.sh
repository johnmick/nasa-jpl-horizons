#!/bin/bash

# Preserve Files Options
PRESERVE_HORZ=0
PRESERVE_TMP_JSON=0

# Default Output Locations
LOG_DIR=logs
OUTPUT_FILE=nasa-jpl-results.json

# Support Files
BODY_LIST_FILE=support-files/major-body-list.txt
CONFIG_FILE=configs/default-example.cfg

# Support Scripts
FARM_SCRIPT=scripts/farm-nasa-jpl-horizons.exp
CONVERT_SCRIPT=scripts/data-to-json.awk
JOIN_SCRIPT=scripts/join-json.awk

function main
{
  set_options "$@"
  validate_arguments
  farm_horizons
}

function display_help
{
  echo "get-nasa-jpl-horizons-data: A script for farming NASA JPL Horizons.
  Flags:
    -o <string>  :  Output filename
    -c <string>  :  The configuration file specifying query information
    -b <string>  :  A file containing the major body list output from Horizons
    -l <string>  :  Directory to store generated log files
    -s <string>  :  The expect script which executes HORIZON automation
    -p           :  If enabled, preserves NASA Horizons data files after JSON conversions (by default they are removed)
    -j           :  If enabled, preserves separate JSON files after conversion (by default they are removed)
    -?           :  Displays this help
  "
}

function set_options
{
  while getopts "c:b:l:s:pjo:?" opt; do
    case $opt in
      o)
        OUTPUT_FILE=${OPTARG}
        ;;
      c)
        CONFIG_FILE=${OPTARG}
        ;;
      b)
        BODY_LIST_FILE=${OPTARG}
        ;;
      l)
        LOG_DIR=${OPTARG}
        ;;
      s)
        FARM_SCRIPT=${OPTARG}
        ;;
      p)
        PRESERVE_HORZ=1
        ;;
      p)
        PRESERVE_TMP_JSON=1
        ;;
      ?)
        display_help
        exit 0
        ;;
      \?)
        echo "Invalid option: ${OPTARG}" >&2
        display_help
        exit 1
        ;;
    esac
  done
}

function validate_arguments
{
  if [[ -z ${CONFIG_FILE} ]]; then
    echo "[ERROR] Required configuration file not specified - displaying help:"
    display_help
    exit 1
  fi
  if [ ! -f ${CONFIG_FILE} ]; then
    echo "[ERROR] Required config file not found"
    exit 1
  fi
  if [ ! -f ${BODY_LIST_FILE} ]; then
    echo "[ERROR] Required body list file not found"
    exit 1
  fi
  if [ ! -d ${LOG_DIR} ]; then
    echo "[ERROR] Log file directory not found"
    exit 1
  fi
}

function farm_horizons
{
  echo "[INFO] Running with ${CONFIG_FILE} configuration"
  while read p; do
    BODY_ID=`     echo $p | cut -d'"' -f2  `
    START_DATE=`  echo $p | cut -d'"' -f4  `
    END_DATE=`    echo $p | cut -d'"' -f6  `
    INTERVAL=`    echo $p | cut -d'"' -f8  `
    CENTER_ID=`   echo $p | cut -d'"' -f10 `

    BODY_INFO=(   `grep " ${BODY_ID} "   ${BODY_LIST_FILE}` )
    CENTER_INFO=( `grep " ${CENTER_ID} " ${BODY_LIST_FILE}` )

    BODY_NAME=${BODY_INFO[1]}
    CENTER_NAME=${CENTER_INFO[1]}

    printf '[FETCHING] %s (%s) '        "${BODY_NAME}"   "${BODY_ID}"
    printf 'from "%s" to "%s" '         "${START_DATE}"  "${END_DATE}"
    printf 'every "%s" '                "${INTERVAL}"
    printf 'with center body %s (%s)\n' "${CENTER_NAME}" "${CENTER_ID}"

    wget $(
      ./${FARM_SCRIPT} "${BODY_ID}" "${START_DATE}" "${END_DATE}" "${INTERVAL}" "${CENTER_ID}" |
      grep -o "ftp:.*" | tr -d "\r"
    ) --append-output=${LOG_DIR}/download-status.log -O ${BODY_ID}.horz

    echo "[CONVERTING] ${BODY_NAME} Horizons output into JSON"
    ./${CONVERT_SCRIPT} ${BODY_ID}.horz > ${BODY_ID}.tmpjson
    if [ ${PRESERVE_HORZ} -eq 0 ]; then
      rm ${BODY_ID}.horz
    fi


  done < ${CONFIG_FILE}

  echo "[JOINING] Concatenating JSON files into a single JSON data file"
  ./${JOIN_SCRIPT} *.tmpjson > ${OUTPUT_FILE}
  if [ ${PRESERVE_TMP_JSON} -eq 0 ]; then
    rm *.tmpjson
  fi
}

main "$@"
