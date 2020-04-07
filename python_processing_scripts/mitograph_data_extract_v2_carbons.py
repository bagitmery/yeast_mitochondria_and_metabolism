#!/usr/bin/env python

# mitograph_data_extract_v2.py
# last update: July 7, 2017
# This script extracts data from the end stages of the mitograph_extended_analysis_vn.py
# and ImageJ batch_extract_volume.txt scripts.
# It outputs one .csv file, with results for individual cells.
# It is executed via specifying a parent directory containing subdirectories associated
# with distinct stage positions, containing their own timepoints and volumetric informations.
# It effectively concatenates data from distinct timepoints and stage positions while
# adding information regarding cell volume and consequent ratiometrics.
# This version has removed the inference of absolute time, as this is now encoded
# within the output of the preceding script, mitograph_extended_analysis_v8.py and later.

# For a future update: change the way directories are organized to become more flexible?

# Usage: python mitograph_data_extract <directory>

#TODO: add support for mitograph-corrected volumetric measurements?

import numpy as np
import sys, csv, os
import pandas as pd


def mitograph_data_extract_carbons(directory):
	if os.path.isdir(directory)!=1 :
		raise Exception ("Error: Input directory is not a valid directory name.")
	# collect a list of all mitochondrial summary files
	directory_contents = sorted(os.listdir(directory))
	stages = []
	basename = os.path.split(directory)[-1]
	
	# check through the parent directory for directories for stage positions
	for file in directory_contents:
		if (os.path.isdir(directory + '/' + file)) and (file[0] == 's'):
			stages += [file]

	with open((directory + '/' + basename + '_unique_cell_data.txt'), 'w') as csv_cells:
		cell_csv_writer = csv.writer(csv_cells, csv.excel_tab)
		cell_csv_writer.writerow(['mitograph_data_extract_v2.py'])
		cell_csv_writer.writerow(['directory: ' + directory])
		cell_csv_writer.writerow('')
		cell_csv_writer.writerow('')
		cell_csv_writer.writerow(['image path' , 'cellID', 'genotype', 'total number of mitochondria' , 'total mitochondrial volume (um^3)' , 'total mitochondrial surface area (um^2)' , 'total normalized shape index' , 'total sphericity', 'total length (um)', 'average volume of mitochondrion (um^3)', 'average surface area of mitochondrion (um^2)', 'average NSI of mitochondrion', 'average sphericity of mitochondrion', 'volume-weighted average surface area of mitochondria (um^2)', 'volume-weighted average NSI of mitochondrion', 'volume-weighted average sphericity of mitochondrion','average compactedness of mitochondrion','volume-weighted average compactedness of mitochondrion', 'average width (um)', 'std width (um)', 'number of endpoints', 'artifacts', 'cell volume (um^3)', 'mito/cell volume ratio' ])
		csv_cells.close()

	# check through each stage directory for timepoint directories
	# also check for volumetric files
	for stage in stages:
		whole_cells = []
		#ind_mitos = []
		timepoints = []
		cell_volumes = ''
		
		stagedir = directory + '/' + stage
		stage_contents = sorted(os.listdir(stagedir))
		for content in stage_contents:
			if (os.path.isdir(stagedir + '/' + content)) and (content[0] == 't'):
				timepoints += [stagedir + '/' + content]
			if content.endswith('volumes.txt'):
				cell_volumes = stagedir + '/' + content
		for timepoint in timepoints:
			for time_content in sorted(os.listdir(timepoint)):
				if time_content.endswith('whole_cell.txt'):
					whole_cells += [timepoint + '/' + time_content]
				#if time_content.endswith('mitochondrion.txt'):
					#ind_mitos += [timepoint + '/' + time_content]
		stage_df = pd.read_csv(whole_cells[0], delimiter = '\t', skiprows = 5)
		for next_cell in whole_cells[1:]:
			sub_df = pd.read_csv(next_cell, delimiter = '\t', skiprows = 5)
			stage_df = pd.concat([stage_df, sub_df], ignore_index = True)
		if len(cell_volumes) > 0:
			df_volume = pd.read_csv(cell_volumes, delimiter = '\t', skiprows = 2)
						
		basepos = stage_df.iloc[1]['image path'].rfind('_cell')
		basepos2 = df_volume.iloc[1]['roi_name'].rfind('_cell')
		
		df_volume['cell_pos'] = df_volume['roi_name'].astype(str).apply(lambda x: x[basepos2:])
		df_volume.loc[:, 'image_path'] = stage_df.iloc[1]['image path'][:basepos] + df_volume['cell_pos']
		
		
		#print(stage_df.iloc[0]['image path'])
		#print(df_volume.iloc[0]['image_path'])
		df_merged = stage_df.merge(df_volume, left_on = 'image path', right_on = 'image_path', how = 'inner')
		#print('stage_df: ' + str(len(stage_df)))
		#print('volume: ' + str(len(df_volume)))
		#print('merged: ' + str(len(df_merged)))
		del df_merged['roi_name']
		del df_merged['image_path']
		del df_merged['major_ellipse_axis (pixels)']		
		del df_merged['minor_ellipse_axis (pixels)']		
		del df_merged['projected_volume (pixels)']
		del df_merged['cell_pos']
		df_merged.loc[:, 'mito/cell volume ratio'] = df_merged['total mitochondrial volume (um^3)'] / df_merged['projected_volume (microns^3)']
		
		df_merged.to_csv(directory + '/' + basename + '_unique_cell_data.txt', sep = '\t', mode = 'a', header = False, index = False)
		print('Completed stage position: ' + stage)

	
def _main():
	if len(sys.argv) < 1:
		raise Exception ('Usage: mitograph_data_extract_v2_carbons.py <directory> <size_of_time_points')
	pathtodir = sys.argv[1]
	mitograph_data_extract_carbons(pathtodir)


if __name__ == "__main__":
	_main()