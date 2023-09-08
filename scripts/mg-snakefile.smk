#!/bin/bash
FLAGS=['flags-mg-demuxSumm.done','flags-mg-featTabSumm.done','flags-mg-denoiseStats.done','flags-mg-vizTaxonomy.done',
'flags-mg-barplot.done','flags-mg-alphaRarefy.done','flags-mg-alphaGrpSig.done','flags-mg-betaGrpSig.done']

rule all:
    input:
        expand('{Flag}', Flag = FLAGS)

rule import:
    input:
        'mg-manifest.tsv'
    output:
        'flags-mg-import.done','mg-output/demux-single-end-mg.qza'
    shell:
        '''
qiime tools import \
--type 'SampleData[SequencesWithQuality]' \
--input-path {input} \
--input-format SingleEndFastqManifestPhred33V2 \
--output-path {output[1]} 

touch {output[0]}
'''

rule demuxSumm:
    input:
        'flags-mg-import.done','mg-output/demux-single-end-mg.qza'
    output:
        'flags-mg-demuxSumm.done','mg-output/demux-single-end-mg.qzv'
    shell:
        '''
qiime demux summarize \
--i-data {input[1]} \
--o-visualization {output[1]}

touch {output[0]}
'''

rule cutAdaptors:
    input:
        'flags-mg-import.done','mg-output/demux-single-end-mg.qza'
    output:
        'flags-mg-cutAdaptors.done','mg-output/demux-single-end-mg-trimmed.qza'
    threads:
        11
    shell:
        '''
qiime cutadapt trim-single \
--i-demultiplexed-sequences {input[1]} \
--p-cores 11 \
--p-front AGAGTTTGATCMTGGCTCAG \
--p-adapter TACGGYTACCTTGTTACGACTT \
--o-trimmed-sequences {output[1]}

touch {output[0]}
'''

rule denoise:
    input:
        'flags-mg-cutAdaptors.done','mg-output/demux-single-end-mg-trimmed.qza'
    output:
        'flags-mg-denoise.done','mg-output/table-mg.qza','mg-output/representative-sequences.qza','mg-output/denoise-stats.qza'
    threads:
        12
    shell:
        '''
qiime dada2 denoise-single \
--i-demultiplexed-seqs {input[1]} \
--p-trunc-len 0 \
--p-trunc-q 12 \
--p-n-threads 0 \
--p-trim-left 0 \
--o-table {output[1]} \
--o-representative-sequences {output[2]} \
--o-denoising-stats {output[3]}

touch {output[0]}
'''

rule featTabSumm:
    input:
        'flags-mg-denoise.done','mg-output/table-mg.qza','mg_metadata.csv'
    output:
        'flags-mg-featTabSumm.done','mg-output/table-mg.qzv'
    shell:
        '''
qiime feature-table summarize \
--i-table {input[1]} \
--o-visualization {output[1]} \
--m-sample-metadata-file {input[2]}

touch {output[0]}
'''

rule filtSeqs:
    input:
        'flags-mg-denoise.done','mg-output/representative-sequences.qza','mg-output/table-mg.qza'
    output:
        'flags-mg-filtSeqs.done','mg-output/filt-rep-seqs.qza'
    shell:
        '''
qiime feature-table filter-seqs \
--i-data {input[1]} \
--i-table {input[2]} \
--o-filtered-data {output[1]}

touch {output[0]}
'''

rule denoiseStats:
    input:
        'flags-mg-denoise.done','mg-output/denoise-stats.qza'
    output:
        'flags-mg-denoiseStats.done','mg-output/denoise-stats.qzv'
    shell:
        '''
qiime metadata tabulate \
--m-input-file {input[1]} \
--o-visualization {output[1]}

touch {output[0]}
'''

rule phylogeny:
    input:
        'flags-mg-filtSeqs.done','mg-output/filt-rep-seqs.qza'
    output:
        'flags-mg-phylogeny.done','mg-output/aligned-rep-seqs.qza','mg-output/masked-aligned-rep-seqs.qza','mg-output/unrooted-tree.qza','mg-output/rooted-tree.qza'
    threads:
        12
    shell:
        '''
qiime phylogeny align-to-tree-mafft-fasttree \
--i-sequences {input[1]} \
--o-alignment {output[1]} \
--o-masked-alignment {output[2]} \
--o-tree {output[3]} \
--o-rooted-tree {output[4]} \
--p-n-threads "auto"

touch {output[0]}
'''

rule taxonomy:
    input:
        'flags-mg-filtSeqs.done','mg-output/filt-rep-seqs.qza','silva-138-99-seqs.qza','silva-138-99-tax.qza'
    output:
        'flags-mg-taxonomy.done','mg-output/taxonomy-slv-vsearch.qza','mg-output/search-slv-vsearch.qza'
    shell:
        '''
qiime feature-classifier classify-consensus-vsearch \
--i-query {input[1]} \
--i-reference-reads {input[2]} \
--i-reference-taxonomy {input[3]} \
--o-classification {output[1]} \
--o-search-results {output[2]}

touch {output[0]}
'''

