#!/usr/bin/env bash

# AJB - Jan 2025

# This script uses rsync to download two files from ENSEMBL:
#    1. The latest full Mus musculus assembly (.fa)
#    2. The latest full Mus musculus annotation file (.gtf)
# Both of these files are required for STAR to generate a genome index.

# Make folder from main
mkdir GRCm39

# Download assembly into GRCm39/
rsync -hav rsync://ftp.ensembl.org/ensembl/pub/release-113/fasta/mus_musculus/dna/Mus_musculus.GRCm39.dna_rm.primary_assembly.fa.gz GRCm39/
# Download annotations into GRCm39/
rsync -hav rsync://ftp.ensembl.org/ensembl/pub/release-113/gtf/mus_musculus/Mus_musculus.GRCm39.113.gtf.gz GRCm39/

# Unzip both files
gunzip GRCm39/*.gz
