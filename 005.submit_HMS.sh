#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/000.config.sh"

MAX_CONCURRENT_NODES="${1:-${MAX_NODES}}"

if [[ ! -s "${TASK_LIST}" ]]; then
    echo "ERROR: Missing task list."
    echo "Run bash 002.make_task_list.sh first."
    exit 1
fi

N_TASKS=$(awk 'END {print NR - 1}' "${TASK_LIST}")

if [[ "${N_TASKS}" -lt 1 ]]; then
    echo "ERROR: No HMS tasks found."
    exit 1
fi

N_CHUNKS=$(( (N_TASKS + TASKS_PER_NODE - 1) / TASKS_PER_NODE ))

ARRAY_SPEC="1-${N_CHUNKS}%${MAX_CONCURRENT_NODES}"

echo
echo "HMS calculations: ${N_TASKS}"
echo "Tasks per node: ${TASKS_PER_NODE}"
echo "Node chunks: ${N_CHUNKS}"
echo "Maximum concurrent nodes: ${MAX_CONCURRENT_NODES}"
echo "SLURM array: ${ARRAY_SPEC}"
echo

sbatch \
    --partition="${SLURM_PARTITION}" \
    --time="${SLURM_TIME}" \
    --nodes=1 \
    --ntasks=1 \
    --cpus-per-task="${TASKS_PER_NODE}" \
    --job-name="HMS_Island" \
    --array="${ARRAY_SPEC}" \
    --output="${WORK_ROOT}/HMS_slurm_%A_%a.out" \
    --export="ALL,WORKFLOW_DIR=${WORK_ROOT}" \
    "${WORK_ROOT}/004.run_HMS_chunks.slurm"
