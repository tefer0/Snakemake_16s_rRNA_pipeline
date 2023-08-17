from snakemake import rules

STEPS = ['vizTableSummary.ddan','summTable.ddan','vizFiltRepSeqs.ddan','vizDenoiseStats.ddan', 'VizRelFreq.ddan', 
'rarefaction.ddan','vizTaxonomy.ddan','filterbacteria.ddan','vizfilteredBacteria.ddan', 'extractbiom.ddan',
'taxonomyPlot.ddan','grpTreatment.ddan', 'collapseRelAbundance.ddan',]

rule targets:
    input:
        expand('{Step}', Step = STEPS )

rule denoise:    
    input:
        'demux-paired-end.qza'
    output:
        'Comp_SeppSLV/table.qza', 'Comp_SeppSLV/rep-seqs.qza', 'Comp_SeppSLV/denoising-stats.qza', 'denoise.ddan'
    threads:
        11
    shell:
        '''

mkdir -pv Comp_SeppSLV

echo "Please examine the denoising summary and input the forward and reverse trims."

echo "Please input the length of forward primer (usually 0-20)"
read trim_left_f

echo "Please input the length of reverse primer (usually 0-20)"
read trim_left_r

echo "Enter the value for truncating length forward reads (280 for my file)"
read trunc_len_f

echo "Enter the value for truncating length for reverse reads (220 for my file)"
read trunc_len_r

qiime dada2 denoise-paired  \
--i-demultiplexed-seqs {input} \
--p-trim-left-f $trim_left_f --p-trim-left-r $trim_left_r \
--p-trunc-len-f $trunc_len_f --p-trunc-len-r $trunc_len_r \
--p-n-threads 0 \
--o-table  {output[0]} \
--o-representative-sequences {output[1]} \
--o-denoising-stats {output[2]}

touch {output[3]}
        '''

rule filterFreqFeat:   
    input:
        'denoise.ddan','Comp_SeppSLV/table.qza'
    output:
        'Comp_SeppSLV/feat-frequency-filtered-table.qza', 'filterFreqFeat.ddan'
    shell:
        '''
qiime feature-table filter-samples \
--i-table {input[1]} \
--p-min-frequency 10 \
--o-filtered-table {output[0]}

touch {output[1]}
        '''

rule filterFreqSmple:   
    input:
        'filterFreqFeat.ddan','Comp_SeppSLV/feat-frequency-filtered-table.qza'
    output:
        'Comp_SeppSLV/sample-frequency-filtered-table.qza', 'filterFreqsmple.ddan'
    shell:
        '''
qiime feature-table filter-samples \
--i-table {input[1]} \
--p-min-frequency 10 \
--o-filtered-table {output[0]}

touch {output[1]}
        '''

rule vizTableSummary:    
    input:
        'filterFreqsmple.ddan','Comp_SeppSLV/sample-frequency-filtered-table.qza', 'dog.metadata.tsv'
    output:
        'Comp_SeppSLV/table.qzv', 'vizTableSummary.ddan'
    shell:
        '''
qiime feature-table summarize \
--i-table {input[1]} \
--o-visualization {output[0]} \
--m-sample-metadata-file {input[2]}

touch {output[1]}
        '''
rule summTable:    
    input:
        'filterFreqsmple.ddan','Comp_SeppSLV/sample-frequency-filtered-table.qza'
    output:
        'Comp_SeppSLV/table-summary.qzv', 'summTable.ddan'  
    shell:
        '''
qiime feature-table summarize \
--i-table {input[1]} \
--o-visualization {output[0]} 

touch {output[1]}
        '''

rule ftrRepSeqs:    
    input:
        'filterFreqsmple.ddan','Comp_SeppSLV/rep-seqs.qza' ,'Comp_SeppSLV/sample-frequency-filtered-table.qza'
    output:
        'Comp_SeppSLV/rep-seqs-filt.qza', 'ftrRepSeqs.ddan'
    shell:
        '''
qiime feature-table filter-seqs \
--i-data {input[1]} \
--i-table {input[2]} \
--o-filtered-data {output[0]}

touch {output[1]}
        '''

rule vizFiltRepSeqs:    
    input:
        'ftrRepSeqs.ddan','Comp_SeppSLV/rep-seqs-filt.qza'
    output:
        'Comp_SeppSLV/rep-seqs-filt.qzv', 'vizFiltRepSeqs.ddan' 
    shell:
        '''
qiime feature-table tabulate-seqs \
--i-data {input[1]} \
--o-visualization {output[0]}

touch {output[1]}
        '''
