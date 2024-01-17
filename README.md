# wes-pdac-claire

- [wes-pdac-claire](#wes-pdac-claire)
- [Raw data](#raw-data)
- [Directory organisation](#directory-organisation)
- [Input files](#input-files)
- [Method summary](#method-summary)

# Raw data
- WES Batch 1 : s3://claire-booney-052023-data

- WES Batch 1 processed data: s3://booney-wes. **Note, the processed data for WES batch 1 is 
not in biodebian due to space constraints, hence, processed data should be retrieved from the
S3 bucket**.

- WES Batch 2: s3://booney-wes-2

- RNAseq: s3://booney-rnaseq

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

See `analysis/results_discussion.pdf` methods section.