#!/bin/bash
#
#SBATCH -p serial_requeue
#SBATCH -J cellstar_segmentation
#SBATCH -c 4
#SBATCH -N 1
#SBATCH -t 0-12:00
#SBATCH --mem=12000
#SBATCH -o cellstar_%j.out
#SBATCH -e cellstar_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=lbagamery@gmail.com

# usage: sbatch batch_cellstar.sh <directory>

module load centos6/0.0.1-fasrc01 matlab/R2014b-fasrc01

mkdir -p /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID
cd /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID
rsync -avz ~/MATLAB/ MATLAB/
rsync -avz ~/$1/ MATLAB/data/
cd ./MATLAB

srun -n 1 -c 4 matlab -nodisplay -nosplash -r "batch_cellstar_segmentation('data/', 0)" 

rsync -avz --update /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID/MATLAB/data/ ~/$1/
cd ~/
rm -rf /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID

