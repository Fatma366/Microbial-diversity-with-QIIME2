# impoting data to qiime2
qiime tools import \
  --type 'SampleData[SequencesWithQuality]' \
  --input-path demux \
  --input-format CasavaOneEightSingleLanePerSampleDirFmt \
  --output-path demux-single-end.qza

# if the data you are importing is not demultiplexed just raw seq with quality
#qiime tools import \
#--type EMPSingleEndSequences \
#--input-path emp-single-end-sequences \
#--output-path emp-single-end-sequences.qza
  
 # demultiplexing, it’s useful to generate a summary of the demultiplexing results. This allows you to determine how many sequences #were obtained per sample
#qiime demux emp-single \
#--i-seqs emp-single-end-sequences.qza \
#--m-barcodes-file sample-metadata.tsv \
#--m-barcodes-column BarcodeSequence \
#--o-per-sample-sequences demultiplexed_sequences.qza

# Change to visualilization so that you can see the imported sequences
 qiime demux summarize \
  --i-data demux-single-end.qza \
  --o-visualization demux.qzv

# Denoising, Trimming and Truncating (Quality Control) using DADA2
qiime dada2 denoise-single \
  --i-demultiplexed-seqs demux-single-end.qza \
  --p-trim-left 20 \
  --p-trunc-len 240 \
  --o-representative-sequences rep-seqs-dada2.qza \
  --o-table table-dada2.qza \
  --o-denoising-stats stats-dada2.qza

qiime metadata tabulate \
  --m-input-file stats-dada2.qza \
  --o-visualization stats-dada2.qzv

# Feature Table and Feature Data Summary
qiime feature-table summarize \
  --i-table table.qza \
  --o-visualization table.qzv \
  --m-sample-metadata-file sample-metadata.tsv
qiime feature-table tabulate-seqs \
  --i-data rep-seqs.qza \
  --o-visualization rep-seqs.qzv

# Phylogenetic Tree Construction
 qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza

# Visualization of the tree
qiime tools export \
--input-path rooted-tree.qza \
--output-path rooted-tree.nwk

# Alpha Rarefraction Plotting
qiime diversity alpha-rarefaction \
  --i-table table.qza \
  --i-phylogeny rooted-tree.qza \
  --p-max-depth 24462 \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization alpha-rarefaction.qzv

# Diversity analysis will be saved in a folder where you can view
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny rooted-tree.qza \
  --i-table table.qza \
  --p-sampling-depth 24467 \
  --m-metadata-file sample-metadata.tsv \
  --output-dir core-metrics-results

# Alpha Diversity Analysis
qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/faith_pd_vector.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization core-metrics-results/faith-pd-group-significance.qzv

qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/evenness_vector.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization core-metrics-results/evenness-group-significance.qzv

# Beta Diversity Analysis
# go to significance.sh for the scripts though some are still below

# Beta Group Significance Analysis (PERMANOVA)
qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file sample-metadata.tsv \
  --m-metadata-column Counties \
  --o-visualization core-metrics-results/unweighted-unifrac-county-significance.qzv \
  --p-pairwise

qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/weighted_unifrac_distance_matrix.qza \
  --m-metadata-file sample-metadata.tsv \
  --m-metadata-column Counties \
  --o-visualization core-metrics-results/weighted-unifrac-county-significance.qzv \
  --p-pairwise
  

# Taxonomic Analysis
# Download the trained naive Bayes classifier for the v4 hypervariable region
wget "https://data.qiime2.org/2021.4/common/gg-13-8-99-515-806-nb-classifier.qza"

qiime feature-classifier classify-sklearn \
  --i-classifier gg-13-8-99-515-806-nb-classifier.qza \
  --i-reads rep-seqs.qza \
  --o-classification taxonomy.qza
 
 wget "https://data.qiime2.org/2021.4/common/silva-138-99-515-806-nb-classifier.qza"
 # if you use silva database 
  qiime feature-classifier classify-sklearn \
  --i-classifier silva-138-99-515-806-nb-classifier.qza \
  --i-reads rep-seqs.qza \
  --o-classification taxonomy.qza

qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --o-visualization taxonomy.qzv
  
  # For fungi use UNITE
  qiime feature-classifier classify-sklearn \
  --i-classifier unite-ver7-99-classifier-01.12.2017.qza \
  --i-reads rep-seqs-dada2.qza\
  --o-classification taxonomy-single-end.qza
  
  qiime taxa barplot \
  --i-table table.qza \
  --i-taxonomy taxonomy.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization taxa-bar-plots.qzv
 
 # Remove unwanted taxa from tables and sequences
  qiime taxa filter-table \
--i-table table-dada2.qza \
--i-taxonomy taxonomy.qza \
--p-include p__ \
--p-exclude mitochondria,chloroplast \
--o-filtered-table table-with-phyla-no-mitochondria-chloroplast.qza

qiime taxa filter-seqs \
--i-sequences rep-seqs-dada2.qza \
--i-taxonomy taxonomy.qza \
--p-include p__ \
--p-exclude mitochondria,chloroplast \
--o-filtered-sequences rep-seqs-with-phyla-no-mitochondria-chloroplast.qza

qiime taxa barplot \
--i-table table-with-phyla-no-mitochondria-chloroplast.qza \
--i-taxonomy taxonomy.qza \
--m-metadata-file sample-metadata.tsv \
--o-visualization taxa-bar-plots.qzv

# fungi.OTU.txt from the sequencing facility was edited a bit to remove unnecessary columns 
# it was edited into fungi-feature-table.tsv then converted into a biom file
biom convert -i fungi-feature-table.tsv -o converteddd_table.biom --to-hdf5

#importing/converting the biom table into qza so as to use in qiime2
qiime tools import \
  --input-path converteddd_table.biom \
  --type 'FeatureTable[Frequency]' \
  --input-format BIOMV210Format \
  --output-path fungi-OTU-table.qza

# importing the fungal OTU table (generated by sequencing facility) into qiime
qiime tools import \
  --type 'FeatureData[Taxonomy]' \
  --input-format HeaderlessTSVTaxonomyFormat \
  --input-path taxonomy.fungi.OTU.txt \
  --output-path taxonomy-fungi.qza

# visualization
qiime metadata tabulate \
 --m-input-file taxonomy-fungi.qza \
 --o-visualization taxonomy-fungi.qzv

# bar plot for fungi
qiime taxa barplot \
 --i-table fungi-OTU-table.qza \
 --i-taxonomy taxonomy-fungi.qza \
 --m-metadata-file sample-metadata.tsv \
 --o-visualization fungi-taxa-barplot.qzv
