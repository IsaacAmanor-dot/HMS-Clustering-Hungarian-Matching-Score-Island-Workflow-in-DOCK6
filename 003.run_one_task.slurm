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
    }
' "${TASK_LIST}")

if [[ -z "${TASK_LINE}" ]]; then
    echo "ERROR: Task ${TASK_ID} was not found."
    exit 1
fi

IFS=$'\t' read -r TASK_ID CUTOFF LABEL CASE_NAME CASE_DIR INPUT_FILE \
    <<< "${TASK_LINE}"

OUTPUT_FILE="${CASE_DIR}/${CASE_NAME}.out"

SUMMARY_FILE="${CASE_DIR}/HMS_Island_summary_${LABEL}.out"

if [[ ! -d "${CASE_DIR}" ]]; then
    echo "ERROR: Missing calculation directory:"
    echo "${CASE_DIR}"
    exit 1
fi

if [[ ! -s "${INPUT_FILE}" ]]; then
    echo "ERROR: Missing input file:"
    echo "${INPUT_FILE}"
    exit 1
fi

cd "${CASE_DIR}" || exit 1

if [[ -f .success ]] \
    && [[ -s "${SUMMARY_FILE}" ]]; then

    echo "Task ${TASK_ID} already completed."
    echo "Cutoff: ${CUTOFF}"
    exit 0
fi

rm -f .success .failed

echo
echo "HMS Similarity Island task"
echo
echo "Task ID: ${TASK_ID}"
echo "Cutoff: ${CUTOFF}"
echo "Case: ${CASE_NAME}"
echo "Node: $(hostname)"
echo "Directory: ${CASE_DIR}"
echo "Input: ${INPUT_FILE}"
echo "Output: ${OUTPUT_FILE}"
echo

"${DOCK_BIN}" \
    -i "${INPUT_FILE}" \
    -o "${OUTPUT_FILE}"

EXIT_CODE=$?

if [[ "${EXIT_CODE}" -eq 0 ]] \
    && [[ -s "${SUMMARY_FILE}" ]]; then

    touch .success
    rm -f .failed

    echo
    echo "Task ${TASK_ID} completed successfully."
    echo "Cutoff: ${CUTOFF}"
    echo "Summary:"
    echo "${SUMMARY_FILE}"

    exit 0
fi

touch .failed
rm -f .success

echo
echo "Task ${TASK_ID} failed."
echo "Cutoff: ${CUTOFF}"
echo "DOCK exit code: ${EXIT_CODE}"

exit 1
