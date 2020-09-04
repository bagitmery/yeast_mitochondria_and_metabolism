# yeast_mitochondria_and_metabolism

This repository contains mitochondrial morphological data and analytic and processing code, as presented in Bagamery et al. 2020.

## raw/

This directory contains full mitochondrial morphological data for glucose starvation and other nutrient shift experiments. 

Individual _.txt_ files contain all stage positions for the specified condition or genotype from a single experiment.

This directory also contains _.csv_ files cataloging the proportion of recoverer cells from metabolic history experiments.

The _cellcounts/_ subdirectory contains cell count data before and during sudden glucose and nitrogen starvation for protrophic yeast cells.

The _glucose_uptake_rates.csv_ file contains glucose uptake rate information for wild-type and mutant strains growing in synthetic media containing high glucose.

The _microcolony_growth.csv_ file contains growth rate information, before and during glucose starvation, for all analyzed single-cell lineages.

The _oxoplate.csv_ file contains oxygen consumption rate data for yeast grown in varying carbon sources.

The _oxoplate_mutants.csv_ file contains oxygen consumption rate data for wild-type and mutant strains growing in synthetic media containing high glucose.

## jupyter-notebook-files/
These notebooks contain the analysis and rendered figures included in the manuscript and supplement. They are written in both Python 2.7 (for compatibility with the _FlowCytometryTools_ library for flow cytometry data) and Python 3 as noted.

_cell_counts_min-N-C.ipynb_: a Python 3 notebook plotting the cumulative budding events in phototrophic yeast experiencing sudden carbon or nitrogen starvation

_flow_cytometry_hxk2_fitness_analysis.ipynb_: a Python 2.7 notebook calculating and plotting relative fitnesses of wild-type and hxk2 mutant cells from flow cytometry data collected during exponential growth, diauxy, and abrupt glucose starvation

_flow_cytometry_hxt3_2018_01_04_analysis.ipynb_: a Python 2.7 notebook analyzing and plotting the signal retention or degradation of the Hxt3p hexose transporter in wild-type and _snf1_ and _hxk2_ mutant strains during acute starvation, as measured by flow cytometry

_flow_cytometry_pH_analysis.ipynb_: a Python 2.7 notebook plotting cytosolic pH, mitochondrial pH, and mitochondrial potential dynamics in wild-type, _hxk2_, and _snf1_ strains, before and during acute glucose starvation

_flow_cytometry_wild_yeast_fitnesses.ipynb_: a Python 2.7 notebook analyzing relative fitnesses of a panel of natural and laboratory yeasts during exponential growth and following sudden starvation. 

_glucose_uptake_rates_all.ipynb_: a Python 3 notebook comparing rates of glucose uptake among wild-type and mutant yeast strains

_metabolic_memory_analysis.ipynb_: a Python 2.7 notebook analyzing recovery probabilities as a function of time since respiratory growth and calculating switching rates between arrester and recoverer states.

_microcolony_growth_rate_analysis.ipynb_: a Python 3 notebook analyzing the growth rate of single-lineage microcolonies in high glucose and its relationship to post-starvation growth capacity

_mito_analysis.ipynb_: a Python 3 notebook analyzing mitochondrial morphology in a range of environmental fluctuations, carbon source conditions, and mutant strains. Contains analysis and rendering corresponding to all mitochondrial data presented.

_mito_trajectories_2016_01_05.ipynb_: a Python 3 notebook analyzing and plotting mitochondrial morphological dynamics in a sample of the larger mitochondrial dataset, for illustrative and exploratory purposes.

_oxygen_consumption_analysis.ipynb_: a Python 3 notebook analyzing oxygen consumption rates in wild-type and mutant strains growing in the presence of high glucose. See _mito_analysis.ipynb_ for oxygen consumption data collected during growth on alternative carbon sources.

_rate_switching_analysis.ipynb_: a Python 3 notebook analyzing data on cells’ birth arrester/recoverer phenotypes and whether they have undergone phenotypic switches within a given observation window. This code calculates the phenotypic switching rates in both directions from microscopy data collected from cells suddenly starved within a microfluidics setup.

## matlab_scripts/
Cell segmentation and tracking were performed using the MATLAB implementation of the CellStar algorithm (cellstar-algorithm.org). This directory contains scripts for processing these segments prior to mitochondrial volumetric analysis in Python.

_batch_cellstar_segmentation.m_ and _batch_cellstar_segmentation_carbons.m_: scripts for headless, batch cell segmentation of brightfield microscopy data via CellStar. The former script processes MetaMorph microscopy files consisting of multiple stage points and time points; the latter processes single fields as collected when assessing mitochondrial morphology in cells growing exponentially in varying carbon sources.

_cellstar_to_mitograph_ and _cellstar_to_mitograph_carbons.sh_: scripts for batch processing of cell masks and traces for downstream analysis. This script isolates the three-dimensional volume in fluorescence images of individual cell masks from brightfield images for mitochondrial segmentation. It also calculates total cell volume for all cells over time. The former script is designed to process MetaMorph microscopy files with multiple time points; the latter processes single images, used during mitochondrial measurements on varying carbon sources. This code relies on _fit_ellipse.m_ from the MathWorks file exchange for fitting cell masks to ellipses.


## python_processing_scripts/
This code performs processing, analysis, and aggregation steps on mitochondrial morphological data. The final output is a series of tab-delimited text files containing mitochondrial and volumetric information for all cells from an experiment, with individual cells tracked over time where applicable.

_mitograph_extended_analysis_v11.py_ and _mitograph_extended_analysis_v11_carbons.py_: scripts for extracting mitochondrial morphological information from _.vtk_ files (see below). The former script is designed to process multi-stage position time courses and to integrate mitochondrial data with the time relative to a sudden environmental shift; the latter works with standalone images, as in varying carbon source analysis.

_mitograph_data_extract_v2.py_ and _mitograph_data_extract_v2_carbons.py_: scripts for assembling all mitochondrial and volumetric data from an experiment, the output of the scripts above, into a single tab-delimited file. The former script catalogs stage position and temporal information as well; the latter functions on collections of standalone images.

## shell_scripts/
This code is designed to perform all MATLAB segmentation processing, mitochondrial segmentation, mitochondrial morphology calculations, and data aggregation in batch on a high-performance computing cluster, namely Harvard Research Computing’s Odyssey cluster.

_batch_cellstar.sh_: shell script for moving data to and from the cluster and performing batch CellStar segmentation in MATLAB headlessly

_batch_cellstar_carbons.sh_: shell script similar to above, but without organizing and recording temporal and stage position information within output files; designed for standalone images

_batch_cellstar-mitograph.sh_: shell script for performing all MATLAB processing steps described above, mitochondrial segmentation via MitoGraph2.0 (https://github.com/vianamp/MitoGraph), and morphological calculations in Python on a computing cluster in batch.

_batch_cellstar-mitograph_carbons.sh_: a shell script similar to above, but agnostic to temporal or stage position information; designed to run on standalone images

_batch_mito_analysis.sh_: shell script for performing final data aggregation step from mitochondrial dynamics experiments; runs _mitorgaph_data_extract.py_ above and handles file organization
