*S.* Tm - RANKL Treatment RNAseq Analysis
===
This repository contains RNA Sequencing analysis for Clara Si and Chris Peek. The first-pass analysis (unpublished) used pseudo-alignments to generate counts and investigate pathway regulation. Andrew Beaudoin ran the analysis in 2024-25 with two goals:
* Map reads to full reference genome (GRCm39) and verify initial GO/Pathway Analysis findings
* Investigate alternative splicing events, specifically in NF-κB pathway

Experimental Design
---
*To-do, verify with Clara*

Sequencing Information
---
* Illumina NovaSeq 6000


Analysis
===
All analysis was performed on a Windows computer running Windows Subsystem for Linux 2.
The computer has an x86_64 processor, 8-core AMD Ryzen 7 CPU, and 48GB RAM.

This analysis uses [Snakemake](https://snakemake.readthedocs.io/en/stable/) to run QC and Read Mapping steps on the paired-end reads. 

To install the same version of Snakemake (v8.16.0), use:
``` bash
conda env create --file envs/snakemake.yml
```

Or install the latest version with:
``` bash
conda create -c conda-forge -c bioconda --name snakemake snakemake
```
I also recommend installing the same Conda environments as I have used for FastP and STAR. These are loaded in the `envs/` folder and can be installed with:
``` bash
conda env create --file envs/fastp.yml
conda env create --file envs/star.yml
```
If you already have your own versions of FastP and STAR installed, the following can still work if the environments are named appropriately! The Snakefiles in this pipeline call Conda environments named `fastp` and `star` - either change the names in the individual Snakefiles under the `conda` directive, or just make new environments with the provided `.yml` files.

Run [fastp](https://github.com/OpenGene/fastp) for QC and Adapter Trimming
---
Activate Conda environment for Snakemake. The `fastp` environment will be called by Snakemake.
``` bash
conda activate snakemake
```
Run Snakemake for QC steps using FastP.
``` bash
snakemake --snakefile 01_QC/Snakefile --use-conda --cores 8
```
### Parameters Used in FastP
* `--detect_adapter_for_pe`
    * Different adapters were used for each sample, these are detected automatically by the software.
* `--correction`
    * Since the experiment uses paired-end reads, the program will correct very low quality mismatching bases with very high quality bases from the overlapping region of the paired read.
* `--trim_poly_x`
    * Because the sequencing was done on an Illumina NovaSeq machine, FastP will automatically remove poly-G motifs ([enriched in Nova and NextSeq platforms](https://support.illumina.com/content/dam/illumina-support/help/Illumina_DRAGEN_Bio_IT_Platform_v3_7_1000000141465/Content/SW/Informatics/Dragen/PolyG_Trimming_fDG.htm)), but I want to remove spurious polyA repeats as well, as these can interfere with read mapping.
* `--compression [6]`
    * Compresses the output slightly higher than normal, to save space on my machine. This can be changed in `config/config.yml`.
* `--html 01_QC/qc_data/{group}.html`
    * Names HTML QC output based on the input file.
* `--json /dev/null`
    * Gets rid of the `.json` file.
* `--report_title {group}`
    * Renames HTML title based on the input file. 


Generate [STAR](https://github.com/alexdobin/STAR) Reference from Ensembl Files
---
First, download the latest versions of the GRCm39 assembly (.fa) and annotation (.gtf) from ENSEMBL. The attached bash script will create a new subdirectory `GRCm39/` that future scripts will reference.
``` bash
bash scripts/get_reference.sh
```
Using the downloaded files, use STAR to generate genome indices for the read mapping step.
``` bash
STAR --runMode genomeGenerate --genomeDir 02_Mapping/index --genomeFastaFiles GRCm39/Mus_musculus.GRCm39.dna_rm.primary_assembly.fa --sjdbGTFfile GRCm39/Mus_musculus.GRCm39.113.gtf --sjdbOverhang 149 --runThreadN 8
```
For the index generation, I set `sjdbOverhang` to 149 as the reads are 150bp each. The recommended overhang length is (read length)-1. 

Map Reads with Splice-Aware Aligner [STAR](https://github.com/alexdobin/STAR)
---
``` bash
snakemake --snakefile 02_Mapping/Snakefile --use-conda --cores 8
```

---
