#!/bin/bash

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WORK_ROOT="${CONFIG_DIR}"

# HMS cutoffs

HMS_CUTOFFS=(
    -5
    -3
    -2
    -1
    1
    3
    5
    8
    10
    15
    20
    100
)

# Similarity Island DOCK6 installation

DOCK_ROOT="/gpfs/projects/rizzo/iamanor/DOCK6_Development/Similarity_Island/dock6_dev"

DOCK_BIN="${DOCK_ROOT}/bin/dock6"

DOCK_PARAMS="${DOCK_ROOT}/parameters"

VDW_DEFN_FILE="${DOCK_PARAMS}/vdw_AMBER_parm99.defn"

FLEX_DEFN_FILE="${DOCK_PARAMS}/flex.defn"

# Ranked/scored molecules to cluster

LIGAND_ATOM_FILE="/gpfs/projects/rizzo/iamanor/DOCK6_Development/Similarity_Island/TesTING_SMI_2/000_VS_For_DOCKING_SCORE/Dock_Scored_Molecules_for_SMI_Clustering_scored.mol2"

# Grid used for descriptor scoring

GRID_PREFIX="/gpfs/projects/AMS536/2026/group3/tutorial_isaac/Individual_Project/003_gridbox/grid"

# Output directories

RUN_DIR="${WORK_ROOT}/runs/HMS"

STATE_DIR="${WORK_ROOT}/state"

LOG_DIR="${WORK_ROOT}/logs"

TASK_LIST="${STATE_DIR}/HMS_tasks.tsv"

STATUS_FILE="${STATE_DIR}/HMS_status.tsv"

# SLURM settings

SLURM_PARTITION="rn-long-40core"

SLURM_TIME="2-00:00:00"

TASKS_PER_NODE=40

MAX_NODES=4

cutoff_label()
{
    local cutoff="$1"

    if [[ "${cutoff}" == -* ]]; then
        cutoff="${cutoff#-}"
        cutoff="${cutoff//./p}"
        echo "minus_${cutoff}"
    else
        cutoff="${cutoff//./p}"
        echo "${cutoff}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then

    echo
    echo "HMS Similarity Island configuration"
    echo
    echo "DOCK binary:"
    echo "${DOCK_BIN}"
    echo
    echo "Ligand file:"
    echo "${LIGAND_ATOM_FILE}"
    echo
    echo "Grid prefix:"
    echo "${GRID_PREFIX}"
    echo
    echo "HMS cutoffs:"

    for CUTOFF in "${HMS_CUTOFFS[@]}"; do
        echo "  ${CUTOFF}"
    done

    echo
    echo "Number of HMS calculations: ${#HMS_CUTOFFS[@]}"
    echo
    echo "Run directory:"
    echo "${RUN_DIR}"
fi
