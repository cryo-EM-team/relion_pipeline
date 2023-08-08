#!/bin/bash

set -eu

ln -s /movies movies

mkdir -p Import/job001
relion_import  --do_movies  --optics_group_name "opticsGroup1" --angpix 1.096 --kV 200 --Cs 2.7 --Q0 0.1 \
  --beamtilt_x 0 --beamtilt_y 0 --i "movies/*.tiff" --odir Import/job001/ --ofile movies.star --continue \
  --pipeline_control Import/job001/

relion_estimate_gain  --i Import/job001/movies.star --o gain_relioncalc2000.mrc --j 8 --max_frames 50000

mkdir -p MotionCorr/job002
relion_run_motioncorr_mpi --i Import/job001/movies.star --o MotionCorr/job002/ --first_frame_sum 1 \
  --last_frame_sum -1 --use_own  --j 2 --bin_factor 1 --bfactor 150 --dose_per_frame 1.0505 --preexposure 0 \
  --patch_x 1 --patch_y 1 --eer_grouping 32 --gainref gain_relioncalc2000.mrc --gain_rot 0 --gain_flip 0 \
  --dose_weighting  --only_do_unfinished   --pipeline_control MotionCorr/job002/

mkdir -p CtfFind/job003
relion_run_ctffind_mpi --i MotionCorr/job002/corrected_micrographs.star --o CtfFind/job003/ \
  --Box 512 --ResMin 30 --ResMax 5 --dFMin 5000 --dFMax 50000 --FStep 500 --dAst 100 --ctffind_exe $CTFFIND_EXE \
  --ctfWin -1 --is_ctffind4  --fast_search  --only_do_unfinished   --pipeline_control CtfFind/job003/