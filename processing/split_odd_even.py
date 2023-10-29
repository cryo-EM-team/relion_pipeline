import os
import argparse
import numpy as np
import mrcfile
from tqdm import tqdm


def motion_correct_file(source_path: str, tmp_path: str, gain_path: str, dark_path: str):
    os.system(f"$MOTIONCOR2_EXE -InMrc {source_path} -OutMrc {tmp_path} -Patch 5 5 -Gpu 0 -Gain {gain_path} -Dark {dark_path} -Iter 10 -OutStack 1")


def split_files(source: str, target: str, save_full: bool, gain_path: str, dark_path: str):
    tmp_path = os.path.join(target, "tmp.mrc")
    tmp_stk_path = os.path.join(target, "tmp_Stk.mrc")
    for file in tqdm(os.listdir(source)):
        if ".frames.mrc" in file:
            motion_correct_file(os.path.join(source, file), tmp_path, gain_path, dark_path)
            with mrcfile.open(tmp_stk_path) as mrc_source:
                with mrcfile.new(os.path.join(target, file[:-11] + "_1.mrc")) as mrc_target:
                    mrc_target.set_data(np.mean(mrc_source.data[::2], axis=0))
                with mrcfile.new(os.path.join(target, file[:-11] + "_2.mrc")) as mrc_target:
                    mrc_target.set_data(np.mean(mrc_source.data[1::2], axis=0))
                if save_full:
                    with mrcfile.new(os.path.join(target, file[:-11] + "_f.mrc")) as mrc_target:
                        mrc_target.set_data(np.mean(mrc_source.data, axis=0))
    os.remove(tmp_path)
    os.remove(tmp_stk_path)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="This script splits every mrc file in given directory into 2 files - one with even frames and the "
                    "second with the odd ones, and then averages them"
    )
    parser.add_argument("--source", "-s", type=str, default=None,
                        help="Path to directory with .mrc files to split")
    parser.add_argument("--target", "-t", type=str, default=None,
                        help="Path to directory in which split .mrc files wil be stored")
    parser.add_argument("--save_full", "-f", type=bool, default=True,
                        help="Should fully averaged files be saved")
    parser.add_argument("--dark", "-d", type=str, default=None,
                        help="MRC file that stores the dark reference")
    parser.add_argument("--gain", "-g", type=str, default=None,
                        help="MRC file that stores the gain reference")
    args = parser.parse_args()

    split_files(args.source, args.target, args.save_full, args.gain, args.dark)
