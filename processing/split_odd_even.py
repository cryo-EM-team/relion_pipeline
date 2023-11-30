import os
import argparse
import numpy as np
import mrcfile
from tqdm import tqdm


# def mrc_std(data: np.ndarray) -> np.ndarray:
#     data -= data.min()
#     data = (data / data.max()) * 65535
#     data = data.astype(np.int16)
#     return data


def motion_correct_file(source_path: str, tmp_path: str, gain_path: str, dark_path: str):
    os.system(f"$MOTIONCOR2_EXE -InMrc \"{source_path}\" -OutMrc \"{tmp_path}\" -Patch 5 5 -Gpu 0 -Gain \"{gain_path}\""
              f" -Dark \"{dark_path}\" -Iter 10 -OutStack 1 -OutStar 1")


def split_avg_frames(files_to_avg: list[tuple[str, str]], save_full: bool, save_stack: bool):
    for pair in tqdm(files_to_avg):
        out_path = pair[0]
        out_stk_path = pair[1]
        with mrcfile.open(out_stk_path) as mrc_source:
            with mrcfile.new(out_path[:-6] + "_1.mrc") as mrc_target:
                mrc_target.set_data(np.mean(mrc_source.data[::2], axis=0))
            with mrcfile.new(out_path[:-6] + "_2.mrc") as mrc_target:
                mrc_target.set_data(np.mean(mrc_source.data[1::2], axis=0))
        if not save_full:
            os.remove(out_path)
        if not save_stack:
            os.remove(out_stk_path)


def correct_and_split(source: str, target: str, gain_path: str, dark_path: str, save_full: bool, save_stack: bool):
    files_to_avg = []
    for file in tqdm(os.listdir(source)):
        if ".frames.mrc" in file:
            out_path = os.path.join(target, file[:-11] + "_f.mrc")
            out_stk_path = os.path.join(target, file[:-11] + "_f_Stk.mrc")
            motion_correct_file(os.path.join(source, file), out_path, gain_path, dark_path)
            files_to_avg.append((out_path, out_stk_path))
            if len(files_to_avg) >= 1:
                split_avg_frames(files_to_avg, save_full, save_stack)
                files_to_avg = []
    if len(files_to_avg) > 0:
        split_avg_frames(files_to_avg, save_full, save_stack)


def main(source: str, target: str, gain_path: str, dark_path: str, save_full: bool, save_stack: bool):
    correct_and_split(source, target, gain_path, dark_path, save_full, save_stack)


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
    parser.add_argument("--dark", "-d", type=str, default=None,
                        help="MRC file that stores the dark reference")
    parser.add_argument("--gain", "-g", type=str, default=None,
                        help="MRC file that stores the gain reference")
    parser.add_argument("--save_full", "-f", type=bool, default=True,
                        help="Should fully averaged files be saved")
    parser.add_argument("--save_stack", "-k", type=bool, default=False,
                        help="Should not averaged files be saved")
    args = parser.parse_args()

    main(args.source, args.target, args.gain, args.dark, args.save_full, args.save_stack)
