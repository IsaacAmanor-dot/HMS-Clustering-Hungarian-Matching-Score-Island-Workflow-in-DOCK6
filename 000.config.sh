#!/bin/bash

WORK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

HMS_CUTOFFS=(
    -5
    -3
    -2
    -1
    1
    3
    20
    50
)

DOCK_ROOT="/gpfs/projects/rizzo/iamanor/DOCK6_Development/Similarity_Island/dock6_dev"
DOCK_BIN="${DOCK_ROOT}/bin/dock6"

DOCK_PARAMS="${DOCK_ROOT}/parameters"
VDW_DEFN_FILE="${DOCK_PARAMS}/vdw_AMBER_parm99.defn"
FLEX_DEFN_FILE="${DOCK_PARAMS}/flex.defn"

LIGAND_ATOM_FILE="/gpfs/projects/rizzo/iamanor/DOCK6_Development/Similarity_Island/TesTING_SMI_2/000_VS_For_DOCKING_SCORE/Dock_Scored_Molecules_for_SMI_Clustering_scored.mol2"

GRID_PREFIX="/gpfs/projects/AMS536/2026/group3/tutorial_isaac/Individual_Project/003_gridbox/grid"

TASK_LIST="${WORK_ROOT}/HMS_tasks.tsv"
STATUS_FILE="${WORK_ROOT}/HMS_status.tsv"

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
    echo "HMS Similarity Island workflow"
    echo
    echo "Working directory:"
    echo "${WORK_ROOT}"
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
    echo "Calculations: ${#HMS_CUTOFFS[@]}"
fi
