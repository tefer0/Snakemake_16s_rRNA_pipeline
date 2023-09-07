#import:

qiime tools import \
--type 'SampleData[SequencesWithQuality]' \
--input-path new-ov-manifest.tsv \
--input-format SingleEndFastqManifestPhred33V2 \
--output-path output/demux-single-end.qza

#demux-summary:

qiime demux summarize \
--i-data output/demux-single-end.qza \
--o-visualization output/demux-single-end.qzv

#cutadptors:

qiime cutadapt trim-single \
--i-demultiplexed-sequences output/demux-single-end.qza \
--p-cores 11 \
--p-front AGAGTTTGATCMTGGCTCAG \
--p-adapter TACGGYTACCTTGTTACGACTT \
--o-trimmed-sequences output/trimmed-se.qza

#denoise:

qiime dada2 denoise-single \
--i-demultiplexed-seqs output/demux-single-end.qza \
--p-trunc-len 0 \
--p-trunc-q 12 \
--p-n-threads 0 \
--p-trim-left 0 \
--o-table output/table-dammy.qza \
--o-representative-sequences output/representative-sequences.qza \
--o-denoising-stats output/denoise-stats.qza

#feature-summary: (try heatmap,group,rarefy,relative freq)

qiime feature-table summarize \
--i-table output/table-dammy.qza \
--o-visualization output/table-dammy.qzv \
--m-sample-metadata-file ov_metadata.csv

#filter rep seqs

qiime feature-table filter-seqs \
--i-data output/representative-sequences.qza \
--i-table output/table-dammy.qza \
--o-filtered-data output/filt-rep-seqs.qza

#viz filt rep seqs (unnecesary)

qiime feature-table tabulate-seqs \
--i-data output/filt-rep-seqs.qza \
--o-visualization output/filt-rep-seqs.qzv

#viz denoise stats (supplimentary mats)

qiime metadata tabulate \
--m-input-file output/denoise-stats.qza \
--o-visualization output/denoise-stats.qzv

#phylogeny (try other options)

qiime phylogeny align-to-tree-mafft-fasttree \
--i-sequences output/filt-rep-seqs.qza \
--o-alignment output/aligned-rep-seqs.qza \
--o-masked-alignment output/masked-aligned-rep-seqs.qza \
--o-tree output/unrooted-tree.qza \
--o-rooted-tree output/rooted-tree.qza \
--p-n-threads "auto"

# #rarefaction 

# qiime diversity alpha-rarefaction \
# --i-table output/table-dammy.qza \
# --p-max-depth 1068 \
# --p-steps 5 \
# --i-phylogeny output/rooted-tree.qza \
# --m-metadata-file ov_metadata.csv \
# --o-visualization output/rarefaction.qzv

#taxonomy

# qiime feature-classifier classify-sklearn \
# --i-classifier gg-13-8-99-nb-classifier.qza \
# --i-reads output/filt-rep-seqs.qza \
# --p-n-jobs -2 \
# --o-classification output/taxonomy-gg.qza

# qiime feature-classifier classify-sklearn \
# --i-classifier silva-138-99-nb-classifier.qza \
# --i-reads output/filt-rep-seqs.qza \
# --p-n-jobs -2 \
# --o-classification output/taxonomy-slv.qza

qiime feature-classifier classify-consensus-vsearch \
--i-query output/filt-rep-seqs.qza \
--i-reference-reads silva-138-99-seqs.qza \
--i-reference-taxonomy silva-138-99-tax.qza \
--o-classification output/taxonomy-slv-vsearch.qza \
--o-search-results output/search-slv-vsearch.qza

# qiime feature-classifier classify-consensus-blast \
# --i-query output/filt-rep-seqs.qza \
# --i-reference-reads silva-138-99-seqs.qza \
# --i-reference-taxonomy silva-138-99-tax.qza \
# --o-classification output/taxonomy-slv-blast.qza \
# --o-search-results output/search-slv-blast.qza

# qiime feature-classifier classify-hybrid-vsearch-sklearn \ #(not fxnal for gg)
# --i-query \
# --i-reference-reads \
# --i-reference-taxonomy \
# --i-classifier \
# --p-n-jobs -2 \
# --o-classification 

#viz taxonomy

qiime metadata tabulate \
--m-input-file output/taxonomy-slv-vsearch.qza \
--o-visualization output/taxonomy-slv-vsearch.qzv

# qiime metadata tabulate \
# --m-input-file output/taxonomy-slv-blast.qza \
# --o-visualization output/taxonomy-slv-blast.qzv