rule vizTaxonomy:
    input:
        'flags-mg-taxonomy.done','mg-output/taxonomy-slv-vsearch.qza'
    output:
        'flags-mg-vizTaxonomy.done','mg-output/taxonomy-slv-vsearch.qzv'
    shell:
        '''
qiime metadata tabulate \
--m-input-file {input[1]} \
--o-visualization {output[1]}

touch {output[0]}
'''

rule filtBacteria:
    input:
        'flags-mg-taxonomy.done','mg-output/table-mg.qza','mg-output/taxonomy-slv-vsearch.qza'
    output:
        'flags-mg-filtBacteria.done','mg-output/table-mg-filt.qza'
    shell:
        '''
qiime taxa filter-table \
--i-table {input[1]} \
--i-taxonomy {input[2]} \
--p-exclude Archaea,Eukaryota,Unassigned,mitochondria,chloroplast \
--o-filtered-table {output[1]}

touch {output[0]}
'''

rule barplot:
    input:
        'flags-mg-filtBacteria.done','mg-output/table-mg-filt.qza','mg-output/taxonomy-slv-vsearch.qza','mg_metadata.csv'
    output:
        'flags-mg-barplot.done','mg-output/raw-bar-slv-vsearch-filt.qzv'
    shell:
        '''
qiime taxa barplot \
--i-table {input[1]} \
--i-taxonomy {input[2]} \
--m-metadata-file {input[3]} \
--o-visualization {output[1]}

touch {output[0]}
'''

rule divCore:
    input:
        'flags-mg-filtBacteria.done','mg-output/rooted-tree.qza','mg-output/table-mg-filt.qza','mg_metadata.csv'
    output:
        'flags-mg-divCore.done',directory('mg-output/diversity-core')
    shell:
        '''
qiime diversity core-metrics-phylogenetic \
--i-phylogeny {input[1]} \
--i-table {input[2]} \
--p-sampling-depth 716 \
--m-metadata-file {input[3]} \
--output-dir {output[1]}

touch {output[0]}
'''

rule alphaRarefy:
    input:
        'flags-mg-divCore.done','mg-output/diversity-core/rarefied_table.qza','mg-output/rooted-tree.qza','mg_metadata.csv'
    output:
        'flags-mg-alphaRarefy.done','mg-output/rarefaction.qzv'
    shell:
        '''
qiime diversity alpha-rarefaction \
--i-table {input[1]} \
--p-max-depth 716 \
--p-steps 20 \
--i-phylogeny {input[2]} \
--m-metadata-file {input[3]} \
--o-visualization {output[1]}

touch {output[0]}
'''
rule alphaGrpSig:
    input:
        'flags-mg-divCore.done','mg-output/diversity-core/faith_pd_vector.qza','mg-output/diversity-core/evenness_vector.qza','mg-output/diversity-core/shannon_vector.qza','mg_metadata.csv'
    output:
        'flags-mg-alphaGrpSig.done','mg-output/faith-pd-group-significance.qzv','mg-output/evenness-group-significance.qzv','mg-output/shannon-group-significance.qzv'
    run:
        shell("qiime diversity alpha-group-significance \
--i-alpha-diversity {input[1]} \
--m-metadata-file {input[4]} \
--o-visualization {output[1]}")

        shell("qiime diversity alpha-group-significance \
--i-alpha-diversity {input[2]} \
--m-metadata-file {input[4]} \
--o-visualization {output[2]}")

        shell("qiime diversity alpha-group-significance \
--i-alpha-diversity {input[3]} \
--m-metadata-file {input[4]} \
--o-visualization {output[3]}")

        shell("touch {output[0]}")

rule betaGrpSig:
    input:
        'flags-mg-divCore.done','mg-output/diversity-core/unweighted_unifrac_distance_matrix.qza','mg-output/diversity-core/weighted_unifrac_distance_matrix.qza','mg-output/diversity-core/bray_curtis_distance_matrix.qza','mg_metadata.csv'
    output:
        'flags-mg-betaGrpSig.done','mg-output/unweighted-unifrac-mmb-significance.qzv','mg-output/weighted-unifrac-mmb-significance.qzv','mg-output/bray_curtis-mmb-significance.qzv'
    run:
        shell("qiime diversity beta-group-significance \
--i-distance-matrix {input[1]} \
--m-metadata-file {input[4]} \
--m-metadata-column mmb \
--o-visualization {output[1]} \
--p-pairwise")

        shell("qiime diversity beta-group-significance \
--i-distance-matrix {input[2]} \
--m-metadata-file {input[4]} \
--m-metadata-column mmb \
--o-visualization {output[2]} \
--p-pairwise")

        shell("qiime diversity beta-group-significance \
--i-distance-matrix {input[3]} \
--m-metadata-file {input[4]} \
--m-metadata-column mmb \
--o-visualization {output[3]} \
--p-pairwise")

        shell("touch {output[0]}")
