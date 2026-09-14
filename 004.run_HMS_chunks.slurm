#!/bin/bash

set -uo pipefail

WORKFLOW_DIR="${WORKFLOW_DIR:-${SLURM_SUBMIT_DIR:-$(pwd)}}"

source "${WORKFLOW_DIR}/000.config.sh"

ARRAY_ID="${SLURM_ARRAY_TASK_ID:-}"

if [[ -z "${ARRAY_ID}" ]]; then
    echo "ERROR: Missing SLURM_ARRAY_TASK_ID."
    exit 1
fi

TOTAL_TASKS=$(awk 'END {print NR - 1}' "${TASK_LIST}")

START_TASK=$(( (ARRAY_ID - 1) * TASKS_PER_NODE + 1 ))
END_TASK=$(( ARRAY_ID * TASKS_PER_NODE ))

if [[ "${END_TASK}" -gt "${TOTAL_TASKS}" ]]; then
    END_TASK="${TOTAL_TASKS}"
fi

if [[ "${START_TASK}" -gt "${TOTAL_TASKS}" ]]; then
    echo "ERROR: No tasks assigned to array element ${ARRAY_ID}."
    exit 1
fi

echo
echo "SLURM job: ${SLURM_JOB_ID:-unknown}"
echo "Array element: ${ARRAY_ID}"
echo "Node: $(hostname)"
echo "Task range: ${START_TASK}-${END_TASK}"
echo

PIDS=()
TASK_IDS=()

for ((TASK_ID=START_TASK; TASK_ID<=END_TASK; TASK_ID++)); do

    echo "Launching HMS task ${TASK_ID}"

    bash "${WORKFLOW_DIR}/003.run_one_task.slurm" "${TASK_ID}" &

    PIDS+=("$!")
    TASK_IDS+=("${TASK_ID}")
done

FAILURES=0

for I in "${!PIDS[@]}"; do

    if wait "${PIDS[$I]}"; then
        echo "Task ${TASK_IDS[$I]} complete."
    else
        echo "Task ${TASK_IDS[$I]} failed."
        FAILURES=$((FAILURES + 1))
    fi
done

echo
echo "Tasks launched: ${#PIDS[@]}"
echo "Failures: ${FAILURES}"

if [[ "${FAILURES}" -gt 0 ]]; then
    exit 1
fi

exit 0
