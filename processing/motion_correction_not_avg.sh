#!/bin/bash

if [ $# -ne 1 ] || [ $# -ne 2 ] || [ $# -ne 3 ] || [ $# -ne 4 ]; then
  echo "use ./motion_correction_not_avg.sh <source file(s)> <dark file> <gain file> <out dir>"
  exit 1
fi

for i in `ls $1` ; do f=$(echo $i | cut -d '/' -f 4); j=$(echo $f | cut -d '.' -f 1);
if [ ! -f $4/Corrected_$j.mrc ]; then
    $MOTIONCOR2_EXE -InMrc $i  -OutMrc $4/Corrected_$j.mrc -Patch 5 5 -Gpu 0 -Gain $3 -Dark $2 -Iter 10 -OutStack 1
fi; done
