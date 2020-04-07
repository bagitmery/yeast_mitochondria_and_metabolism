#!/usr/bin/env python

# mitograph_extended_analysis_v11.py
# last update: October 11, 2017
# This script processes an input directory containing output from MitoGraph2.0.
# It finds three-dimensional surface reconstructions--files ending in _surface.vtk,
# extracts vtk polydata, and converts to a triangle mesh via vtkTriangleFilter.
# It then applies vtkPolyDataConnectivityFilter, extracts the number of distinct regions,
# and constructs separate connectivity output filters for each individual mitochondrion.
# For each, it calculates surface area, volume, normalized shape index (NSI),  
# sphericity, and length. It saves these outputs to a .csv file including input file name and a unique
# cell index.
# It also calculates whole-cell averages of volume, surface area, NSI, and sphericity,
# as well as averages weighted by mitochondrion volume.
# These are saved in a separate .csv file, coded by input file name, unique cell index,
# and individual mitochondrion number.
# As of right now, due to paraview import issues (all dependent upon the length measurement),
# this runs on pvpython: /Applications/ParaView.app/Contents/bin/pvpython
# Calculations include a volume threshold for defining mitochondria in opposition to background
# noise, which is occasionally segmented as a small intracellular object.
# This variable is minvol. This version also includes a volume maximum, to assist in ignoring
# data in which the background is segmented, no longer in use. This variable is maxvol.
# This adds a compactedness measure for mitochondria.
# The script takes five additional arguments--a prefix for generating unique cell IDs
# across experiments (intended to be YYMMDD; e.g., cell 25 of stage position 7 from 01/15/16
# codes as 2016011507025), a string denoting the genotype (or ease of combinatorial work
# downstream), a specification of the length of time points (in minutes), 
# a number denoting the time (in hours) of glucose withdrawal,
# and a specification of the time (in hours) of glucose return, if applicable (measured
# from the beginning of the time course). Times during recovery are expressed as strings prefixed by 'r'.
# Updates for v10: compatibility with the Harvard Odyssey cluster. Namely, paraview and VTK
# are somehow incompatible, such that VTK cannot be loaded as a Python package while paraview
# is installed as a module. 
# This avoids the issue by loading lengths from mitograph output directly, rather than recalculating in paraview.


# Usage: /Applications/ParaView.app/Contents/bin/pvpython [path-to-script]
# [directory] [cellID--like 20160115, YYYYMMDD, or other experiment signifier] [genotype] [min of spacing of time points]
# [hr at glucose withdrawal] [hr at glucose return--'NA' if never] 

# for example:
# /Applications/ParaView.app/Contents/bin/pvpython ~/Desktop/mitograph_extended_analysis/mitograph_extended_analysis_v9.py
# ~/Dropbox/1_15_16 20160115 wildtype 15 1 8


import numpy as np
import vtk, sys, csv, os
import pandas as pd


