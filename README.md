## Snakemake 16s rRNA Gene Analysis pipeline
### 16s rRNA gene amplicons analysis written with Snakemake workflow manager and Quantitative Insights into Microbial Ecoloy QIIME2 version 2022.11

## Prerequisites:
### You should be have Snakemake (version 6.15.1 used in this tutorial), QIIME2 (version 2022.11 used in this tutorial)

## Usage:
### 1. Make manifest file using metadata file and data folder path as commandline arguements using the [make_manifest script](https://github.com/tefer0/Snakemake_16s_rRNA_pipeline/blob/main/scripts/mmfst.sh)
### 2. Import data using manifest file using the [import script](https://github.com/tefer0/Snakemake_16s_rRNA_pipeline/blob/main/scripts/import.smk)
### 3. After viewing denoising ouput make necessary changes where applicable (number of threads) in the [composition script](https://github.com/tefer0/Snakemake_16s_rRNA_pipeline/blob/main/scripts/newcomp.gg.smk) and provide the requested parameters from the screen, parameters include length of forward and revervse primers, and truncation length to remove poor quality bases at the ends.
### 4. last step is to run the diversity core script.