rule vizDenoiseStats:    
    input:
        'denoise.ddan','Comp_SeppSLV/denoising-stats.qza'
    output:
        'Comp_SeppSLV/denoising-stats.qzv', 'vizDenoiseStats.ddan'
    shell:
        '''
qiime metadata tabulate \
--m-input-file {input[1]} \
--o-visualization {output[0]}

touch {output[1]}
        '''

rule phylogeny:    
    input:
        'ftrRepSeqs.ddan','Comp_SeppSLV/rep-seqs-filt.qza', 'sepp-refs-silva-128.qza'
    output:
        'Comp_SeppSLV/rooted-tree.qza', 'Comp_SeppSLV/tree-placements.qza', 'phylogeny.ddan'
    threads:
        11
    shell:
        '''
qiime fragment-insertion sepp \                             
--i-representative-sequences {input[1]} \ 
--i-reference-database {input[2]} \    
--o-tree {output[0]} \                        
--o-placements {output[1]} \
--p-threads 0 
touch {output[2]}
        '''

rule rarefaction:    
    input:
        'phylogeny.ddan', 'Comp_SeppSLV/rooted-tree.qza', 'Comp_SeppSLV/sample-frequency-filtered-table.qza', 'dog.metadata.tsv'
    output:
        'Comp_SeppSLV/rarefactionCurves.qzv', 'rarefaction.ddan'
    shell:
        '''
qiime diversity alpha-rarefaction \
--i-table {input[2]} \
--p-max-depth 20443 \
--p-steps 20 \
--i-phylogeny {input[1]} \
--m-metadata-file {input[3]} \
--o-visualization {output[0]}

touch {output[1]}
        '''

rule taxonomyClassification:    
    input:
        'ftrRepSeqs.ddan', 'classifier-slv.qza', 'Comp_SeppSLV/rep-seqs-filt.qza'
    output:
        'Comp_SeppSLV/taxonomy.qza', 'taxonomyClassification.ddan'
    shell:
        '''
qiime feature-classifier classify-sklearn --i-classifier {input[1]} --i-reads {input[2]} --o-classification {output[0]}

touch {output[1]}
        '''

rule vizTaxonomy:    
    input:
        'taxonomyClassification.ddan','Comp_SeppSLV/taxonomy.qza'
    output:
        'Comp_SeppSLV/taxonomy.qzv', 'vizTaxonomy.ddan'
    shell:
        '''
qiime metadata tabulate \
--m-input-file {input[1]} \
--o-visualization {output[0]}

touch {output[1]}
        '''

rule filterbacteria:    
    input:
        'taxonomyClassification.ddan', 'Comp_SeppSLV/taxonomy.qza', 'Comp_SeppSLV/rep-seqs-filt.qza'
    output:
        'Comp_SeppSLV/filtered-rep-seqs.qza', 'filterbacteria.ddan'
    shell:
        '''
qiime taxa filter-seqs \
--i-sequences {input[2]} \
--i-taxonomy {input[1]} \
--p-include d__,p__ \
--p-exclude Archaea,Eukaryota,Unassigned,mitochondria,chloroplast \
--o-filtered-sequences {output[0]}

touch {output[1]}
        '''

rule vizfilteredBacteria:    
    input:
        'filterbacteria.ddan','Comp_SeppSLV/filtered-rep-seqs.qza'
    output:
        'Comp_SeppSLV/filtered-rep-seqs.qzv','vizfilteredBacteria.ddan'
    shell:
        '''
qiime feature-table tabulate-seqs \
--i-data {input[1]} \
--o-visualization {output[0]}

touch {output[1]}
        '''

rule taxonomyPlot:    
    input:
        'taxonomyClassification.ddan', 'Comp_SeppSLV/taxonomy.qza', 'Comp_SeppSLV/sample-frequency-filtered-table.qza', 'dog.metadata.tsv'
    output:
        'Comp_SeppSLV/raw_taxa-bar-plots.qzv', 'taxonomyPlot.ddan'
    shell:
        '''
qiime taxa barplot  \
--i-table {input[2]} \
--i-taxonomy {input[1]}   \
--m-metadata-file {input[3]}  \
--o-visualization {output[0]}

touch {output[1]}
        '''

rule RelAbundanceFeat:
    input:
        'filterFreqsmple.ddan', 'Comp_SeppSLV/sample-frequency-filtered-table.qza', 
    output:
        'Comp_SeppSLV/rAf-table.qza','RelabundanceFeat.ddan'
    shell:
        '''
qiime feature-table relative-frequency \
--i-table {input[1]} \
--o-relative-frequency-table {output[0]} 
touch {output[1]}
        '''        

