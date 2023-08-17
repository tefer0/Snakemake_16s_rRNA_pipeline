rule all:
    input:
        'silva.nr_v138_1.classifier.qza'

rule importSilva:
    input:
        'silva.nr_v138_1.align'
    output:
        'silva.nr_v138_1.align.qza'
    shell:
        '''
        qiime tools import \
--type FeatureData[Sequence] \
--input-path {input} \
--output-path {output}
        '''

rule importTaxonomy:
    input:
        'silva.nr_v138_1.tax'
    output:
        'silva.nr_v138_1.tax.qza'
    shell:
        '''
        qiime tools import \
--type FeatureData[Taxonomy] \
--input-path {input} \
--output-path {output} \
--input-format HeaderlessTSVTaxonomyFormat
        '''

rule trainclassifier:
    input:
        'silva.nr_v138_1.align.qza', 'silva.nr_v138_1.tax.qza'
    output:
        'silva.nr_v138_1.classifier.qza'
    shell:
        '''
        qiime feature-classifier fit-classifier-naive-bayes \
--i-reference-reads {input[0]} \
--i-reference-taxonomy {input[1]} \
--o-classifier {output}
        '''
