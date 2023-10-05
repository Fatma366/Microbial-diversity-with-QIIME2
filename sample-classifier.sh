# If you were to construct the heatmap straight from the table.qza, it will produce a heatmap with feature ids instead of OTUs. So we have to manually edit the qza file so that the features can be OTUs 1,2,3….We will have to; convert/export the table.qza as biom  to a tsv, edit to OTUs 1,2,3…., convert to biom file, then import to Qiime again.
# All in all if you don’t mind the features IDs provided by Qiime2 the skip the steps and move directly to ‘qiime sample-classifier classify-samples’

# Exporting a feature table; A FeatureTable[Frequency] artifact will be exported as a BIOM v2.1.0 formatted file. The export tables is a folder containing feature-table.biom
qiime tools export  --input-path table-dada2.qza  --output-path Export_tables

# To convert the table to a .tsv then you can use the biom convert option on the new .biom file.
biom convert -i feature-table.biom -o feature-table.tsv --to-tsv

# In the tsv format, open with text editor and edit by removeing the feature ID and replacing with OTU IDs. After that covert tsv again to biom
biom convert -i feature-table.tsv -o converted_table.biom --to-hdf5

# import the biom file to qiime2
qiime tools import \
  --input-path convertedbacteria_table.biom \
  --type 'FeatureTable[Frequency]' \
  --input-format BIOMV210Format \
  --output-path bacteria-OTU-table.qza

#if you want to collapse the table
qiime taxa collapse \
  --i-table bacteria-OTU-table.qza \
  --i-taxonomy taxonomy-bacteria.qza \
  --p-level 6 \                                         
  --o-collapsed-table collapsed-six-table.qza

# Use the RFC to conduct prediction, play with the different parameters to produce a good heatmaps that gives good predictions. They are 3 stacks of scripts that can help
qiime sample-classifier classify-samples \
  --i-table bacteria-OTU-table.qza \
  --m-metadata-file sample-metadata.tsv \
  --m-metadata-column Counties \
  --p-cv 3 \
  --p-optimize-feature-selection \
  --p-no-parameter-tuning \
  --p-estimator RandomForestClassifier \
  --p-n-estimators 20 \
  --p-random-state 123 \
  --output-dir sample-classifier-bacteria-OTU11-results
  
  qiime sample-classifier classify-samples \
  --i-table bacteria-OTU-table.qza \
  --m-metadata-file sample-metadata.tsv \
  --m-metadata-column Counties \
  --p-cv 3 \
  --p-no-optimize-feature-selection \
  --p-parameter-tuning \
  --p-estimator RandomForestClassifier \
  --p-n-estimators 20 \
  --p-random-state 123 \
  --output-dir sample-classifier-bacteria-OTU12-results

qiime sample-classifier classify-samples \
  --i-table OTU-table.qza \
  --m-metadata-file sample-metadata.tsv \
  --m-metadata-column Counties \
  --p-test-size 0.2 \
  --p-cv 3 \
  --p-optimize-feature-selection \
  --p-parameter-tuning \
  --p-estimator RandomForestClassifier \
  --p-n-estimators 100 \
  --output-dir sample-classifier-OTU-results

# Optional, if you want to check the important features in your sample
qiime metadata tabulate \
  --m-input-file feature_importance.qza \
  --o-visualization feature_importance.qzv
#visualize
qiime metadata tabulate \
  --m-input-file important-bacteria-feature-table-top-20.qza \
  --o-visualization important-bacteria-feature-table-top-20.qzv

qiime feature-table filter-features \
  --i-table bacteria-OTU-table.qza \
  --m-metadata-file feature_importance.qza \
  --o-filtered-table important-bacteria-feature-table.qza