#filter bacteria

# qiime taxa filter-table \
# --i-table output/table-dammy.qza \
# --i-taxonomy output/taxonomy-slv-blast.qza \
# --p-exclude Archaea,Eukaryota,Unassigned,mitochondria,chloroplast \
# --o-filtered-table output/table-dammy-filt.qza

qiime taxa filter-table \
--i-table output/table-dammy.qza \
--i-taxonomy output/taxonomy-slv-vsearch.qza \
--p-exclude Archaea,Eukaryota,Unassigned,mitochondria,chloroplast \
--o-filtered-table output/table-dammy-filt2.qza

# qiime metadata tabulate \ #not useful
# --m-input-file output/table-dammy-filt.qza \
# --o-visualization output/table-dammy-filt.qzv

qiime feature-table summarize \
--i-table output/table-dammy-filt2.qza \
--o-visualization output/table-dammy-filt.qzv \
--m-sample-metadata-file ov_metadata.csv


#barplot rel freq

qiime taxa barplot \
--i-table output/table-dammy-filt2.qza \
--i-taxonomy output/taxonomy-slv-vsearch.qza \
--m-metadata-file ov_metadata.csv \
--o-visualization output/raw-bar-slv-vsearch.qzv

# qiime taxa barplot \
# --i-table output/table-dammy-filt.qza \
# --i-taxonomy output/taxonomy-slv-blast.qza \
# --m-metadata-file ov_metadata.csv \
# --o-visualization output/raw-bar-slv-blast-filt.qzv

# #relative freq -supplimentary material

# qiime feature-table relative-frequency \
# --i-table output/table-dammy-filt.qza \
# --o-relative-frequency-table output/rel-bar-slv-blast-filt.qza

# qiime feature-table summarize \
# --i-table output/rel-bar-slv-blast-filt.qza \
# --o-visualization output/rel-bar-slv-blast-filt.qzv \
# --m-sample-metadata-file ov_metadata.csv

# #heatmap, corefeatures, biomtable

# qiime feature-table heatmap \
# --i-table output/table-dammy-filt.qza \
# --m-sample-metadata-file ov_metadata.csv \
# --m-sample-metadata-column mmb \
# --o-visualization output/heat-bar-slv-blast-filt.qzv

# qiime feature-table core-features \
# --i-table output/table-dammy-filt.qza \
# --o-visualization output/core-feats-slv-blast-filt.qzv

# qiime feature-table core-features \
# --i-table output/table-dammy-filt2.qza \
# --o-visualization output/core-feats-slv-vsearch-filt.qzv

qiime tools extract \
--input-path output/table-dammy-filt.qza \
--output-path output/biomtable


# #ancom
# qiime composition add-pseudocount \
# --i-table output/table-dammy-filt.qza \
# --o-composition-table output/comp-add-pseudocount-slv-blast-filt.qza

# qiime composition add-pseudocount \
# --i-table output/table-dammy-filt2.qza \
# --o-composition-table output/comp-add-pseudocount-slv-vsearch-filt.qza

# qiime composition ancom \
# --i-table output/comp-add-pseudocount-slv-blast-filt.qza  \
# --m-metadata-file ov_metadata.csv \
# --m-metadata-column mmb \
# --o-visualization output/ancom-slv-blast-filt.qzv  

# qiime composition ancom \
# --i-table output/comp-add-pseudocount-slv-vsearch-filt.qza  \
# --m-metadata-file ov_metadata.csv \
# --m-metadata-column mmb \
# --o-visualization output/ancom-slv-vsearch-filt.qzv 



# qiime diversity beta-rarefaction \
# --i-table output/diversity-core/rarefied_table.qza  \
# --i-phylogeny output/rooted-tree.qza \
# --p-metric unweighted_unifrac \
# --p-clustering-method nj \
# --p-sampling-depth 1068 \
# --m-metadata-file ov_metadata.csv \
# --o-visualization output/diversity-core/beta-rarefy.qzv

# qiime diversity beta-rarefaction \
# --i-table output/diversity-core/rarefied_table.qza  \
# --i-phylogeny output/rooted-tree.qza \
# --p-metric unweighted_unifrac \
# --p-clustering-method upgma \
# --p-sampling-depth 1068 \
# --m-metadata-file ov_metadata.csv \
# --o-visualization output/diversity-core/beta-rarefy2.qzv


# weighted_unifrac, braycurtis, jaccard | upgma

# diversity core

