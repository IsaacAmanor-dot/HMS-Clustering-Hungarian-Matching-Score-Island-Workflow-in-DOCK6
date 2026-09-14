#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/000.config.sh"

if [[ ! -s "${TASK_LIST}" ]]; then
    echo "ERROR: Missing task list:"
    echo "${TASK_LIST}"
    exit 1
fi

printf "task_id\tcutoff\tcase_name\tstatus\tsummary_file\n" \
    > "${STATUS_FILE}"

while IFS=$'\t' read -r TASK_ID CUTOFF LABEL CASE_NAME CASE_DIR INPUT_FILE; do

    SUMMARY_FILE="${CASE_DIR}/HMS_Island_summary_${LABEL}.out"

    OUTPUT_FILE="${CASE_DIR}/${CASE_NAME}.out"

    if [[ -f "${CASE_DIR}/.success" ]] \
        && [[ -s "${SUMMARY_FILE}" ]]; then

        STATUS="SUCCESS"

    elif [[ -f "${CASE_DIR}/.failed" ]]; then

        STATUS="FAILED"

    elif [[ -s "${OUTPUT_FILE}" ]] \
        || [[ -s "${SUMMARY_FILE}" ]]; then

        STATUS="INCOMPLETE"

    else

        STATUS="MISSING"

    fi

    printf "%s\t%s\t%s\t%s\t%s\n" \
        "${TASK_ID}" \
        "${CUTOFF}" \
        "${CASE_NAME}" \
        "${STATUS}" \
        "${SUMMARY_FILE}" \
        >> "${STATUS_FILE}"

done < <(tail -n +2 "${TASK_LIST}")

TOTAL=$(awk 'NR > 1 {n++} END {print n+0}' "${STATUS_FILE}")

SUCCESS=$(awk -F '\t' '$4=="SUCCESS" {n++} END {print n+0}' "${STATUS_FILE}")

FAILED=$(awk -F '\t' '$4=="FAILED" {n++} END {print n+0}' "${STATUS_FILE}")

INCOMPLETE=$(awk -F '\t' '$4=="INCOMPLETE" {n++} END {print n+0}' "${STATUS_FILE}")

MISSING=$(awk -F '\t' '$4=="MISSING" {n++} END {print n+0}' "${STATUS_FILE}")

echo
echo "HMS Similarity Island status"
echo
echo "Total calculations:    ${TOTAL}"
echo "Successful:            ${SUCCESS}"
echo "Failed:                ${FAILED}"
echo "Incomplete/running:    ${INCOMPLETE}"
echo "Missing/not started:   ${MISSING}"
echo
echo "Status table:"
echo "${STATUS_FILE}"