rule VizRelFreq:
    input:
        'RelabundanceFeat.ddan', 'Comp_SeppSLV/rAf-table.qza' ,'dog.metadata.tsv'
    output:
        'Comp_SeppSLV/rAf-table.qza', 'VizRelFreq.ddan'
    shell:
        '''
qiime feature-table summarize \
--i-table {input[1]} \
--o-visualization {output[0]} \
--m-sample-metadata-file {input[2]}
touch {output[1]}
        '''

rule grpTreatment:    
    input:
        'filterFreqsmple.ddan', 'Comp_SeppSLV/sample-frequency-filtered-table.qza', 'dog.metadata.tsv'
    output:
        'Comp_SeppSLV/table-treatmentgrp.qza', 'grpTreatment.ddan'
    shell:
        '''
qiime feature-table group \
--i-table {input[1]} \
--p-axis sample \
--p-mode sum \
--m-metadata-file {input[2]} \
--m-metadata-column Treatment \
--o-grouped-table {output[0]}

touch {output[1]}
        '''

rule collapseTable:    
    input:
        'taxonomyClassification.ddan', 'Comp_SeppSLV/taxonomy.qza','Comp_SeppSLV/sample-frequency-filtered-table.qza'
    output:
        'Comp_SeppSLV/family-table.qza', 'Comp_SeppSLV/genus-table.qza', 'Comp_SeppSLV/species-table.qza', 'Comp_SeppSLV/kingdom-table.qza', 'Comp_SeppSLV/phylum-table.qza', 'Comp_SeppSLV/class-table.qza', 'Comp_SeppSLV/order-table.qza', 'collapseTable.ddan'
    shell:
        '''
qiime taxa collapse   --i-table {input[2]}   --i-taxonomy {input[1]}   --p-level 5   --o-collapsed-table {output[0]}
qiime taxa collapse   --i-table {input[2]}   --i-taxonomy {input[1]}   --p-level 6   --o-collapsed-table {output[1]}
qiime taxa collapse   --i-table {input[2]}   --i-taxonomy {input[1]}   --p-level 7   --o-collapsed-table {output[2]}
qiime taxa collapse   --i-table {input[2]}   --i-taxonomy {input[1]}   --p-level 1   --o-collapsed-table {output[3]}
qiime taxa collapse   --i-table {input[2]}   --i-taxonomy {input[1]}   --p-level 2   --o-collapsed-table {output[4]}
qiime taxa collapse   --i-table {input[2]}   --i-taxonomy {input[1]}   --p-level 3   --o-collapsed-table {output[5]}
qiime taxa collapse   --i-table {input[2]}   --i-taxonomy {input[1]}   --p-level 4   --o-collapsed-table {output[6]}
touch {output[7]}
        '''

rule collapseRelAbundance:    
    input:
        'collapseTable.ddan','Comp_SeppSLV/family-table.qza', 'Comp_SeppSLV/genus-table.qza', 'Comp_SeppSLV/species-table.qza', 'Comp_SeppSLV/kingdom-table.qza', 'Comp_SeppSLV/phylum-table.qza', 'Comp_SeppSLV/class-table.qza', 'Comp_SeppSLV/order-table.qza'
    output:
        'Comp_SeppSLV/rel-family-table.qza', 'Comp_SeppSLV/rel-genus-table.qza', 'Comp_SeppSLV/rel-species-table.qza', 'Comp_SeppSLV/rel-kingdom-table.qza', 'Comp_SeppSLV/rel-phylum-table.qza', 'Comp_SeppSLV/rel-class-table.qza', 'Comp_SeppSLV/rel-order-table.qza', 'collapseRelAbundance.ddan'
    shell:
        '''
qiime feature-table relative-frequency --i-table {input[1]} --o-relative-frequency-table {output[0]}
qiime feature-table relative-frequency --i-table {input[2]} --o-relative-frequency-table {output[1]}
qiime feature-table relative-frequency --i-table {input[3]} --o-relative-frequency-table {output[2]}
qiime feature-table relative-frequency --i-table {input[4]} --o-relative-frequency-table {output[3]}
qiime feature-table relative-frequency --i-table {input[5]} --o-relative-frequency-table {output[4]}
qiime feature-table relative-frequency --i-table {input[6]} --o-relative-frequency-table {output[5]}
qiime feature-table relative-frequency --i-table {input[7]} --o-relative-frequency-table {output[6]}
touch {output[7]}
        '''
rule extractbiom:
    input:
        'filterFreqsmple.ddan', 'Comp_SeppSLV/sample-frequency-filtered-table.qza'
    output:
        'biomtable', 'extractbiom.ddan'
    shell:
        '''
mkdir -pv biomtable

qiime tools extract \
--input-path {input[1]} \
--output-path {output[0]} || true
touch {output[1]}
        '''
