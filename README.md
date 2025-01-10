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
* `--runThreadN 4`
    * I set this to run quickly using 4 threads. With 8 available on my CPU, Snakemake will run two jobs at a time. **Double-check your machine's capabilities before running!**


Generate [STAR](https://github.com/alexdobin/STAR) Reference from Ensembl Files
---
First, download the latest versions of the GRCm39 assembly (.fa) and annotation (.gtf) from ENSEMBL. The attached bash script will create a new subdirectory `GRCm39/` that future scripts will reference.
``` bash
bash scripts/get_reference.sh
```
Deactivate the active `snakemake` environment, and activate the Conda environment for STAR.
``` bash
conda deactivate
conda activate star
```
Using the downloaded files from ENSEMBL, use STAR to generate genome indices for the read mapping step.
``` bash
STAR --runMode genomeGenerate --genomeDir 02_Mapping/index --genomeFastaFiles GRCm39/Mus_musculus.GRCm39.dna_rm.primary_assembly.fa --sjdbGTFfile GRCm39/Mus_musculus.GRCm39.113.gtf --sjdbOverhang 149 --runThreadN 8
```
### Parameters Used in STAR Index Generation
* `--sjdbOverhang 149`
    * The recommended overhang length to allow for best splice site determination is $n-1$ where $n$ is the length of reads. Therefore, I used 149 for this value.
* `--runThreadN 8`
    * I set this to run (relatively) quickly using 8 threads. **Double-check your machine's capabilities before running!**

Map Reads with Splice-Aware Aligner [STAR](https://github.com/alexdobin/STAR)
---
Re-activate Conda environment for Snakemake. The `star` environment will be called again in Snakemake.
``` bash
conda deactivate
conda activate snakemake
```
Run Snakemake for Read Mapping. 

**Note:** This is computationally intensive, and runs for ~12 hours on a machine with 8 CPU cores and 48GB of RAM. You may consider running this on a high-performance computing cluster. In that case, you may want to refer the [Snakemake documentation](https://snakemake.readthedocs.io/en/v7.19.1/executing/cluster.html) for connecting to your HPC of interest.
``` bash
snakemake --snakefile 02_Mapping/Snakefile --use-conda --cores 8
```
### Parameters Used in STAR Read Mapping
* `--readFilesCommand zcat`
    * Because the input files are [gzipped](https://www.gzip.org/), STAR needs a way to read in the files. [Zcat](https://linux.die.net/man/1/zcat) is efficient for this job.
* `--twoPassMode Basic`
    * Because I am interested in alternative splicing in downstream pathways, two passes of read mapping will be used to potentially detect novel splice junctions. 
* `--alignSJDBoverhangMin 4`
    * I am increasing the minimum overlap for *annotated* splice junctions to be called from the default of 3 up to 4. This is slightly more stringent and reduces potential false-positive annotated splice alignments.
* `--alignSJoverhangMin 8`
    * Similarly, I am increasing the minimum overlap for *un-annotated* splice junctions from the default of 5 up to 7, with the same goal of reducing false-positive novel splice alignments.
* `--outSAMtype BAM SortedByCoordinate`
    * Outputting to a BAM file saves disk space (a hot commodity on my machine) and sorting the BAM file is handy for downstream analyses (though not necessarily required by featureCounts). 
* `--runThreadN 8`
    * I set this to run using all 8 threads of my machine, maximizing available RAM per run. Your machine may not have 8 threads, or maybe you want to use a different number anyways. This can be set in `02_Mapping/Snakefile`. **Double-check your machine's capabilities before running!**

---
