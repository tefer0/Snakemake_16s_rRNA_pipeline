#!/bin/bash
FLAGS=['flags-ov-demuxSumm.done','flags-ov-featTabSumm.done','flags-ov-denoiseStats.done','flags-ov-vizTaxonomy.done',
'flags-ov-barplot.done','flags-ov-alphaRarefy.done','flags-ov-alphaGrpSig.done','flags-ov-betaGrpSig.done']

rule all:
    input:
        expand('{Flag}', Flag = FLAGS)

rule import:
    input:
        'ov-manifest.tsv'
    output:
        'flags-ov-import.done','ov-output/demux-single-end-ov.qza'
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
        'flags-ov-import.done','ov-output/demux-single-end-ov.qza'
    output:
        'flags-ov-demuxSumm.done','ov-output/demux-single-end-ov.qzv'
    shell:
        '''
qiime demux summarize \
--i-data {input[1]} \
--o-visualization {output[1]}

touch {output[0]}
'''

rule cutAdaptors:
    input:
        'flags-ov-import.done','ov-output/demux-single-end-ov.qza'
    output:
        'flags-ov-cutAdaptors.done','ov-output/demux-single-end-ov-trimmed.qza'
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
        'flags-ov-cutAdaptors.done','ov-output/demux-single-end-ov-trimmed.qza'
    output:
        'flags-ov-denoise.done','ov-output/table-ov.qza','ov-output/representative-sequences.qza','ov-output/denoise-stats.qza'
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
        'flags-ov-denoise.done','ov-output/table-ov.qza','ov_metadata.csv'
    output:
        'flags-ov-featTabSumm.done','ov-output/table-ov.qzv'
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
        'flags-ov-denoise.done','ov-output/representative-sequences.qza','ov-output/table-ov.qza'
    output:
        'flags-ov-filtSeqs.done','ov-output/filt-rep-seqs.qza'
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
        'flags-ov-denoise.done','ov-output/denoise-stats.qza'
    output:
        'flags-ov-denoiseStats.done','ov-output/denoise-stats.qzv'
    shell:
        '''
qiime metadata tabulate \
--m-input-file {input[1]} \
--o-visualization {output[1]}

touch {output[0]}
'''

rule phylogeny:
    input:
        'flags-ov-filtSeqs.done','ov-output/filt-rep-seqs.qza'
    output:
        'flags-ov-phylogeny.done','ov-output/aligned-rep-seqs.qza','ov-output/masked-aligned-rep-seqs.qza','ov-output/unrooted-tree.qza','ov-output/rooted-tree.qza'
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
        'flags-ov-filtSeqs.done','ov-output/filt-rep-seqs.qza','silva-138-99-seqs.qza','silva-138-99-tax.qza'
    output:
        'flags-ov-taxonomy.done','ov-output/taxonomy-slv-vsearch.qza','ov-output/search-slv-vsearch.qza'
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
        'flags-ov-taxonomy.done','ov-output/taxonomy-slv-vsearch.qza'
    output:
        'flags-ov-vizTaxonomy.done','ov-output/taxonomy-slv-vsearch.qzv'
    shell:
        '''
qiime metadata tabulate \
--m-input-file {input[1]} \
--o-visualization {output[1]}

touch {output[0]}
'''

rule filtBacteria:
    input:
        'flags-ov-taxonomy.done','ov-output/table-ov.qza','ov-output/taxonomy-slv-vsearch.qza'
    output:
        'flags-ov-filtBacteria.done','ov-output/table-ov-filt.qza'
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
        'flags-ov-filtBacteria.done','ov-output/table-ov-filt.qza','ov-output/taxonomy-slv-vsearch.qza','ov_metadata.csv'
    output:
        'flags-ov-barplot.done','ov-output/raw-bar-slv-vsearch-filt.qzv'
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
        'flags-ov-filtBacteria.done','ov-output/rooted-tree.qza','ov-output/table-ov-filt.qza','ov_metadata.csv'
    output:
        directory('ov-output/diversity-core'),'flags-ov-divCore.done'
    shell:
        '''
qiime diversity core-metrics-phylogenetic \
--i-phylogeny {input[1]} \
--i-table {input[2]} \
--p-sampling-depth 1068 \
--m-metadata-file {input[3]} \
--output-dir {output[0]}

touch {output[1]}
'''

rule alphaRarefy:
    input:
        'flags-ov-divCore.done','ov-output/rooted-tree.qza','ov_metadata.csv'
    output:
        'flags-ov-alphaRarefy.done','ov-output/rarefaction.qzv'
    params:
        'ov-output/diversity-core/rarefied_table.qza'
    shell:
        '''
qiime diversity alpha-rarefaction \
--i-table {params[0]} \
--p-max-depth 1068 \
--p-steps 20 \
--i-phylogeny {input[1]} \
--m-metadata-file {input[2]} \
--o-visualization {output[1]}

touch {output[0]}
'''
rule alphaGrpSig:
    input:
        'flags-ov-divCore.done','ov_metadata.csv'
    output:
        'flags-ov-alphaGrpSig.done','ov-output/faith-pd-group-significance.qzv','ov-output/evenness-group-significance.qzv','ov-output/shannon-group-significance.qzv'
    params:
        'ov-output/diversity-core/faith_pd_vector.qza','ov-output/diversity-core/evenness_vector.qza','ov-output/diversity-core/shannon_vector.qza'
    run:
        shell("qiime diversity alpha-group-significance \
--i-alpha-diversity {params[0]} \
--m-metadata-file {input[1]} \
--o-visualization {output[1]}")

        shell("qiime diversity alpha-group-significance \
--i-alpha-diversity {params[1]} \
--m-metadata-file {input[1]} \
--o-visualization {output[2]}")

        shell("qiime diversity alpha-group-significance \
--i-alpha-diversity {params[2]} \
--m-metadata-file {input[1]} \
--o-visualization {output[3]}")

        shell("touch {output[0]}")

rule betaGrpSig:
    input:
        'flags-ov-divCore.done','ov_metadata.csv'
    output:
        'flags-ov-betaGrpSig.done','ov-output/unweighted-unifrac-mmb-significance.qzv','ov-output/weighted-unifrac-mmb-significance.qzv','ov-output/bray_curtis-mmb-significance.qzv'
    params:
        'ov-output/diversity-core/unweighted_unifrac_distance_matrix.qza','ov-output/diversity-core/weighted_unifrac_distance_matrix.qza','ov-output/diversity-core/bray_curtis_distance_matrix.qza'
    run:
        shell("qiime diversity beta-group-significance \
--i-distance-matrix {params[0]} \
--m-metadata-file {input[1]} \
--m-metadata-column mmb \
--o-visualization {output[1]} \
--p-pairwise")

        shell("qiime diversity beta-group-significance \
--i-distance-matrix {params[1]} \
--m-metadata-file {input[1]} \
--m-metadata-column mmb \
--o-visualization {output[2]} \
--p-pairwise")

        shell("qiime diversity beta-group-significance \
--i-distance-matrix {params[2]} \
--m-metadata-file {input[1]} \
--m-metadata-column mmb \
--o-visualization {output[3]} \
--p-pairwise")

        shell("touch {output[0]}")
