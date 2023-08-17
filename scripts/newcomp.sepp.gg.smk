from snakemake import rules

STEPS = ['vizTableSummary.dan','summTable.dan','vizFiltRepSeqs.dan','vizDenoiseStats.dan', 'VizRelFreq.dan', 
'rarefaction.dan','vizTaxonomy.dan','filterbacteria.dan','vizfilteredBacteria.dan', 'extractbiom.dan',
'taxonomyPlot.dan','grpTreatment.dan', 'collapseRelAbundance.dan',]

rule targets:
    input:
        expand('{Step}', Step = STEPS )

rule denoise:    
    input:
        'demux-paired-end.qza'
    output:
        'Comp_SeppGG/table.qza', 'Comp_SeppGG/rep-seqs.qza', 'Comp_SeppGG/denoising-stats.qza', 'denoise.dan'
    threads:
        11
    shell:
        '''

mkdir -pv Comp_SeppGG

echo "Please examine the denoising summary and input the forward and reverse trims."

echo "Please input the length of forward primer (usually 0-20)"
read trim_left_f

echo "Please input the length of reverse primer (usually 0-20)"
read trim_left_r

echo "Enter the value for truncating length forward reads (280 for my file)"
read trunc_len_f

echo "Enter the value for truncating length for reverse reads (220 for my file)"
read trunc_len_r

qiime dada2 denoise-paired \
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
        'denoise.dan','Comp_SeppGG/table.qza'
    output:
        'Comp_SeppGG/feat-frequency-filtered-table.qza', 'filterFreqFeat.dan'
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
        'filterFreqFeat.dan','Comp_SeppGG/feat-frequency-filtered-table.qza'
    output:
        'Comp_SeppGG/sample-frequency-filtered-table.qza', 'filterFreqsmple.dan'
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
        'filterFreqsmple.dan','Comp_SeppGG/sample-frequency-filtered-table.qza', 'dog.metadata.tsv'
    output:
        'Comp_SeppGG/table.qzv', 'vizTableSummary.dan'
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
        'filterFreqsmple.dan','Comp_SeppGG/sample-frequency-filtered-table.qza'
    output:
        'Comp_SeppGG/table-summary.qzv', 'summTable.dan'  
    shell:
        '''
qiime feature-table summarize \
--i-table {input[1]} \
--o-visualization {output[0]} 

touch {output[1]}
        '''

rule ftrRepSeqs:    
    input:
        'filterFreqsmple.dan','Comp_SeppGG/rep-seqs.qza' ,'Comp_SeppGG/sample-frequency-filtered-table.qza'
    output:
        'Comp_SeppGG/rep-seqs-filt.qza', 'ftrRepSeqs.dan'
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
        'ftrRepSeqs.dan','Comp_SeppGG/rep-seqs-filt.qza'
    output:
        'Comp_SeppGG/rep-seqs-filt.qzv', 'vizFiltRepSeqs.dan' 
    shell:
        '''
qiime feature-table tabulate-seqs \
--i-data {input[1]} \
--o-visualization {output[0]}

touch {output[1]}
        '''
rule vizDenoiseStats:    
    input:
        'denoise.dan','Comp_SeppGG/denoising-stats.qza'
    output:
        'Comp_SeppGG/denoising-stats.qzv', 'vizDenoiseStats.dan'
    shell:
        '''
qiime metadata tabulate \
--m-input-file {input[1]} \
--o-visualization {output[0]}

touch {output[1]}
        '''

rule phylogeny:    
    input:
        'ftrRepSeqs.dan','Comp_SeppGG/rep-seqs-filt.qza', 'sepp-refs-gg-13-8.qza'
    output:
        'Comp_SeppGG/rooted-tree.qza', 'Comp_SeppGG/tree-placements.qza', 'phylogeny.dan'
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
        'phylogeny.dan', 'Comp_SeppGG/rooted-tree.qza', 'Comp_SeppGG/sample-frequency-filtered-table.qza', 'dog.metadata.tsv'
    output:
        'Comp_SeppGG/rarefactionCurves.qzv', 'rarefaction.dan'
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
        'ftrRepSeqs.dan', 'classifier-gg.qza', 'Comp_SeppGG/rep-seqs-filt.qza'
    output:
        'Comp_SeppGG/taxonomy.qza', 'taxonomyClassification.dan'
    shell:
        '''
