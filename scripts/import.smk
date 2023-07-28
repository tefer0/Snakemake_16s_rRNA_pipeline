rule all:
	input:
		'demux_summary.qzv'

rule import_data:
	input:
		'manifest.tsv'
	output:
		'demux-paired-end.qza'
	shell:	
		'''qiime tools import \
		--type 'SampleData[PairedEndSequencesWithQuality]' \
		--input-path {input} \
		--input-format PairedEndFastqManifestPhred33V2 \
		--output-path {output} '''


rule demux_summarize:
	input:
		'demux-paired-end.qza'
	output:
		'demux_summary.qzv'
	shell:
		'''qiime demux summarize \
        	--i-data {input} \
        	--o-visualization {output} '''

