# HMS Similarity Island Benchmark Workflow

This workflow automates testing of the Hungarian Matching Similarity (HMS) implementation of the DOCK6 Similarity Island clustering protocol across multiple HMS cutoff values.

Each cutoff value is treated as an independent DOCK6 calculation.

## Configuration

All shared parameters are defined in:

```text
000.config.sh
```

The configuration contains:

- HMS cutoff values
- Similarity Island DOCK6 executable
- input multi-MOL2 file
- grid prefix
- DOCK6 parameter files
- SLURM settings
- workflow directories

The cutoff values can be changed by editing:

```bash
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
```

The current configuration can be displayed with:

```bash
bash 000.config.sh
```

## 001.setup_HMS_runs.sh

Creates one calculation directory and one DOCK6 input file for every HMS cutoff.

Run:

```bash
bash 001.setup_HMS_runs.sh
```

For example, cutoff `-5` produces:

```text
runs/HMS/HMS_Island_minus_5/
```

with an input file named:

```text
HMS_Island_minus_5.in
```

The DOCK6 output, Similarity Island summary, and generated MOL2 files use the same cutoff-specific naming scheme.

## 002.make_task_list.sh

Creates the task table used to map each HMS cutoff calculation to a unique task ID.

Run:

```bash
bash 002.make_task_list.sh
```

## 003.run_one_task.slurm

Runs one HMS cutoff calculation.

This script is called automatically by the workflow and normally does not need to be run manually.

## 004.run_HMS_chunks.slurm

Runs multiple independent HMS cutoff calculations concurrently on a compute node.

This script is submitted automatically by `005.submit_HMS.sh`.

## 005.submit_HMS.sh

Submits all HMS cutoff calculations to SLURM.

Run:

```bash
bash 005.submit_HMS.sh
```

The default maximum number of simultaneously occupied nodes is defined by `MAX_NODES` in `000.config.sh`.

A temporary node limit can also be supplied:

```bash
bash 005.submit_HMS.sh 2
```

## 006.check_HMS_results.sh

Checks the status of all HMS cutoff calculations.

Run:

```bash
bash 006.check_HMS_results.sh
```

The script reports calculations as:

```text
SUCCESS
FAILED
INCOMPLETE
MISSING
```

## Running the Workflow

After editing `000.config.sh`, prepare and submit the HMS benchmark with:

```bash
bash 000.config.sh
bash 001.setup_HMS_runs.sh
bash 002.make_task_list.sh
bash 005.submit_HMS.sh
```

Check the calculations with:

```bash
bash 006.check_HMS_results.sh
```

## HMS Similarity Island Calculation

HMS Similarity Island clustering is enabled with:

```text
cluster_by_similarity_island yes
similarity_island_scoring_type hms
```

The cutoff tested by each calculation is defined through:

```text
similarity_island_hms_cutoff CUTOFF
```

Each cutoff produces its own calculation directory, DOCK6 input, DOCK6 output, Similarity Island summary, and MOL2 output.
# HMS-Clustering-Hungarian-Matching-Score-Island-Workflow-in-DOCK6
