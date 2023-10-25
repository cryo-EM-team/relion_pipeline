#!/bin/bash

set -eu
ln -s /movies movies

echo "Importing"
mkdir Import
relion_import  --do_movies  --optics_group_name "opticsGroup1" --angpix 0.66 --kV 300 --Cs 2.7 --Q0 0.1 \
  --beamtilt_x 0 --beamtilt_y 0 --i "movies/*.frames.mrc" --odir Import/ --ofile movies.star --continue \
  --pipeline_control Import/

echo "Estimating Gain"
relion_estimate_gain  --i Import/movies.star --o gain.mrc --j $(nproc) --max_frames 50000

echo "MotionCor2 Motion Correction and Splitting on Odd and Even"
mkdir OddEven
python3 /processing/split_odd_even.py -s movies -t OddEven -f True -d movies/dark-amibox05-0.mrc -g gain.mrc

echo "Cutting particles"
mkdir CutOut
python3 /processing/cut_particles.py -s OddEven -t CutOut -c movies/run1_shiny_mp007_data_dotstar.txt -d 128

rm movies # remove symlink