qiime feature-classifier classify-sklearn --i-classifier {input[1]} --i-reads {input[2]} --o-classification {output[0]}

touch {output[1]}
        '''

rule vizTaxonomy:    
    input:
        'taxonomyClassification.dan','Comp_SeppGG/taxonomy.qza'
    output:
        'Comp_SeppGG/taxonomy.qzv', 'vizTaxonomy.dan'
    shell:
        '''
qiime metadata tabulate \
--m-input-file {input[1]} \
--o-visualization {output[0]}

touch {output[1]}
        '''

rule filterbacteria:    
    input:
        'taxonomyClassification.dan', 'Comp_SeppGG/taxonomy.qza', 'Comp_SeppGG/rep-seqs-filt.qza'
    output:
        'Comp_SeppGG/filtered-rep-seqs.qza', 'filterbacteria.dan'
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
        'filterbacteria.dan','Comp_SeppGG/filtered-rep-seqs.qza'
    output:
        'Comp_SeppGG/filtered-rep-seqs.qzv','vizfilteredBacteria.dan'
    shell:
        '''
qiime feature-table tabulate-seqs \
--i-data {input[1]} \
--o-visualization {output[0]}

touch {output[1]}
        '''

rule taxonomyPlot:    
    input:
        'taxonomyClassification.dan', 'Comp_SeppGG/taxonomy.qza', 'Comp_SeppGG/sample-frequency-filtered-table.qza', 'dog.metadata.tsv'
    output:
        'Comp_SeppGG/raw_taxa-bar-plots.qzv', 'taxonomyPlot.dan'
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
        'filterFreqsmple.dan', 'Comp_SeppGG/sample-frequency-filtered-table.qza', 
    output:
        'Comp_SeppGG/rAf-table.qza','RelabundanceFeat.dan'
    shell:
        '''
qiime feature-table relative-frequency \
--i-table {input[1]} \
--o-relative-frequency-table {output[0]} 
touch {output[1]}
        '''        

rule VizRelFreq:
    input:
        'RelabundanceFeat.dan', 'Comp_SeppGG/rAf-table.qza' ,'dog.metadata.tsv'
    output:
        'Comp_SeppGG/rAf-table.qza', 'VizRelFreq.dan'
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
        'filterFreqsmple.dan', 'Comp_SeppGG/sample-frequency-filtered-table.qza', 'dog.metadata.tsv'
    output:
        'Comp_SeppGG/table-treatmentgrp.qza', 'grpTreatment.dan'
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
        'taxonomyClassification.dan', 'Comp_SeppGG/taxonomy.qza','Comp_SeppGG/sample-frequency-filtered-table.qza'
    output:
        'Comp_SeppGG/family-table.qza', 'Comp_SeppGG/genus-table.qza', 'Comp_SeppGG/species-table.qza', 'Comp_SeppGG/kingdom-table.qza', 'Comp_SeppGG/phylum-table.qza', 'Comp_SeppGG/class-table.qza', 'Comp_SeppGG/order-table.qza', 'collapseTable.dan'
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
        'collapseTable.dan','Comp_SeppGG/family-table.qza', 'Comp_SeppGG/genus-table.qza', 'Comp_SeppGG/species-table.qza', 'Comp_SeppGG/kingdom-table.qza', 'Comp_SeppGG/phylum-table.qza', 'Comp_SeppGG/class-table.qza', 'Comp_SeppGG/order-table.qza'
    output:
        'Comp_SeppGG/rel-family-table.qza', 'Comp_SeppGG/rel-genus-table.qza', 'Comp_SeppGG/rel-species-table.qza', 'Comp_SeppGG/rel-kingdom-table.qza', 'Comp_SeppGG/rel-phylum-table.qza', 'Comp_SeppGG/rel-class-table.qza', 'Comp_SeppGG/rel-order-table.qza', 'collapseRelAbundance.dan'
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
        'filterFreqsmple.dan', 'Comp_SeppGG/sample-frequency-filtered-table.qza'
    output:
        'biomtable', 'extractbiom.dan'
    shell:
        '''
mkdir -pv biomtable

qiime tools extract \
--input-path {input[1]} \
--output-path {output[0]} || true
touch {output[1]}
        '''
