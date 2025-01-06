*S.* Tm - RANKL Treatment RNAseq Analysis
===
This repository contains RNA Sequencing analysis for Clara Si and Chris Peek. The first-pass analysis (unpublished) used pseudo-alignments to generate counts and investigate pathway regulation. Andrew Beaudoin ran the analysis in 2024-25 with two goals:
* Map reads to full reference genome (GRCm39) and verify initial GO/Pathway Analysis findings
* Investigate alternative splicing events, specifically in NF-κB pathway

Experimental Design
---
*To-do, verify with Clara*

Analysis
===
All analysis was performed on a Windows computer running Windows Subsystem for Linux 2.
The computer has an x86_64 processor, 8-core AMD Ryzen 7 CPU, and 48GB RAM.

This analysis uses [Snakemake](https://snakemake.readthedocs.io/en/stable/) to run QC and Read Mapping steps on the paired-end reads. 

To install the same version of Snakemake (v8.16.0), use:
``` bash
conda env create -f envs/snakemake.yml
```

Or install the latest version with:
``` bash
conda create -c conda-forge -c bioconda --name snakemake snakemake
```

Run [fastp](https://github.com/OpenGene/fastp) for QC and Adapter Trimming
---
``` bash
snakemake --snakefile 01_QC/Snakefile --use-conda --cores 8
```

Generate [STAR](https://github.com/alexdobin/STAR) Reference from Ensembl Files
---
First, download the latest versions of the GRCm39 assembly (.fa) and annotation (.gtf) from ENSEMBL. The attached bash script will create an appropriate subdirectory
``` bash
bash scripts/get_reference.sh
```

``` bash
STAR --runMode genomeGenerate --genomeDir {} --genomeFastaFiles {} --sjdbGTFfile --sjdbOverhang 99
```

Map Reads with Splice-Aware Aligner [STAR](https://github.com/alexdobin/STAR)
---
``` bash
snakemake --snakefile 02_Mapping/Snakefile --use-conda --cores 8
```

---
