from snakemake import rules

STEPS = ['vizTableSummary.gg.na.done','summTable.gg.na.done','vizFiltRepSeqs.gg.na.done','vizDenoiseStats.gg.na.done', 'VizRelFreq.gg.na.done', 
'rarefaction.gg.na.done','vizTaxonomy.gg.na.done','filterbacteria.gg.na.done','vizfilteredBacteria.gg.na.done', 'extractbiom.gg.na.done',
'taxonomyPlot.gg.na.done','grpTreatment.gg.na.done', 'collapseRelAbundance.gg.na.done',]

rule targets:
    input:
        expand('{Step}', Step = STEPS )

rule denoise:    
    input:
        'demux-paired-end.qza'
    output:
        'Comp_folderGG/table.qza', 'Comp_folderGG/rep-seqs.qza', 'Comp_folderGG/denoising-stats.qza', 'denoise.gg.na.done'
    threads:
        11
    shell:
        '''

mkdir -pv Comp_folderGG

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
        'denoise.gg.na.done','Comp_folderGG/table.qza'
    output:
        'Comp_folderGG/feat-frequency-filtered-table.qza', 'filterFreqFeat.gg.na.done'
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
        'filterFreqFeat.gg.na.done','Comp_folderGG/feat-frequency-filtered-table.qza'
    output:
        'Comp_folderGG/sample-frequency-filtered-table.qza', 'filterFreqsmple.gg.na.done'
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
        'filterFreqsmple.gg.na.done','Comp_folderGG/sample-frequency-filtered-table.qza', 'dog.metadata.tsv'
    output:
        'Comp_folderGG/table.qzv', 'vizTableSummary.gg.na.done'
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
        'filterFreqsmple.gg.na.done','Comp_folderGG/sample-frequency-filtered-table.qza'
    output:
        'Comp_folderGG/table-summary.qzv', 'summTable.gg.na.done'  
    shell:
        '''
qiime feature-table summarize \
--i-table {input[1]} \
--o-visualization {output[0]} 

touch {output[1]}
        '''

rule ftrRepSeqs:    
    input:
        'filterFreqsmple.gg.na.done','Comp_folderGG/rep-seqs.qza' ,'Comp_folderGG/sample-frequency-filtered-table.qza'
    output:
        'Comp_folderGG/rep-seqs-filt.qza', 'ftrRepSeqs.gg.na.done'
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
        'ftrRepSeqs.gg.na.done','Comp_folderGG/rep-seqs-filt.qza'
    output:
        'Comp_folderGG/rep-seqs-filt.qzv', 'vizFiltRepSeqs.gg.na.done' 
    shell:
        '''
qiime feature-table tabulate-seqs \
--i-data {input[1]} \
--o-visualization {output[0]}

touch {output[1]}
        '''
rule vizDenoiseStats:    
    input:
        'denoise.gg.na.done','Comp_folderGG/denoising-stats.qza'
    output:
        'Comp_folderGG/denoising-stats.qzv', 'vizDenoiseStats.gg.na.done'
    shell:
        '''
qiime metadata tabulate \
--m-input-file {input[1]} \
--o-visualization {output[0]}

touch {output[1]}
        '''

rule phylogeny:    
    input:
        'ftrRepSeqs.gg.na.done','Comp_folderGG/rep-seqs-filt.qza'
    output:
        'Comp_folderGG/aligned-rep-seqs.qza', 'Comp_folderGG/masked-aligned-rep-seqs.qza', 'Comp_folderGG/unrooted-tree.qza', 
        'Comp_folderGG/rooted-tree.qza', 'phylogeny.gg.na.done'
    threads:
        11
    shell:
        '''
qiime phylogeny align-to-tree-mafft-fasttree \
--i-sequences {input[1]} \
--o-alignment {output[0]} \
--o-masked-alignment {output[1]} \
--o-tree {output[2]} \
--o-rooted-tree {output[3]} \
--p-n-threads "auto"
touch {output[4]}
        '''

rule rarefaction:    
    input:
        'phylogeny.gg.na.done', 'Comp_folderGG/rooted-tree.qza', 'Comp_folderGG/sample-frequency-filtered-table.qza', 'dog.metadata.tsv'
    output:
        'Comp_folderGG/rarefactionCurves.qzv', 'rarefaction.gg.na.done'
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
        'ftrRepSeqs.gg.na.done', 'classifier-gg.qza', 'Comp_folderGG/rep-seqs-filt.qza'
    output:
        'Comp_folderGG/taxonomy.qza', 'taxonomyClassification.gg.na.done'
    shell:
        '''
