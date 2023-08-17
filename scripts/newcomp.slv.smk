from snakemake import rules

STEPS = ['vizTableSummary.slv.na.done','summTable.slv.na.done','vizFiltRepSeqs.slv.na.done','vizDenoiseStats.slv.na.done', 'VizRelFreq.slv.na.done', 
'rarefaction.slv.na.done','vizTaxonomy.slv.na.done','filterbacteria.slv.na.done','vizfilteredBacteria.slv.na.done', 'extractbiom.slv.na.done',
'taxonomyPlot.slv.na.done','grpTreatment.slv.na.done', 'collapseRelAbundance.slv.na.done',]

rule targets:
    input:
        expand('{Step}', Step = STEPS )

rule denoise:    
    input:
        'demux-paired-end.qza'
    output:
        'Comp_folderSLV/table.qza', 'Comp_folderSLV/rep-seqs.qza', 'Comp_folderSLV/denoising-stats.qza', 'denoise.slv.na.done'
    threads:
        11
    shell:
        '''

mkdir -pv Comp_folderSLV

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
        'denoise.slv.na.done','Comp_folderSLV/table.qza'
    output:
        'Comp_folderSLV/feat-frequency-filtered-table.qza', 'filterFreqFeat.slv.na.done'
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
        'filterFreqFeat.slv.na.done','Comp_folderSLV/feat-frequency-filtered-table.qza'
    output:
        'Comp_folderSLV/sample-frequency-filtered-table.qza', 'filterFreqsmple.slv.na.done'
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
        'filterFreqsmple.slv.na.done','Comp_folderSLV/sample-frequency-filtered-table.qza', 'dog.metadata.tsv'
    output:
        'Comp_folderSLV/table.qzv', 'vizTableSummary.slv.na.done'
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
        'filterFreqsmple.slv.na.done','Comp_folderSLV/sample-frequency-filtered-table.qza'
    output:
        'Comp_folderSLV/table-summary.qzv', 'summTable.slv.na.done'  
    shell:
        '''
qiime feature-table summarize \
--i-table {input[1]} \
--o-visualization {output[0]} 

touch {output[1]}
        '''

rule ftrRepSeqs:    
    input:
        'filterFreqsmple.slv.na.done','Comp_folderSLV/rep-seqs.qza' ,'Comp_folderSLV/sample-frequency-filtered-table.qza'
    output:
        'Comp_folderSLV/rep-seqs-filt.qza', 'ftrRepSeqs.slv.na.done'
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
        'ftrRepSeqs.slv.na.done','Comp_folderSLV/rep-seqs-filt.qza'
    output:
        'Comp_folderSLV/rep-seqs-filt.qzv', 'vizFiltRepSeqs.slv.na.done' 
    shell:
        '''
qiime feature-table tabulate-seqs \
--i-data {input[1]} \
--o-visualization {output[0]}

touch {output[1]}
        '''
rule vizDenoiseStats:    
    input:
        'denoise.slv.na.done','Comp_folderSLV/denoising-stats.qza'
    output:
        'Comp_folderSLV/denoising-stats.qzv', 'vizDenoiseStats.slv.na.done'
    shell:
        '''
qiime metadata tabulate \
--m-input-file {input[1]} \
--o-visualization {output[0]}

touch {output[1]}
        '''

rule phylogeny:    
    input:
        'ftrRepSeqs.slv.na.done','Comp_folderSLV/rep-seqs-filt.qza'
    output:
        'Comp_folderSLV/aligned-rep-seqs.qza', 'Comp_folderSLV/masked-aligned-rep-seqs.qza', 'Comp_folderSLV/unrooted-tree.qza', 
        'Comp_folderSLV/rooted-tree.qza', 'phylogeny.slv.na.done'
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
        'phylogeny.slv.na.done', 'Comp_folderSLV/rooted-tree.qza', 'Comp_folderSLV/sample-frequency-filtered-table.qza', 'dog.metadata.tsv'
    output:
        'Comp_folderSLV/rarefactionCurves.qzv', 'rarefaction.slv.na.done'
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
        'ftrRepSeqs.slv.na.done', 'classifier-slv.qza', 'Comp_folderSLV/rep-seqs-filt.qza'
    output:
        'Comp_folderSLV/taxonomy.qza', 'taxonomyClassification.slv.na.done'
    shell:
        '''