qiime diversity core-metrics-phylogenetic \
--i-phylogeny output/rooted-tree.qza \
--i-table output/table-dammy-filt2.qza \
--p-sampling-depth 1068 \
--m-metadata-file ov_metadata.csv \
--output-dir output/diversity-core

#rarefaction 

qiime diversity alpha-rarefaction \
--i-table output/diversity-core/rarefied_table.qza  \
--p-max-depth 1068 \
--p-steps 20 \
--i-phylogeny output/rooted-tree.qza \
--m-metadata-file ov_metadata.csv \
--o-visualization output/diversity-core/alpha-rarefy.qzv

#alpha sig 

qiime diversity alpha-group-significance \
--i-alpha-diversity output/diversity-core/faith_pd_vector.qza \
--m-metadata-file ov_metadata.csv \
--o-visualization output/diversity-core/faith-pd-group-significance.qzv

qiime diversity alpha-group-significance \
--i-alpha-diversity output/diversity-core/evenness_vector.qza \
--m-metadata-file ov_metadata.csv \
--o-visualization output/diversity-core/evenness-group-significance.qzv

qiime diversity alpha-group-significance \
--i-alpha-diversity output/diversity-core/shannon_vector.qza \
--m-metadata-file ov_metadata.csv \
--o-visualization output/diversity-core/shannon-group-significance.qzv

qiime diversity alpha-group-significance \
--i-alpha-diversity output/diversity-core/observed_features_vector.qza \
--m-metadata-file ov_metadata.csv \
--o-visualization output/diversity-core/observed_features-group-significance.qzv

#beta sig 

qiime diversity beta-group-significance \
--i-distance-matrix output/diversity-core/unweighted_unifrac_distance_matrix.qza \
--m-metadata-file ov_metadata.csv \
--m-metadata-column mmb \
--o-visualization output/diversity-core/unweighted-unifrac-mmb-significance.qzv \
--p-pairwise


qiime diversity beta-group-significance \
--i-distance-matrix output/diversity-core/weighted_unifrac_distance_matrix.qza \
--m-metadata-file ov_metadata.csv \
--m-metadata-column mmb \
--o-visualization output/diversity-core/weighted-unifrac-mmb-significance.qzv \
--p-pairwise

qiime diversity beta-group-significance \
--i-distance-matrix output/diversity-core/jaccard_distance_matrix.qza \
--m-metadata-file ov_metadata.csv \
--m-metadata-column mmb \
--o-visualization output/diversity-core/jaccard-mmb-significance.qzv \
--p-pairwise

qiime diversity beta-group-significance \
--i-distance-matrix output/diversity-core/bray_curtis_distance_matrix.qza \
--m-metadata-file ov_metadata.csv \
--m-metadata-column mmb \
--o-visualization output/diversity-core/bray_curtis-mmb-significance.qzv \
--p-pairwise

#emperor plots #same alpha plots

# qiime emperor plot \
# --i-pcoa output/diversity-core/unweighted_unifrac_pcoa_results.qza \
# --m-metadata-file ov_metadata.csv \
# --o-visualization output/diversity-core/unweighted-unifrac-emperor.qzv

# qiime emperor plot \
# --i-pcoa output/diversity-core/unweighted_unifrac_pcoa_results.qza \
# --m-metadata-file ov_metadata.csv \
# --p-custom-axes mmb \
# --o-visualization output/diversity-core/unweighted-unifrac-mmb.qzv

# qiime emperor plot \
# --i-pcoa output/diversity-core/weighted_unifrac_pcoa_results.qza \
# --m-metadata-file ov_metadata.csv \
# --o-visualization output/diversity-core/weighted-unifrac-emperor.qzv

# qiime emperor plot \
# --i-pcoa output/diversity-core/weighted_unifrac_pcoa_results.qza \
# --m-metadata-file ov_metadata.csv \
# --p-custom-axes mmb \
# --o-visualization diversity-core/weighted-unifrac-mmb.qzv


# qiime emperor plot \
# --i-pcoa output/diversity-core/bray_curtis_pcoa_results.qza \
# --m-metadata-file ov_metadata.csv \
# --o-visualization output/diversity-core/bray-curtis_pcoa.qzv

# qiime emperor plot \
# --i-pcoa output/diversity-core/bray_curtis_pcoa_results.qza \
# --m-metadata-file ov_metadata.csv \
# --p-custom-axes mmb \
# --o-visualization output/diversity-core/bray-curtis_pcoa_mmb.qzv