qiime feature-classifier classify-sklearn --i-classifier {input[1]} --i-reads {input[2]} --o-classification {output[0]}

touch {output[1]}
        '''

rule vizTaxonomy:    
    input:
        'taxonomyClassification.gg.na.done','Comp_folderGG/taxonomy.qza'
    output:
        'Comp_folderGG/taxonomy.qzv', 'vizTaxonomy.gg.na.done'
    shell:
        '''
qiime metadata tabulate \
--m-input-file {input[1]} \
--o-visualization {output[0]}

touch {output[1]}
        '''

rule filterbacteria:    
    input:
        'taxonomyClassification.gg.na.done', 'Comp_folderGG/taxonomy.qza', 'Comp_folderGG/rep-seqs-filt.qza'
    output:
        'Comp_folderGG/filtered-rep-seqs.qza', 'filterbacteria.gg.na.done'
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
        'filterbacteria.gg.na.done','Comp_folderGG/filtered-rep-seqs.qza'
    output:
        'Comp_folderGG/filtered-rep-seqs.qzv','vizfilteredBacteria.gg.na.done'
    shell:
        '''
qiime feature-table tabulate-seqs \
--i-data {input[1]} \
--o-visualization {output[0]}

touch {output[1]}
        '''

rule taxonomyPlot:    
    input:
        'taxonomyClassification.gg.na.done', 'Comp_folderGG/taxonomy.qza', 'Comp_folderGG/sample-frequency-filtered-table.qza', 'dog.metadata.tsv'
    output:
        'Comp_folderGG/raw_taxa-bar-plots.qzv', 'taxonomyPlot.gg.na.done'
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
        'filterFreqsmple.gg.na.done', 'Comp_folderGG/sample-frequency-filtered-table.qza', 
    output:
        'Comp_folderGG/rAf-table.qza','RelabundanceFeat.gg.na.done'
    shell:
        '''
qiime feature-table relative-frequency \
--i-table {input[1]} \
--o-relative-frequency-table {output[0]} 
touch {output[1]}
        '''        

rule VizRelFreq:
    input:
        'RelabundanceFeat.gg.na.done', 'Comp_folderGG/rAf-table.qza' ,'dog.metadata.tsv'
    output:
        'Comp_folderGG/rAf-table.qzv', 'VizRelFreq.gg.na.done'
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
        'filterFreqsmple.gg.na.done', 'Comp_folderGG/sample-frequency-filtered-table.qza', 'dog.metadata.tsv'
    output:
        'Comp_folderGG/table-treatmentgrp.qza', 'grpTreatment.gg.na.done'
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
        'taxonomyClassification.gg.na.done', 'Comp_folderGG/taxonomy.qza','Comp_folderGG/sample-frequency-filtered-table.qza'
    output:
        'Comp_folderGG/family-table.qza', 'Comp_folderGG/genus-table.qza', 'Comp_folderGG/species-table.qza', 'Comp_folderGG/kingdom-table.qza', 'Comp_folderGG/phylum-table.qza', 'Comp_folderGG/class-table.qza', 'Comp_folderGG/order-table.qza', 'collapseTable.gg.na.done'
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
        'collapseTable.gg.na.done','Comp_folderGG/family-table.qza', 'Comp_folderGG/genus-table.qza', 'Comp_folderGG/species-table.qza', 'Comp_folderGG/kingdom-table.qza', 'Comp_folderGG/phylum-table.qza', 'Comp_folderGG/class-table.qza', 'Comp_folderGG/order-table.qza'
    output:
        'Comp_folderGG/rel-family-table.qza', 'Comp_folderGG/rel-genus-table.qza', 'Comp_folderGG/rel-species-table.qza', 'Comp_folderGG/rel-kingdom-table.qza', 'Comp_folderGG/rel-phylum-table.qza', 'Comp_folderGG/rel-class-table.qza', 'Comp_folderGG/rel-order-table.qza', 'collapseRelAbundance.gg.na.done'
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
        'filterFreqsmple.gg.na.done', 'Comp_folderGG/sample-frequency-filtered-table.qza'
    output:
        directory('biomtable'), 'extractbiom.gg.na.done'
    shell:
        '''
mkdir -pv biomtable

qiime tools extract \
--input-path {input[1]} \
--output-path {output[0]} || true
touch {output[1]}
        '''
