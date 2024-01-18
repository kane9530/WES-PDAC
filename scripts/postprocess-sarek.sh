#!/bin/bash
set -eo pipefail

BASE_PATH="/media/gedac/kane/projects/booney_wes/results_wes_2_pad50bp"
FILTER_MAXAF_IMPACT="(MAX_AF < 0.001 or not MAX_AF) and ((IMPACT is HIGH) or (IMPACT is MODERATE and (SIFT match deleterious or PolyPhen match damaging)))"
FILTER_MAXAF="(MAX_AF < 0.001 or not MAX_AF)"

# Loop through each sample folder
for sample_dir in $(ls -d ${BASE_PATH}/annotation/mutect2/*); do
    sample_name=$(basename "$sample_dir")
    printf "Processing $sample_name ...\n"

    # Define folder and file paths
    strelka_dir=${BASE_PATH}/annotation/strelka/${sample_name}
    mutect2_dir=${BASE_PATH}/annotation/mutect2/${sample_name}
    
    strelka_indels_vcf=${strelka_dir}/${sample_name}.strelka.somatic_indels_VEP.ann.vcf.gz
    strelka_snvs_vcf=${strelka_dir}/${sample_name}.strelka.somatic_snvs_VEP.ann.vcf.gz
    mutect2_vcf=${mutect2_dir}/${sample_name}.mutect2.filtered_VEP.ann.vcf.gz

    # Define results filenames
    strelka_concat_vcf=${strelka_dir}/${sample_name}.strelka.somatic_concat_VEP.ann.vcf
    strelka_concat_pass_vcf=${strelka_dir}/${sample_name}.strelka.somatic_concat_VEP.ann.PASS.vcf
    strelka_concat_pass_maxaf_vcf=${strelka_dir}/${sample_name}.strelka.somatic_concat_VEP.ann.PASS.maxAF.vcf
    strelka_concat_pass_maxaf_impact_vcf=${strelka_dir}/${sample_name}.strelka.somatic_concat_VEP.ann.PASS.maxAF.impact.vcf
    strelka_reheader_vcf=${strelka_dir}/${sample_name}.strelka.somatic_concat_VEP.ann.PASS.maxAF.reheader.vcf
    strelka_reorder_vcf=${strelka_dir}/${sample_name}.strelka.somatic_concat_VEP.ann.PASS.maxAF.reordered.vcf

    mutect2_pass_vcf=${mutect2_dir}/${sample_name}.mutect2.filtered_VEP.ann.PASS.vcf
    mutect2_pass_maxaf_vcf=${mutect2_dir}/${sample_name}.mutect2.filtered_VEP.ann.PASS.maxAF.vcf
    mutect2_pass_maxaf_impact_vcf=${mutect2_dir}/${sample_name}.mutect2.filtered_VEP.ann.PASS.maxAF.impact.vcf
    mutect2_reorder_vcf=${mutect2_dir}/${sample_name}..mutect2.filtered_VEP.ann.PASS.maxAF.impact.reordered.vcf

    combined_vcf=${BASE_PATH}/combined/vcf/${sample_name}.combined.vcf
    combined_maf=${BASE_PATH}/combined/maf/${sample_name}.combined.maf

    # Check if all the required files exist
    if [[ -f "$strelka_indels_vcf" && -f "$mutect2_vcf"  && -f "$strelka_snvs_vcf" ]]; then
        printf "All files are present in ${sample_name} directory! \n"

        # First, Strelka:
        ## Combine the SNPs and INDELs from Strelka
        bcftools concat -a $strelka_snvs_vcf $strelka_indels_vcf >  $strelka_concat_vcf
        printf "Concatenated Strelka SNVs and INDELs for ${sample_name}! \n"

        ## Filter that PASS internal filter and bgzip as well as bcftools index this file.
        bcftools view -f PASS $strelka_concat_vcf > $strelka_concat_pass_vcf
        printf "Filtered Strelka VCF by internal PASS filter for ${sample_name}! \n"

        ## Filter MAX_AF filter
        filter_vep --format vcf -i $strelka_concat_pass_vcf \
        -o $strelka_concat_pass_maxaf_vcf \
        --filter "(MAX_AF < 0.001 or not MAX_AF)" \
        --force_overwrite
        printf "Filtered Strelka VCF by maxAF and impact filters for ${sample_name}! \n"

        # Mutect2 
        ## Filter that PASS internal filter, and bgzip as well as bcftools index this file.
        bcftools view -f PASS $mutect2_vcf > $mutect2_pass_vcf
        printf "Filtered mutect2 VCF by internal PASS filter for ${sample_name}! \n"

        ## Filter MAX_AF filter
        filter_vep --format vcf -i $mutect2_pass_vcf \
        -o $mutect2_pass_maxaf_vcf \
        --filter "(MAX_AF < 0.001 or not MAX_AF)" \
        --force_overwrite

        bgzip -f $mutect2_pass_maxaf_vcf
        bcftools index $mutect2_pass_maxaf_vcf.gz
        printf "Filtered mutect2 VCF by maxAF and impact filters for ${sample_name}, bgzipped and indexed! \n"

        # Combine callers script

        echo "Getting the sample names from the Mutect2 VCF..."
        MUTECT2_NAMES=$(bcftools query -l "$mutect2_vcf")

        # Split the names into an array
        readarray -t MUTECT2_NAMES_ARRAY <<<"$MUTECT2_NAMES"

        NORMAL_NAME=""
        TUMOR_NAME=""

        echo "Identifying Normal and Tumor sample names..."
        for name in "${MUTECT2_NAMES_ARRAY[@]}"; do
            if [[ $name == *"PBMC"* ]]; then
                NORMAL_NAME=$name
            else
                TUMOR_NAME=$name
            fi
        done

        echo "Normal Sample Name: $NORMAL_NAME"
        echo "Tumor Sample Name: $TUMOR_NAME"

        echo "Renaming the samples in the Strelka VCF..."
        bcftools reheader -s <(echo -e "NORMAL\nTUMOR" | awk -v n="$NORMAL_NAME" -v t="$TUMOR_NAME" 'BEGIN{FS=OFS="\t"} /NORMAL/{print n} /TUMOR/{print t}') -o "$strelka_reheader_vcf" "$strelka_concat_pass_maxaf_vcf"
        
        echo "Rearranging the samples in the Strelka and Mutect2 VCF, bgzipping and indexing..."
        bcftools view -s "$TUMOR_NAME,$NORMAL_NAME" -Oz -o "$strelka_reorder_vcf" "$strelka_reheader_vcf"
        bgzip -f $strelka_reorder_vcf
        bcftools index $strelka_reorder_vcf.gz

        bcftools view -s "$TUMOR_NAME,$NORMAL_NAME" -Oz -o "$mutect2_reorder_vcf" "$mutect2_pass_maxaf_vcf.gz"
        bgzip -f $mutect2_reorder_vcf
        bcftools index $mutect2_reorder_vcf.gz

        echo "Concatenating the Mutect2 and reordered Strelka VCFs..."
        bcftools concat -a -Oz -o "$combined_vcf" "$mutect2_reorder_vcf.gz" "$strelka_reorder_vcf.gz"

        echo "The combined vcf file is saved as $combined_vcf"

        # Convert VCF to MAF and output in directory called maf.
        vcf2maf.pl --input-vcf "$combined_vcf" --output-maf "$combined_maf" \
        --inhibit-vep --ref-fasta "/media/gedac/kane/projects/booney_wes/Homo_sapiens_assembly38.fasta" \
        --tumor-id $TUMOR_NAME \
        --normal-id $NORMAL_NAME
        echo "The maf file is saved as $combined_maf!"
        echo "Procssing of ${sample_name} is complete !"

    else
        printf "Required files for $sample_name do not exist. Skipping... \n"
    fi
done