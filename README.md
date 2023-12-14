# wes-pdac-claire

- [wes-pdac-claire](#wes-pdac-claire)
  - [Directory organisation](#directory-organisation)
  - [Analysis steps](#analysis-steps)
    - [Run Nfcore/sarek.](#run-nfcoresarek)
    - [Post-processing with custom bash scripts](#post-processing-with-custom-bash-scripts)
    - [Post-processing in R.](#post-processing-in-r)

## Directory organisation

## Analysis steps

### Run Nfcore/sarek.
Key outputs: Annotated vcf files

Inputs 
1. dbNSFP 4.4a
[Resource](https://sites.google.com/site/jpopgen/dbNSFP).
 dbNSFP is a database developed for functional prediction and annotation of all potential non-synonymous single-nucleotide variants (nsSNVs) in the human genome. In nfcore/sarek, we used the Ensembl Variant Effect Predictor (VEP) tool with the dbNSFP plugin for annotation of the identified variants. This is indicated in the
 nfcore configuration files by setting `vep_dbnsfp:true`, the `dbnsfp` field to the path to the dbNSFP database, and the `dbnsfp_tbi` to the path to the tabix indexed file.

 2.  ASCAT 

 3. Twist Biosciences 2.0 exome bed file

[Resource](https://www.twistbioscience.com/resources/data-files/twist-exome-20-bed-files). The bed file was sorted by chromosomal coordinates 
with `sort -k1,1V -k2,2n -k3,3n "input.bed" > output.bed` , and then padded by 50bp
on both ends of the region. This extends each entry by a total of 100bp. The file
is supplied in the nfcore configuration files under the `intervals` field. 

4. wes_input_full.csv
This should be edited to provide the complete file paths to the original fastq files,
and then supplied in the `--input` parameter when calling the nfcore/sarek pipeline.

### Post-processing with custom bash scripts
Key outputs: Processed maf file

### Post-processing in R.
Key outputs: Oncoplot, lollipop plots.