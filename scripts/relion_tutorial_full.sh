#!/bin/bash

set -eu
ln -s /movies movies

mkdir Import
relion_import  --do_movies  --optics_group_name "opticsGroup1" --angpix 1.096 --kV 200 --Cs 2.7 --Q0 0.1 \
  --beamtilt_x 0 --beamtilt_y 0 --i "movies/*.tiff" --odir Import/ --ofile movies.star --continue \

relion_estimate_gain  --i Import/movies.star --o gain.mrc --j $(nproc) --max_frames 50000

mkdir MotionCorr
relion_run_motioncorr --i Import/movies.star --o MotionCorr/ --first_frame_sum 1 \
  --last_frame_sum -1 --use_own  --j $(nproc) --bin_factor 1 --bfactor 150 --dose_per_frame 1.0505 --preexposure 0 \
  --patch_x 1 --patch_y 1 --eer_grouping 32 --gainref gain.mrc --gain_rot 0 --gain_flip 0 \
  --dose_weighting  --only_do_unfinished

mkdir CtfFind
relion_run_ctffind --i MotionCorr/corrected_micrographs.star --o CtfFind/ \
  --Box 512 --ResMin 30 --ResMax 5 --dFMin 5000 --dFMax 50000 --FStep 500 --dAst 100 --ctffind_exe $CTFFIND_EXE \
  --ctfWin -1 --is_ctffind4 --j $(nproc)  --fast_search  --only_do_unfinished

# Particle picking
## Select a subset of the micrographs
mkdir Select
relion_star_handler --i CtfFind/micrographs_ctf.star --o Select/ --split --size_split 10
cp SubsetSelection/_split1. SubsetSelection/_split1.star

## LoG-based auto-picking
mkdir LoGAutoPicking
relion_autopick --i Select/_split1.star --odir LoGAutoPicking/ --j $(nproc) --LoG --LoG_diam_min 150 --LoG_diam_max 180 \
  --LoG_upper_threshold 5

## Particle extraction
mkdir Extract
relion_preprocess --i CtfFind/micrographs_ctf.star --coord_list LoGAutoPicking/autopick.star --part_star Extract/particles.star \
  --pick_star Extract/extractpick.star --part_dir Extract/ --extract --extract_size 256 --float16  --norm --bg_radius 100 \
  --invert_contrast  --only_do_unfinished --j $(nproc)

## 2D class averaging to select good particles
mkdir Class2D
relion_refine --i Extract/particles.star --o Class2D/ --ctf --K 50 --tau2_fudge 2 --iter 25 --particle_diameter 200 --zero_mask \
  --center_classes --pool 2 --j $(nproc)

## Selecting good 2D classes for Topaz training
mkdir Select2
relion_class_ranker --opt Class2D/_it025_optimiser.star --o Select2/ --auto_select --min_score 0.5

rm movies # remove symlink
