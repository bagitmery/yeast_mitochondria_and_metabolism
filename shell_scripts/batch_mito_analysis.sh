#!/bin/bash
#
#SBATCH -p serial_requeue
#SBATCH -J mitalysis
#SBATCH -n 4
#SBATCH -N 1
#SBATCH -t 0-6:00
#SBATCH --mem=20000
#SBATCH -o mitalysis_%j.out
#SBATCH -e mitalysis_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=lbagamery@gmail.com

module load centos6/0.0.1-fasrc01 python/2.7.6-fasrc01

mkdir -p /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID
cd /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID
rsync -avz ~/$1/ /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID/$1/
rsync -avz ~/mitograph_data_extract_v2.py /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID/

python mitograph_data_extract_v2.py $1 

rsync -avz --update /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID/$1/ ~/$1
cd ~/
rm -rf /n/scratchlfs/murray_lab/$USER/$SLURM_JOBID


# usage: sbatch batch_mito_analysis.sh <parent-directory-containing-stage positions>