#!/bin/bash
set -eo pipefail

BASE_PATH="/media/gedac/kane/projects/booney_wes/results_wes_2_pad50bp/"

# Loop through each sample folder
for sample_dir in $(ls -d ${BASE_PATH}/annotation/mutect2/*); do
    sample_name=$(basename "$sample_dir")
    printf "Processing $sample_name ...\n"

    # Define folder and file paths
    strelka_dir=${BASE_PATH}/annotation/strelka/${sample_name}
    mutect2_dir=${BASE_PATH}/annotation/mutect2/${sample_name}
    
    # Before applying internal PASS filter
    mutect2_vcf_initial=${mutect2_dir}/${sample_name}.mutect2.filtered_VEP.ann.vcf.gz
    strelka_vcf_initial=${strelka_dir}/${sample_name}.strelka.somatic_concat_VEP.ann.vcf

    # After applying maxaf<0.001 filter 
    mutect2_vcf_maxaf=${mutect2_dir}/${sample_name}.mutect2.filtered_VEP.ann.PASS.maxAF.vcf.gz
    strelka_vcf_maxaf=${strelka_dir}/${sample_name}.strelka.somatic_concat_VEP.ann.PASS.maxAF.vcf

    # Final filtered file
    filtered_vcf_final=${BASE_PATH}/combined/vcf/${sample_name}.combined.vcf
    filtered_vcf_norm_final=${BASE_PATH}/combined/vcf/${sample_name}.combined.norm.vcf

    results_dir=${BASE_PATH}/vcfstats/

    # Check if all the required files exist
    if [[ -f "$mutect2_vcf_initial" && -f "$strelka_vcf_initial" ]]; then
        printf "All files are present in ${sample_name} directory! \n"
    else
        printf "Required files for $sample_name do not exist. Skipping... \n"
    fi

    # Run bcftools query and add sample_name column

    echo "Running VCFstats for initial Mutect2 calls: $sample_name"
    bcftools query -f '%FILTER\n' ${mutect2_vcf_initial} | cut -d '=' -f 2 | tr ';' '\n' | sort | uniq -c | awk -v var="$sample_name" '{print var, $0}' > $results_dir/$sample_name.mutect2.initial.vcfStats.txt
    echo "Running VCFstats for initial Strelka2 calls: $sample_name"
    bcftools query -f '%FILTER\n' ${strelka_vcf_initial} | cut -d '=' -f 2 | tr ';' '\n' | sort | uniq -c | awk -v var="$sample_name" '{print var, $0}' > $results_dir/$sample_name.strelka2.initial.vcfStats.txt

    echo "Running VCFstats for maxAF Mutect2 calls: $sample_name"
    bcftools query -f '%FILTER\n' ${mutect2_vcf_maxaf} | cut -d '=' -f 2 | tr ';' '\n' | sort | uniq -c | awk -v var="$sample_name" '{print var, $0}' > $results_dir/$sample_name.mutect2.maxAF.vcfStats.txt
    echo "Running VCFstats for maxAF Strelka2 calls: $sample_name"
    bcftools query -f '%FILTER\n' ${strelka_vcf_maxaf} | cut -d '=' -f 2 | tr ';' '\n' | sort | uniq -c | awk -v var="$sample_name" '{print var, $0}' > $results_dir/$sample_name.strelka2.maxAF.vcfStats.txt
    
    echo "Normalisaing final VCF file"
    bgzip -f $filtered_vcf_final
    bcftools norm -d any -Ov -o $filtered_vcf_norm_final $filtered_vcf_final.gz 

    echo "Final filtered VCF file for $sample_name"
    bcftools query -f '%FILTER\n' ${filtered_vcf_norm_final} | cut -d '=' -f 2 | tr ';' '\n' | sort | uniq -c | awk -v var="$sample_name" '{print var, $0}' > $results_dir/$sample_name.final.vcfStats.txt
done