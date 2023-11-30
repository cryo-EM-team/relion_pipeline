#!/bin/bash

set -eu
ln -s /movies movies
source /root/miniconda3/etc/profile.d/conda.sh

# Preprocessing
## Getting organised
echo "Importing"
mkdir Import
relion_import  --do_movies  --optics_group_name "opticsGroup1" --angpix 0.66 --kV 300 --Cs 1.4 --Q0 0.1 \
  --beamtilt_x 0 --beamtilt_y 0 --i "movies/*.frames.mrc" --odir Import/ --ofile movies.star --continue

relion_estimate_gain  --i Import/movies.star --o gain.mrc --j $(nproc) --max_frames 50000

## Beam-induced motion correction
echo "MotionCorr"
mkdir MotionCorr
relion_run_motioncorr --i Import/movies.star --o MotionCorr/ --first_frame_sum 1 \
  --last_frame_sum -1 --use_own  --j $(nproc) --bin_factor 1 --bfactor 150 --dose_per_frame 1.3947 --preexposure 0 \
  --patch_x 5 --patch_y 5 --eer_grouping 32 --gainref gain.mrc --gain_rot 0 --gain_flip 0 \
  --grouping_for_ps 4 --dose_weighting  --only_do_unfinished --gpu 0

## CTF estimation
echo "CtfFind"
mkdir CtfFind
relion_run_ctffind --i MotionCorr/corrected_micrographs.star --o CtfFind/ \
  --Box 512 --ResMin 30 --ResMax 5 --dFMin 5000 --dFMax 50000 --FStep 500 --dAst 100 --ctffind_exe $CTFFIND_EXE \
  --use_given_ps --ctfWin -1 --is_ctffind4 --j $(nproc)  --fast_search  --only_do_unfinished --gpu 0

# Particle picking
## Select a subset of the micrographs
echo "Select"
mkdir Select
relion_star_handler --i CtfFind/micrographs_ctf.star --o Select/micrographs.star --split --size_split 10

## LoG-based auto-picking
echo "LoGAutoPicking"
mkdir LoGAutoPicking
relion_autopick --i Select/micrographs_split1.star --odir LoGAutoPicking/ --j $(nproc) \
  --LoG --LoG_diam_min 150 --LoG_diam_max 195 --LoG_upper_threshold 5

## Particle extraction
echo "Extract"
mkdir Extract
relion_preprocess --i CtfFind/micrographs_ctf.star --coord_list LoGAutoPicking/autopick.star --part_star Extract/particles.star \
  --pick_star Extract/extractpick.star --part_dir Extract/ --extract --extract_size 256 --float16 --norm --bg_radius 25 \
  --invert_contrast --scale 64

## 2D class averaging to select good particles
echo "Class2D"
mkdir Class2D
relion_refine --i Extract/particles.star --o Class2D/ --ctf --K 50 --tau2_fudge 2 --iter 25 --particle_diameter 195 --zero_mask \
  --center_classes --pool 2 --j $(nproc) --gpu

## Selecting good 2D classes for Topaz training
echo "Select2"
mkdir Select2
relion_class_ranker --opt Class2D/_it025_optimiser.star --o Select2/ --auto_select --min_score 0.25 --python /root/miniconda3/envs/class_ranker/bin/python \
  --do_granularity_features

## Re-training the TOPAZ neural network
echo "TopazAutoPicking"
mkdir TopazAutoPicking
relion_autopick --i Select/micrographs_split1.star --odir TopazAutoPicking/ --particle_diameter 195 --topaz_nr_particles 300 \
  --topaz_train --gpu --topaz_train_parts Select2/particles.star --topaz_exe /setup/topaz.sh

## Pick all micrographs with the re-trained TOPAZ neural network
echo "TopazAutoPickingAll"
mkdir TopazAutoPickingAll
relion_autopick --i CtfFind/micrographs_ctf.star --odir TopazAutoPickingAll/ --particle_diameter 195 --topaz_nr_particles 300 \
  --topaz_extract --gpu --topaz_model TopazAutoPicking/model_epoch10.sav --topaz_exe /setup/topaz.sh

## Particle extraction
echo "Extract2"
mkdir Extract2
relion_preprocess --i CtfFind/micrographs_ctf.star --coord_list TopazAutoPickingAll/autopick.star --part_star Extract2/particles.star \
  --pick_star Extract2/extractpick.star --part_dir Extract2/ --extract --extract_size 256 --float16  --norm --bg_radius 25 \
  --invert_contrast --scale 64 --minimum_pick_fom -3

source /root/miniconda3/etc/profile.d/conda.sh
conda activate particle_cut

echo "MotionCor2 Motion Correction and Splitting on Odd and Even"
mkdir OddEven
python3 /processing/split_odd_even.py -s movies -t OddEven -f True -k False -d movies/dark-amibox05-0.mrc -g gain.mrc

echo "Cutting particles"
mkdir CutOut
python3 /processing/cut_particles.py -s OddEven -t CutOut -c Extract2/particles.star -d 448 -p $(nproc) --chars 11

conda deactivate


rm movies # remove symlink