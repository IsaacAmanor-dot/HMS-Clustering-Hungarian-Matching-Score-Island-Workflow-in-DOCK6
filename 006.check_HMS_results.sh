#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/000.config.sh"

printf "task_id\tcutoff\tcase_name\tstatus\ttotal_islands\toutput_file\n" \
    > "${STATUS_FILE}"

while IFS=$'\t' read -r TASK_ID CUTOFF LABEL CASE_NAME INPUT_FILE; do

    OUTPUT_FILE="${WORK_ROOT}/${CASE_NAME}.out"
    SUMMARY_FILE="${WORK_ROOT}/${CASE_NAME}_summary.out"

    SUCCESS_FILE="${WORK_ROOT}/.${CASE_NAME}.success"
    FAILED_FILE="${WORK_ROOT}/.${CASE_NAME}.failed"

    TOTAL_ISLANDS=""

    if [[ -s "${OUTPUT_FILE}" ]]; then
        TOTAL_ISLANDS=$(awk '
        /^Total Islands:/ {
            print $3
            exit
        }
        ' "${OUTPUT_FILE}")
    fi

    if [[ -f "${SUCCESS_FILE}" ]] \
        && [[ -s "${OUTPUT_FILE}" ]] \
        && [[ -s "${SUMMARY_FILE}" ]] \
        && grep -q "Similarity Island clustering complete" "${OUTPUT_FILE}" 2>/dev/null; then

        STATUS="SUCCESS"

    elif [[ -f "${FAILED_FILE}" ]]; then

        STATUS="FAILED"

    elif [[ -s "${OUTPUT_FILE}" || -s "${SUMMARY_FILE}" ]]; then

        STATUS="INCOMPLETE"

    else

        STATUS="MISSING"
    fi

    printf "%s\t%s\t%s\t%s\t%s\t%s\n" \
        "${TASK_ID}" \
        "${CUTOFF}" \
        "${CASE_NAME}" \
        "${STATUS}" \
        "${TOTAL_ISLANDS}" \
        "${OUTPUT_FILE}" \
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
echo "Total:      ${TOTAL}"
echo "Successful: ${SUCCESS}"
echo "Failed:     ${FAILED}"
echo "Incomplete: ${INCOMPLETE}"
echo "Missing:    ${MISSING}"
echo
echo "Status table:"
echo "${STATUS_FILE}"
echo

column -t -s $'\t' "${STATUS_FILE}"
