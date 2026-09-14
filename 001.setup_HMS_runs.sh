#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/000.config.sh"

if [[ ! -x "${DOCK_BIN}" ]]; then
    echo "ERROR: DOCK binary not found:"
    echo "${DOCK_BIN}"
    exit 1
fi

if [[ ! -s "${LIGAND_ATOM_FILE}" ]]; then
    echo "ERROR: Ligand file not found:"
    echo "${LIGAND_ATOM_FILE}"
    exit 1
fi

if [[ ! -s "${GRID_PREFIX}.bmp" ]]; then
    echo "ERROR: Grid BMP file not found:"
    echo "${GRID_PREFIX}.bmp"
    exit 1
fi

if [[ ! -s "${GRID_PREFIX}.nrg" ]]; then
    echo "ERROR: Grid NRG file not found:"
    echo "${GRID_PREFIX}.nrg"
    exit 1
fi

if [[ ! -s "${VDW_DEFN_FILE}" ]]; then
    echo "ERROR: VDW definition file not found:"
    echo "${VDW_DEFN_FILE}"
    exit 1
fi

if [[ ! -s "${FLEX_DEFN_FILE}" ]]; then
    echo "ERROR: Flex definition file not found:"
    echo "${FLEX_DEFN_FILE}"
    exit 1
fi

GENERATED=0

for CUTOFF in "${HMS_CUTOFFS[@]}"; do

    LABEL=$(cutoff_label "${CUTOFF}")
    CASE_NAME="HMS_Island_${LABEL}"

    INPUT_FILE="${WORK_ROOT}/${CASE_NAME}.in"
    SUMMARY_FILE="${CASE_NAME}_summary.out"

    cat > "${INPUT_FILE}" << EOF_INPUT
conformer_search_type                                      analysis
ligand_atom_file                                           ${LIGAND_ATOM_FILE}
limit_max_ligands                                          no
skip_molecule                                              no
read_mol_solvation                                         no
calculate_rmsd                                             no
cluster_by_similarity_island                               yes
similarity_island_scoring_type                             hms
similarity_island_hms_cutoff                               ${CUTOFF}
similarity_island_retention_mode                           all
similarity_island_write_summary                            yes
similarity_island_summary_file                             ${SUMMARY_FILE}
score_molecules                                            yes
contact_score_primary                                      no
grid_score_primary                                         no
gist_score_primary                                         no
multigrid_score_primary                                    no
dock3.5_score_primary                                      no
continuous_score_primary                                   no
footprint_similarity_score_primary                         no
pharmacophore_score_primary                                no
hbond_score_primary                                        no
internal_energy_score_primary                              no
descriptor_score_primary                                   yes
descriptor_use_grid_score                                  yes
descriptor_use_grid_lig_efficiency                         no
descriptor_use_pharmacophore_score                         no
descriptor_use_tanimoto                                    no
descriptor_use_hungarian                                   no
descriptor_use_volume_overlap                              no
descriptor_use_gist                                        no
descriptor_use_dock3.5                                     no
descriptor_grid_score_rep_rad_scale                        1
descriptor_grid_score_vdw_scale                            1
descriptor_grid_score_es_scale                             1
descriptor_grid_score_grid_prefix                          ${GRID_PREFIX}
descriptor_weight_grid_score                               1
atom_model                                                 all
vdw_defn_file                                              ${VDW_DEFN_FILE}
flex_defn_file                                             ${FLEX_DEFN_FILE}
ligand_outfile_prefix                                      ${CASE_NAME}
EOF_INPUT

    echo "Created ${CASE_NAME}.in"

    GENERATED=$((GENERATED + 1))
done

echo
echo "Generated ${GENERATED} HMS input files."