def mitograph_extended_analysis(directory, cellID, genotype, timespace, switchpoint, refeed):
	if os.path.isdir(directory)!=1 :
		raise Exception ("Error: Input directory is not a valid directory name.")
	# collect a list of all surface reconstructions to be analyzed
	directory_contents = sorted(os.listdir(directory))
	surfaces = []
	for file in directory_contents:
		if file.endswith('surface.vtk'):
			surfaces += [file]

	# specifies the volume threshold used to distinguish mitochondria
	# from cellular debris, hot pixels, and other non-mitochondrial noise
	# units are cubed microns
	# number of objects falling below this threshold in each cell is recorded
	minvol = 0.0250

	# specifies a minimum size to be counted as a potential artifact
	# number of potential artifacts will be used downstream to identify segmentation artifacts on a whole-cell level
	minartifact = 0.045

	# specifies a maximum volume threshold used to distinguish cells
	# from massive, overly-segmented background noise
	maxvol = 10000
	
		
	with open((directory + '/' + os.path.basename(directory) + '_morphological_summaries_by_mitochondrion.txt'), 'wb') as csv_ind:
		ind_csv_writer = csv.writer(csv_ind, csv.excel_tab)
		ind_csv_writer.writerow(['mitograph_extended_analysis_v11.py'])
		ind_csv_writer.writerow(['directory: ' + directory])
		ind_csv_writer.writerow(['minimum volume threshold for mitochondrion: ' + str(minvol)])
		ind_csv_writer.writerow(['maximum volume threshold for cell: ' + str(maxvol)])
		ind_csv_writer.writerow('')
		ind_csv_writer.writerow(['image path', 'cellID', 'genotype', 'time', 'mitochondrion', 'volume (um^3)', 'surface area (um^2)', 'normalized shape index', 'sphericity','compactedness'])
		csv_ind.close()

	with open((directory + '/' + os.path.basename(directory) + '_morphological_summaries_by_whole_cell.txt'), 'wb') as csv_totals:
		total_csv_writer = csv.writer(csv_totals, csv.excel_tab)
		total_csv_writer.writerow(['mitograph_extended_analysis_v11.py'])
		total_csv_writer.writerow(['directory: ' + directory])
		total_csv_writer.writerow(['minimum volume threshold for mitochondrion: ' + str(minvol)])
		total_csv_writer.writerow(['maximum volume threshold for cell: ' + str(maxvol)])
		total_csv_writer.writerow('')
		total_csv_writer.writerow(['image path' , 'cellID', 'genotype', 'time', 'total number of mitochondria' , 'total mitochondrial volume (um^3)' , 'total mitochondrial surface area (um^2)' , 'total normalized shape index' , 'total sphericity', 'total length (um)', 'average volume of mitochondrion (um^3)', 'average surface area of mitochondrion (um^2)', 'average NSI of mitochondrion', 'average sphericity of mitochondrion', 'volume-weighted average surface area of mitochondria (um^2)', 'volume-weighted average NSI of mitochondrion', 'volume-weighted average sphericity of mitochondrion','average compactedness of mitochondrion','volume-weighted average compactedness of mitochondrion', 'average width (um)', 'std width (um)', 'number of endpoints', 'artifacts'])
		csv_totals.close()
	
	for surface in surfaces:
		surface_and_path = directory + '/' + surface
		
		stagename = surface.split('_')[-5]
		stagepos = (stagename[1:]).zfill(2)
		
		# read in contents of .vtk file as polydata
		reader = vtk.vtkPolyDataReader()
		filename = '\'' + surface_and_path + '\'' 
		print('processing file: ' + filename)
		reader.SetFileName(surface_and_path)
		reader.Update()
		
		# determine the time, in minutes
		# times prior to glucose withdrawal are expressed as a function of time until withdrawal
		# e.g., -15 minutes
		# times following glucose return are recorded as strings preceded by r
		# e.g., 'r60' minutes 
		# remember that time here is 1-indexed, making this work counterintuitively
		
		# extract timepoint number from file name 
		timepos = int(filename[-25:-22])
		# if the timepoint, converted into minutes since initiation, 
		# is earlier than glucose return, then calculate time as the difference
		# between the timepoint number and timepoint of glucose withdrawal, times the time interval
		if (((timepos - 1) * timespace) < (refeed * 60)) or refeed == 'NA':
			time = (timepos - 1 - (switchpoint * 60 / timespace)) * timespace
		# if post-refeeding:
		# calculate time as the difference between the timepoint number and timepoint of 
		# glucose refeeding, times the time interval
		else:		
			time = 'r' + str((timepos - 1 - (refeed * 60 / timespace)) * timespace)
		
		
		# convert to triangle mesh
		triangulated = vtk.vtkTriangleFilter()
		triangulated.SetInputConnection(reader.GetOutputPort())
		triangulated.Update()
		
		# test whether the entire cell exceeds the maximum volume ceiling indicating background segmentation
		# if so, proceed directly to the next iteration of the loop on the next surface
		massvol_test = vtk.vtkMassProperties()
		massvol_test.SetInputConnection(triangulated.GetOutputPort())
		massvol_test.Update()
		test_vol = massvol_test.GetVolume()
		if test_vol >= maxvol:
			continue
		
		else:
			# apply connectivity filter; extract number of distinct mitochondria
			connect_filter = vtk.vtkPolyDataConnectivityFilter()
			connect_filter.SetInputConnection(triangulated.GetOutputPort())
			connect_filter.Update()
			mitochondria = connect_filter.GetNumberOfExtractedRegions()
			
			# initialize dictionaries containing connectivity filter output; massproperties;
			# and shape descriptives for individual mitochondria, to be keyed by region number
			mitochonnectdict = {}
			masspropdict = {}
			volumes = {}
			surface_areas = {}
			NSIs = {}
			sphericity = {}
			compacteds = {}
			avgvolume = 0
			avgSA = 0
			avgNSI = 0
			avgsphericity = 0
			avgcompacted = 0
			weighted_avgSA = 0
			weighted_avgNSI = 0
			weighted_avgsphericity = 0
			weighted_avgcompacted = 0
			total_volume = 0
			total_length = 'NA' 
			total_surface_area = 0
			avg_width = 'NA'
			std_width = 'NA'
			endpoints = 'NA'
			
			# initializes a count of segmented objects that meet a size threshold requirement
			# as a noise elimination step to remove non-mitochondrial junk
			threshmitos = 0
					
			# searches for mitograph summary file
			# if it exists: find the network length associated with the cell
			skeleton_and_path =  directory + '/summary.txt'
			if os.path.isfile(skeleton_and_path):
				df = pd.read_csv(skeleton_and_path, skiprows = 8, sep = '\t')
				skelname = '///' + surface[:-12]
				total_length = float(df[df.Image.str.endswith(skelname)]['total_length_(um)'])
				avg_width = float(df[df.Image.str.endswith(skelname)]['avg_width_(um)'])
				std_width = float(df[df.Image.str.endswith(skelname)]['std_width_(um)'])
				endpoints = float(df[df.Image.str.endswith(skelname)]['#Endpoints'])
			
			artifacts = 0
							
			for i in range (mitochondria):
				# cycle through individual mitochondria identified by connectivity filter
				# partition via multiple connectivity filters
				# save filters in a dictionary keyed to each connectivity region
				key = i
				mitochonnectdict[key] = vtk.vtkPolyDataConnectivityFilter()
				mitochonnectdict[key].SetInputConnection(triangulated.GetOutputPort())
				mitochonnectdict[key].Update()
				mitochonnectdict[key].SetExtractionModeToSpecifiedRegions()
				mitochonnectdict[key].AddSpecifiedRegion(i)
				mitochonnectdict[key].Update()
				
				# create a vtkmassproperties class for each separate connectivity partition
				# save each instance in a dictionary keyed to each connectivity region
				masspropdict[key] = vtk.vtkMassProperties()
				masspropdict[key].SetInputConnection(mitochonnectdict[key].GetOutputPort())
				masspropdict[key].Update()
				
				# calculate the volume of the mitochondrion
				testvol = masspropdict[key].GetVolume()
				
				# if it falls below the artifact threshold: record as an artifact
				if testvol <= minartifact:
					artifacts += 1

				# test whether the volume of the mitochondrion surpasses the threshold size
				# if yes: proceed with morphological analysis and iterate real mitochondrial count
				# if no: break for loop and proceed to next cell			
				if testvol <= minvol:
					continue
					
				else:
					# extract volume, surface area, and normalized shape index from massproperties class
					t = threshmitos
					volumes[t] = masspropdict[key].GetVolume()
					surface_areas[t] = masspropdict[key].GetSurfaceArea()
					NSIs[t] = masspropdict[key].GetNormalizedShapeIndex()
					compacteds[t] = np.power(surface_areas[t],1.5)/float(volumes[t])
					total_volume += volumes[t]
					avgvolume += volumes[t]
					avgcompacted += compacteds[t]
					total_surface_area += surface_areas[t]
					avgSA += surface_areas[t]
					avgNSI += NSIs[t]
			
					# calculate sphericity
					sphericity[t] = (np.power(np.pi , (1.0 / 3.0)) * np.power((6 * volumes[t]) , (2.0 / 3.0))) / float(surface_areas[t])
					avgsphericity += sphericity[t]
	
					# add the product of volume and surface area, normalized shape index, or sphericity
					# to a running calculation of averages of shape parameters weighted by volume
					weighted_avgSA += ( volumes[t] * surface_areas[t] )
					weighted_avgNSI += ( volumes[t] * NSIs[t] )
					weighted_avgsphericity += ( volumes[t] * sphericity[t] )
					weighted_avgcompacted += ( volumes[t] * compacteds[t] )
					
					# add this mitochondrion to the count of confirmed mitochondrial structures
					threshmitos += 1
	
	
			# write measurements of individual mitochondria to a csv file
			with open((directory + '/' + os.path.basename(directory) + '_morphological_summaries_by_mitochondrion.txt'), 'a') as csv_ind:
				ind_csv_writer = csv.writer(csv_ind, csv.excel_tab)
				for j in range(threshmitos):
					ind_csv_writer.writerow([surface[:-12], (cellID + stagepos + filename[-16:-13]), genotype, time, (j + 1), volumes[j], surface_areas[j], NSIs[j], sphericity[j], compacteds[j]])
				csv_ind.close()
						 	 
				
			# perform massproperties calculations for bulk mitochondrial content in cell
			# note that total volume and surface area were calculated previously from thresholded mitochondrial content
			total_massproperties = vtk.vtkMassProperties()
			total_massproperties.SetInputConnection(triangulated.GetOutputPort())
			total_massproperties.Update()
			#total_volume = total_massproperties.GetVolume()
			#total_surface_area = total_massproperties.GetSurfaceArea()
			total_NSI = total_massproperties.GetNormalizedShapeIndex()
			total_sphericity = (np.power(np.pi , (1.0 / 3.0)) * np.power((6 * total_volume), (2.0 / 3.0))) / float(total_surface_area)
						
			# get cell-averaged data
			avgvolume = avgvolume / float(threshmitos)
			avgSA = avgSA / float(threshmitos)
			avgNSI = avgNSI / float(threshmitos)
			avgsphericity = avgsphericity / float(threshmitos)
					
			# get cell-averaged data weighted by mitochondrion volume
			if total_volume>0:
				weighted_avgSA = weighted_avgSA / float(total_volume)
				weighted_avgNSI = weighted_avgNSI / float(total_volume)
				weighted_avgsphericity = weighted_avgsphericity / float(total_volume)
				weighted_avgcompacted = weighted_avgcompacted / float(total_volume)
			else:
				weighted_avgSA = 0
				weighted_avgNSI = 0
				weighted_avgsphericity = 0
				weighted_avgcompacted = 0
			
			
			# write cell-total and cell-averaged output to a second csv file
			with open((directory + '/' + os.path.basename(directory) + '_morphological_summaries_by_whole_cell.txt'), 'a') as csv_totals:
				total_csv_writer = csv.writer(csv_totals, csv.excel_tab)
				total_csv_writer.writerow([surface[:-12] , (cellID + stagepos + filename[-16:-13]), genotype, time, threshmitos , total_volume , total_surface_area , total_NSI , total_sphericity, total_length, avgvolume, avgSA, avgNSI, avgsphericity, weighted_avgSA, weighted_avgNSI, weighted_avgsphericity, avgcompacted, weighted_avgcompacted, avg_width, std_width, endpoints, artifacts])
				csv_totals.close()
			
		
	print('Analysis complete!')
	
def _main():
	if len(sys.argv) != 7:
		raise Exception ('Usage: mitograph_extended_analysis_v11.py <directory>')
	pathtodir = sys.argv[1]
	ID = sys.argv[2]
	genotype = sys.argv[3]
	timespace = int(sys.argv[4])
	switchpoint = int(sys.argv[5])
	refeed = int(sys.argv[6])
	
	mitograph_extended_analysis(pathtodir, ID, genotype, timespace, switchpoint, refeed)


if __name__ == "__main__":
	_main()