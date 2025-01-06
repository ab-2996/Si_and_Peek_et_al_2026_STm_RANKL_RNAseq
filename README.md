*Salmonella* Typhimurium - RANKL Treatment RNAseq Analysis
===
This repository contains RNA Sequencing analysis from Clara Si and Chris Peek. Andrew Beaudoin re-ran the analysis in 2024-25 


Experimental Design
---


Analysis
===
All analysis was performed on a Windows computer running Windows Subsystem for Linux 2.
The computer has an x86_64 processor, 8 core CPU, and 48GB RAM.

1. Run [fastp](https://github.com/OpenGene/fastp) for QC and Adapter Trimming
---
``` bash
snakemake --snakefile 01_QC/Snakefile --directory 01_QC --use-conda --cores 8
```

2. Generate [STAR](https://github.com/alexdobin/STAR) Reference From Ensembl Files
---
``` bash
STAR --runMode genomeGenerate --genomeDir {} --genomeFastaFiles {} --sjdbGTFfile --sjdbOverhang
```

3. Map Reads with Splice-Aware Aligner [STAR](https://github.com/alexdobin/STAR)
---
``` bash
snakemake --snakefile 02_Mapping/Snakefile --directory 02_Mapping --use-conda --cores 8
```

---
