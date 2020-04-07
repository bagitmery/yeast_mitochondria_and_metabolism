#!/bin/bash
#
#SBATCH -p serial_requeue
#SBATCH -J mitograph
#SBATCH -c 1
#SBATCH -N 1
#SBATCH -t 0-2:00
#SBATCH --mem=8000
#SBATCH -o mitograph_%j.out
#SBATCH -e mitograph_%j.err

module load centos6/0.0.1-fasrc01
module load matlab/R2014b-fasrc01
module load gcc/4.8.2-fasrc01 openmpi/1.8.3-fasrc02 VTK/6.2.0-fasrc01
module load python/2.7.6-fasrc01

mkdir -p /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID
cd /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID
rsync -avz ~/MitoGraph-diam/ ./MitoGraph/
rsync -avz ~/MATLAB/ ./MATLAB/
rsync -avz ~/mitograph_extended_analysis_v11_carbons.py /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID/

cd ./MATLAB

for s in $(seq 1 $4); do rsync -avz ~/$1/s$s/ ./data/; srun -n 1 -c 1 matlab -nodisplay -nosplash -r "cellstar_to_mitograph_carbons('data/', $4, 0.160); exit"; 
cd data;
echo 'MATLAB segmentation and image partitioning complete. Proceeding to mitograph';
/n/scratchlfs/murray_lab/$USER/$SLURM_JOBID/MitoGraph/MitoGraph -xy 0.160 -z 0.2 -path t001/;
echo 'Mitograph 3d-segmentation complete. Proceeding to python summarization';
python /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID/mitograph_extended_analysis_v11_carbons.py t001 $2 $3;
echo 'Python summarization complete. Transferring csv files';
rsync -avz extracted_ROI_volumes.txt ~/$1/s$s/;
mkdir -p ~/$1/s$s/t001; 
rsync -avz t001/*_morphological_summaries_by_whole_cell.txt ~/$1/s$s/t001/; 
rsync -avz t001/*_morphological_summaries_by_mitochondrion.txt ~/$1/s$s/t001/;
rsync -avz t001/summary.txt ~/$1/s$s/t001; 
cd /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID/MATLAB;
rm -rf ./data; done

 
cd ~/
rm -rf /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID

# usage: sbatch batch_cellstar-mitograph.sh <1-directory> <2-cellID> <3-genotype>
# <4-number of stage positions>
