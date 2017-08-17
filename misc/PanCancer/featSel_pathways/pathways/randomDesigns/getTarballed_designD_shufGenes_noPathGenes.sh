#!/bin/bash
# run on mac, remotely tarballs results and downloads
# KIRC pathway predictor

DELL=shraddhapai@192.168.81.215

localDir=/Users/shraddhapai/DropBox/netDx/BaderLab/2017_TCGA_KIRC/output/randomD_pseudoPath_noPathGenes_170804
mkdir -p $localDir

indir=/home/shraddhapai/BaderLab/PanCancer_KIRC/output/randomD_pseudoPath_noPathGenes_170804
outF=KIRC_randomD_pseudo_170804.tar.gz
ssh $DELL "cd $indir; tar cvfz ~/${outF} rng*/predictionResults.txt"
scp $DELL:~/${outF} .

indir=/home/shraddhapai/BaderLab/PanCancer_KIRC/output/randomD_pseudoPath_noPathGenes2_170804
outF=KIRC_randomD_pseudo2_170804.tar.gz
ssh $DELL "cd $indir; tar cvfz ~/${outF} rng*/predictionResults.txt"
scp $DELL:~/${outF} .

mv *gz ${localDir}/.
cd $localDir
tar xvfz KIRC_randomD_pseudo_170804.tar.gz
tar xvfz KIRC_randomD_pseudo2_170804.tar.gz
