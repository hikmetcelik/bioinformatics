#! /usr/bin/env bash

cd ~/bio-inf

DEFAULT_TRIM_MODE="PE"
DEFAULT_PHRED="-phred64"
DEFAULT_ADAPTER="TruSeq3-PE-2.fa"
ALTERNATIVE_ADAPTER="TruSeq3-PE.fa"
PATH_TRIMMOMATIC="Trimmomatic-0.39/trimmomatic-0.39.jar"

# -ne :not equal
# -lt :less than
# -gt :greater than

if [ "$#" -lt 2 ] || [ "$#" -gt 5 ]; then
	echo "Usage: $0 <outdir> <SRA_number> [<trim_mode=$DEFAULT_TRIM_MODE>] [<phred=$DEFAULT_PHRED>] [<adapter=$DEFAULT_ADAPTER>]>"
	exit 1
fi

target="$1"
SRA_number="$2"
trim_mode="${3:-$DEFAULT_TRIM_MODE}"
phred="${4:-$DEFAULT_PHRED}" # DEFAULT PHRED is Phred64
adapter="${5:-$DEFAULT_ADAPTER}" # DEFAULT ADAPTER is TruSeq3-PE-2.fa

if [ -f "${SRA_number}_1.fastq" ]; then
	echo "File ${SRA_number}_1.fastq is already downloaded. Skipping the download stage!"
else
	fastq-dump --outdir "$target" --split-files "$SRA_number"
fi

echo "The current folder is $(pwd)"

source /etc/profile.d/conda.sh
conda activate trimmomatic_env

# RBT : Report Before Trimming
fastqc "${SRA_number}_1.fastq" 

# R1: Report 1
trimmomatic "$trim_mode" "$phred" \
	"${SRA_number}_1.fastq" "${SRA_number}_2.fastq" \
	"${SRA_number}FP_R1.fq" \
	"${SRA_number}FunP_R1.fq" \
	"${SRA_number}RP_R1.fq" \
	"${SRA_number}RunP_R1.fq" \
	CROP:217  HEADCROP:183 LEADING:4 TRAILING:4 SLIDINGWINDOW:4:28 MINLEN:20
fastqc "${SRA_number}FP_R1.fq"

# RAOT: Report Alternative Adapter  Trimming
trimmomatic "$trim_mode" "$phred" \
	"${SRA_number}_1.fastq" "${SRA_number}_2.fastq" \
	"${SRA_number}FP_RAAT.fq" \
	"${SRA_number}FunP_RAAT.fq" \
	"${SRA_number}RP_RAAT.fq" \
	"${SRA_number}RunP_RAAT.fq" \
	ILLUMINACLIP:Trimmomatic-0.39/adapters/"$ALTERNATIVE_ADAPTER":2:30:10

fastqc "${SRA_number}FP_RAAT.fq"

# RAT: Report After Trimming
# F: Forward	R: Reverse
# P: Paired  	unP: Unpaired
trimmomatic "$trim_mode" "$phred" \
	"${SRA_number}_1.fastq" "${SRA_number}_2.fastq" \
	"${SRA_number}FP_RAT.fq" \
	"${SRA_number}FunP_RAT.fq" \
	"${SRA_number}RP_RAT.fq" \
	"${SRA_number}RunP_RAT.fq" \
	ILLUMINACLIP:"Trimmomatic-0.39/adapters/$adapter":2:30:10

fastqc "${SRA_number}FP_RAT.fq"

conda deactivate
