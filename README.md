# wes-pdac-claire

- [wes-pdac-claire](#wes-pdac-claire)
- [Directory organisation](#directory-organisation)
- [Input files](#input-files)
- [Method summary](#method-summary)
  - [Whole Exome sequencing and somatic variant calling {#sarekMethod}](#whole-exome-sequencing-and-somatic-variant-calling-sarekmethod)
  - [Identifyting copy number alterations](#identifyting-copy-number-alterations)
  - [HLA class I typing](#hla-class-i-typing)

# Directory organisation

1. analysis/
Rmd files used to analyse the maf files

2. nfcore/
- config/ 
  - config.json files for nfcore
- *.csv files
Input csv files for nfcore

3. scripts/
Custom bash scripts ran after the nfcore pipeline to generate the vcf and maf files.

4. results/
- first_batch_wes/
Contains the key output files from running the Rmd files in analysis/, and the maf, vcf and vcfstats output from the first batch of 40 WES samples. The full results from the nfcore/sarek pipeline is stored in this S3 bucket: s3://booney-wes/. As of 10/01/24, HLA haplotyping with optitype was run only on the first batch of samples. 
- second_batch_wes/
Same as the first_batch_wes folder but for the second batch of 23 WES samples. Full results are stored in this S3 bucket: s3://booney-wes-2/.
- combined_batches_wes/
Results arising from combining the samples from both batches of WES analysis.

Other folders present in /media/gedac/kane/projects/booney_wes_clean include:
- data/
Contains folders pointing to the raw data for both batches of WES analysis and an RNAseq analysis. For the RNAseq analysis, note that secondary analysis conducted by Novogene is also included. 
- references/
Reference files used to run the nfcore, such as preparatory files for the ascat tool and the dbNSFP database for variant annotation.

# Input files 

1. dbNSFP 4.4a
[Resource](https://sites.google.com/site/jpopgen/dbNSFP).
 dbNSFP is a database developed for functional prediction and annotation of all potential non-synonymous single-nucleotide variants (nsSNVs) in the human genome. In nfcore/sarek, we used the Ensembl Variant Effect Predictor (VEP) tool with the dbNSFP plugin for annotation of the identified variants. This is indicated in the
 nfcore configuration files by setting `vep_dbnsfp:true`, the `dbnsfp` field to the path to the dbNSFP database, and the `dbnsfp_tbi` to the path to the tabix indexed file.

 2.  ASCAT resources

ASCAT resources were generated following the guide from section "How to generate ASCAT resources for exome or targeted sequencing" in the [nfcore/sarek](https://nf-co.re/sarek/3.2.3/docs/usage) page.

 3. Twist Biosciences 2.0 exome bed file

[Resource](https://www.twistbioscience.com/resources/data-files/twist-exome-20-bed-files). The bed file was sorted by chromosomal coordinates 
with `sort -k1,1V -k2,2n -k3,3n "input.bed" > output.bed` , and then padded by 50bp
on both ends of the region. This extends each entry by a total of 100bp. The file
is supplied in the nfcore configuration files under the `intervals` field. 

4. [first_batch|second_batch]_wes_input_full.csv 
This should be edited to provide the complete file paths to the original fastq files,
and then supplied in the `--input` parameter when calling the nfcore/sarek pipeline.

5. [first_batch|second_batch]_nf_params_pad.json and rnaseq_nfcore_config.json
Supply this via the `--params-file` parameter when calling the nfcore/sarek or nfcore/rnaseq pipeline. See the multiqc.html file for the exact command used.

# Method summary

## Whole Exome sequencing and somatic variant calling {#sarekMethod}

The nf-core/sarek (v3.1.2) pipeline from the nf-core collection of workflows, which follows the GATK 
best practices, was used to call short somatic variants (SNVs/INDELs) and copy number alterations (CNAs). The complete parameter
configuration file is stored in the `nf-params-pad.json` file in JSON format, and the pipeline was run 
with ` nextflow run nf-core/sarek -r 3.1.2 --input wes_input_full.csv -params-file nf-params-pad.json -profile docker -resume`. 

In brief, reads were aligned to the human reference genome (GRCh38) using the Burrows
Wheeler Aligner (BWA) with default parameters. Next, the bam files were processed by marking duplicates
and carrying out quality recalibration at the base level. Mutect2 and Strelka2 were used to identify short mutations which include single nucleotide variants (SNVs) and insertion/deletions (INDELs), and subsequently annotated with VEP. Variants identified in either caller were retained for downstream analysis if they met the following criteria:

1. Passed the caller's internal filters
2. Have a MAX_AF score less than 0.001, if the value is present in the CSV INFO column ("maxAF < 0.01 or not MAX_AF"). The MAX_AF score represents the highest allele frequency observed in any population from 1000 genomes, ESP or gnomAD.

The filtered VCF files across both callers were then combined and converted to MAF format with the [vcf2maf](https://github.com/mskcc/vcf2maf) tool. Downstream analysis was carried out in R using the maftools packages, and several heatmaps were drawn with the ComplexHeatmap package. One of the PDO samples, `PCA117_117B_CM+`, was discarded as it had a very low TMB score and did not exhibit the known PDAC mutations. The tumor mutational
burden (TMB) score was computed with the `tmb` function in maftools, with the twist exome panel
capture size of 36.5 MB supplied to the captureSize parameter. 

Mutational data from the TCGA_PAAD cohort was retrieved from maftools with the `tcgaLoad` function. The sample
with the tumor sample barcode of ‘TCGA-IB-7651-01” was excluded from the analysis as it has around two orders of magnitude more
mutations identified than the rest of the samples, making it a clear outlier.

## Identifyting copy number alterations

ASCAT was used to detect copy number alterations in the WES data, by accounting for the admixture
of non-neoplastic cells and tumor ploidy levels.

## HLA class I typing

HLA class I typing was performed with Optitype v1.3.1, implemented using nf-core/hlatyping v2.0.0 of the nf-core collection of workflows (Ewels et al., 2020). The coverage plots (`*coverage_plot.pdf`) that were output from Optitype show clear exome enrichment. Coverage is high on 
both exons 2 and 3 of the HLA Class I loci, as shown by the large green areas (paired-end reads where both ends are aligned to the allele sequence with without any mismatches) that concentrate on 
the grey bands representing the locations of exons 2 and 3. This indicates that high quality data was used for predicting the HLA genotype.