#!/bin/bash

set -eu
ln -s /movies movies

mkdir Import
relion_import  --do_movies  --optics_group_name "opticsGroup1" --angpix 1.061 --kV 200 --Cs 2.7 --Q0 0.1 \
  --beamtilt_x 0 --beamtilt_y 0 --i "movies/*.mrc" --odir Import/ --ofile movies.star --continue \
  --pipeline_control Import/

relion_estimate_gain  --i Import/movies.star --o gain.mrc --j $(nproc) --max_frames 50000

mkdir MotionCorr
relion_run_motioncorr_mpi --i Import/movies.star --o MotionCorr/ --first_frame_sum 1 \
  --last_frame_sum -1 --use_own  --j $(nproc) --bin_factor 1 --bfactor 150 --dose_per_frame 1.0505 --preexposure 0 \
  --patch_x 1 --patch_y 1 --eer_grouping 32 --gainref gain.mrc --gain_rot 0 --gain_flip 0 \
  --dose_weighting  --only_do_unfinished   --pipeline_control MotionCorr/

mkdir CtfFind
relion_run_ctffind_mpi --i MotionCorr/corrected_micrographs.star --o CtfFind/ \
  --Box 512 --ResMin 30 --ResMax 5 --dFMin 5000 --dFMax 50000 --FStep 500 --dAst 100 --ctffind_exe $CTFFIND_EXE \
  --ctfWin -1 --is_ctffind4 --j $(nproc)  --fast_search  --only_do_unfinished   --pipeline_control CtfFind/

rm movies # remove symlink