qiime feature-classifier classify-sklearn --i-classifier {input[1]} --i-reads {input[2]} --o-classification {output[0]}

touch {output[1]}
        '''

rule vizTaxonomy:    
    input:
        'taxonomyClassification.slv.na.done','Comp_folderSLV/taxonomy.qza'
    output:
        'Comp_folderSLV/taxonomy.qzv', 'vizTaxonomy.slv.na.done'
    shell:
        '''
qiime metadata tabulate \
--m-input-file {input[1]} \
--o-visualization {output[0]}

touch {output[1]}
        '''

rule filterbacteria:    
    input:
        'taxonomyClassification.slv.na.done', 'Comp_folderSLV/taxonomy.qza', 'Comp_folderSLV/rep-seqs-filt.qza'
    output:
        'Comp_folderSLV/filtered-rep-seqs.qza', 'filterbacteria.slv.na.done'
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
        'filterbacteria.slv.na.done','Comp_folderSLV/filtered-rep-seqs.qza'
    output:
        'Comp_folderSLV/filtered-rep-seqs.qzv','vizfilteredBacteria.slv.na.done'
    shell:
        '''
qiime feature-table tabulate-seqs \
--i-data {input[1]} \
--o-visualization {output[0]}

touch {output[1]}
        '''

rule taxonomyPlot:    
    input:
        'taxonomyClassification.slv.na.done', 'Comp_folderSLV/taxonomy.qza', 'Comp_folderSLV/sample-frequency-filtered-table.qza', 'dog.metadata.tsv'
    output:
        'Comp_folderSLV/raw_taxa-bar-plots.qzv', 'taxonomyPlot.slv.na.done'
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
        'filterFreqsmple.slv.na.done', 'Comp_folderSLV/sample-frequency-filtered-table.qza', 
    output:
        'Comp_folderSLV/rAf-table.qza','RelabundanceFeat.slv.na.done'
    shell:
        '''
qiime feature-table relative-frequency \
--i-table {input[1]} \
--o-relative-frequency-table {output[0]} 
touch {output[1]}
        '''        

rule VizRelFreq:
    input:
        'RelabundanceFeat.slv.na.done', 'Comp_folderSLV/rAf-table.qza' ,'dog.metadata.tsv'
    output:
        'Comp_folderSLV/rAf-table.qzv', 'VizRelFreq.slv.na.done'
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
        'filterFreqsmple.slv.na.done', 'Comp_folderSLV/sample-frequency-filtered-table.qza', 'dog.metadata.tsv'
    output:
        'Comp_folderSLV/table-treatmentgrp.qza', 'grpTreatment.slv.na.done'
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
        'taxonomyClassification.slv.na.done', 'Comp_folderSLV/taxonomy.qza','Comp_folderSLV/sample-frequency-filtered-table.qza'
    output:
        'Comp_folderSLV/family-table.qza', 'Comp_folderSLV/genus-table.qza', 'Comp_folderSLV/species-table.qza', 'Comp_folderSLV/kingdom-table.qza', 'Comp_folderSLV/phylum-table.qza', 'Comp_folderSLV/class-table.qza', 'Comp_folderSLV/order-table.qza', 'collapseTable.slv.na.done'
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
        'collapseTable.slv.na.done','Comp_folderSLV/family-table.qza', 'Comp_folderSLV/genus-table.qza', 'Comp_folderSLV/species-table.qza', 'Comp_folderSLV/kingdom-table.qza', 'Comp_folderSLV/phylum-table.qza', 'Comp_folderSLV/class-table.qza', 'Comp_folderSLV/order-table.qza'
    output:
        'Comp_folderSLV/rel-family-table.qza', 'Comp_folderSLV/rel-genus-table.qza', 'Comp_folderSLV/rel-species-table.qza', 'Comp_folderSLV/rel-kingdom-table.qza', 'Comp_folderSLV/rel-phylum-table.qza', 'Comp_folderSLV/rel-class-table.qza', 'Comp_folderSLV/rel-order-table.qza', 'collapseRelAbundance.slv.na.done'
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
        'filterFreqsmple.slv.na.done', 'Comp_folderSLV/sample-frequency-filtered-table.qza'
    output:
        directory('biomtable'), 'extractbiom.slv.na.done'
    shell:
        '''
mkdir -pv biomtable

qiime tools extract \
--input-path {input[1]} \
--output-path {output[0]} || true
touch {output[1]}
        '''
