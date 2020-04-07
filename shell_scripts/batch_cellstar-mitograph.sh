#!/bin/bash
#
#SBATCH -p shared
#SBATCH -J mitograph
#SBATCH -c 4
#SBATCH -N 1
#SBATCH -t 0-6:00
#SBATCH --mem=8000
#SBATCH -o mitograph_%j.out
#SBATCH -e mitograph_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=lbagamery@gmail.com

module load centos6/0.0.1-fasrc01
module load matlab/R2014b-fasrc01
module load gcc/4.8.2-fasrc01 openmpi/1.8.3-fasrc02 VTK/6.2.0-fasrc01
module load python/2.7.6-fasrc01

mkdir -p /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID
cd /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID
rsync -avz ~/MitoGraph-diam/ ./MitoGraph/
rsync -avz ~/MATLAB/ ./MATLAB/
rsync -avz ~/$1/ ./MATLAB/data/
rsync -avz ~/mitograph_extended_analysis_v11.py /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID/

cd ./MATLAB

srun -n 1 -c 4 matlab -nodisplay -nosplash -r "cellstar_to_mitograph('data/', '$7', 0.160); exit"
cd data
echo 'MATLAB segmentation and image partitioning complete. Proceeding to mitograph'

for i in t0[0-9][0-9]; do /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID/MitoGraph/MitoGraph -xy 0.160 -z 0.2 -path $i/; done
echo 'Mitograph 3d-segmentation complete. Proceeding to python summarization'

for i in t0[0-9][0-9]; do python /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID/mitograph_extended_analysis_v11.py $i $2 $3 $4 $5 $6; done
mv extracted_ROI_volumes.txt ~/$1/
echo 'Python summarization complete. Transferring csv files'
for i in t0[0-9][0-9]; do mkdir -p ~/$1/$i; mv $i/*_morphological_summaries_by_whole_cell.txt ~/$1/$i/; mv $i/*_morphological_summaries_by_mitochondrion.txt ~/$1/$i/; mv $i/summary.txt ~/$1/$i/; done
 
cd ~/
rm -rf /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID

# usage: sbatch batch_cellstar-mitograph.sh <1-directory> <2-cellID> <3-genotype>
# <4-timepoint spacing in min> <5-t-glucose withdrawal> <6-t-glucose return> <7-ntimepoints-to-process>