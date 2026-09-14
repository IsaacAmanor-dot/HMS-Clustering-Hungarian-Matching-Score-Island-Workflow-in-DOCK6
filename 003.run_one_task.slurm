#!/bin/bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/000.config.sh"

TASK_ID="${1:-}"

if [[ -z "${TASK_ID}" ]]; then
    echo "Usage: bash 003.run_one_task.slurm TASK_ID"
    exit 1
fi

if [[ ! -s "${TASK_LIST}" ]]; then
    echo "ERROR: Missing task list:"
    echo "${TASK_LIST}"
    exit 1
fi

TASK_LINE=$(awk -F '\t' -v ID="${TASK_ID}" '
NR > 1 && $1 == ID {
    print
    exit
}' "${TASK_LIST}")

if [[ -z "${TASK_LINE}" ]]; then
    echo "ERROR: Task ${TASK_ID} not found."
    exit 1
fi

IFS=$'\t' read -r TASK_ID CUTOFF LABEL CASE_NAME INPUT_FILE <<< "${TASK_LINE}"

OUTPUT_FILE="${WORK_ROOT}/${CASE_NAME}.out"
SUMMARY_FILE="${WORK_ROOT}/${CASE_NAME}_summary.out"

SUCCESS_FILE="${WORK_ROOT}/.${CASE_NAME}.success"
FAILED_FILE="${WORK_ROOT}/.${CASE_NAME}.failed"

cd "${WORK_ROOT}" || exit 1

if [[ -f "${SUCCESS_FILE}" ]] \
    && [[ -s "${OUTPUT_FILE}" ]] \
    && [[ -s "${SUMMARY_FILE}" ]] \
    && grep -q "Similarity Island clustering complete" "${OUTPUT_FILE}"; then

    echo "${CASE_NAME} already completed."
    exit 0
fi

rm -f "${SUCCESS_FILE}" "${FAILED_FILE}"

echo
echo "HMS Similarity Island calculation"
echo
echo "Task ID: ${TASK_ID}"
echo "Cutoff: ${CUTOFF}"
echo "Case: ${CASE_NAME}"
echo "Node: $(hostname)"
echo "Input: ${INPUT_FILE}"
echo "Output: ${OUTPUT_FILE}"
echo

"${DOCK_BIN}" \
    -i "${INPUT_FILE}" \
    -o "${OUTPUT_FILE}"

EXIT_CODE=$?

if [[ "${EXIT_CODE}" -eq 0 ]] \
    && [[ -s "${OUTPUT_FILE}" ]] \
    && [[ -s "${SUMMARY_FILE}" ]] \
    && grep -q "Similarity Island clustering complete" "${OUTPUT_FILE}"; then

    touch "${SUCCESS_FILE}"
    rm -f "${FAILED_FILE}"

    echo
    echo "${CASE_NAME} completed successfully."

    exit 0
fi

touch "${FAILED_FILE}"
rm -f "${SUCCESS_FILE}"

echo
echo "${CASE_NAME} failed."
echo "DOCK exit code: ${EXIT_CODE}"

exit 1
