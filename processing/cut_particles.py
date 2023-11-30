import argparse
import mrcfile
import numpy as np
import pandas as pd
from tqdm import tqdm
import os
import multiprocessing
from functools import partial

COLUMN_NAMES = [
    '_rlnCoordinateX',
    '_rlnCoordinateY',
    '_rlnAutopickFigureOfMerit',
    '_rlnClassNumber',
    '_rlnAnglePsi',
    '_rlnImageName',
    '_rlnMicrographName',
    '_rlnOpticsGroup',
    '_rlnCtfMaxResolution',
    '_rlnCtfFigureOfMerit',
    '_rlnDefocusU',
    '_rlnDefocusV',
    '_rlnDefocusAngle',
    '_rlnCtfBfactor',
    '_rlnCtfScalefactor',
    '_rlnPhaseShift',
]

NAME_POST_FIXES = ['1', '2', 'f']


def cut_particles(df: pd.DataFrame,
                  source: str,
                  target: str,
                  diameter: int,
                  start_idx: int = 0,
                  cut_chars_from_name: int = 11):
    files = df['_rlnMicrographName'].unique()
    odd_pixel = diameter % 2
    for file in tqdm(files):
        file_df = df[df['_rlnMicrographName'] == file]
        micrograph_core_name = file.split('/')[2][:-cut_chars_from_name]
        sub_dir = os.path.join(target, micrograph_core_name)
        for fix in NAME_POST_FIXES:
            micrograph_name = f"{micrograph_core_name}_{fix}.mrc"
            micrograph_path = os.path.join(source, micrograph_name)
            if os.path.exists(micrograph_path):
                with mrcfile.open(micrograph_path) as mrc_source:
                    img = mrc_source.data  # np.flip(mrc_source.data, axis=0)
                    for idx, row in file_df.iterrows():
                        minx = int(row['_rlnCoordinateX'] - diameter // 2)
                        maxx = int(row['_rlnCoordinateX'] + diameter // 2 + odd_pixel)
                        miny = int(row['_rlnCoordinateY'] - diameter // 2)
                        maxy = int(row['_rlnCoordinateY'] + diameter // 2 + odd_pixel)
                        xlimit = mrc_source.data.shape[1]
                        ylimit = mrc_source.data.shape[0]
                        if minx >= 0 and miny >= 0 and maxx < xlimit and maxy < ylimit:
                            cut = img[miny:maxy, minx:maxx]
                            with mrcfile.new(
                                    os.path.join(sub_dir, f'{str(int(idx) + start_idx)}_{fix}.mrc')) as mrc_target:
                                mrc_target.set_data(cut)


def multi_cut(df: pd.DataFrame,
              source: str,
              target: str,
              diameter: int,
              num_processes: float,
              cut_chars_from_name: int = 11):
    chunk_size = int(df.shape[0] / num_processes)
    chunks = [df.iloc[df.index[i:i + chunk_size]] for i in range(0, df.shape[0], chunk_size)]
    pool = multiprocessing.Pool(processes=num_processes)
    pool.map(partial(cut_particles, source=source, target=target, diameter=diameter, start_idx=0,
                     cut_chars_from_name=cut_chars_from_name), chunks)


def main(source: str, target: str, coordinates: str, diameter: int, num_processes: int, cut_chars_from_name: int = 11):
    df = pd.read_csv(coordinates, delim_whitespace=True, skiprows=40, header=None)
    df.columns = COLUMN_NAMES
    files = df['_rlnMicrographName'].unique()
    for file in tqdm(files):
        micrograph_core_name = file.split('/')[2][:-cut_chars_from_name]
        sub_dir = os.path.join(target, micrograph_core_name)
        if not os.path.exists(sub_dir):
            os.mkdir(sub_dir)
    if num_processes is None:
        cut_particles(df, source=source, target=target, diameter=diameter, start_idx=0,
                      cut_chars_from_name=cut_chars_from_name)
    elif num_processes < 1:
        raise Exception("Number of processes must be None or above 0")
    else:
        multi_cut(df, source=source, target=target, diameter=diameter, num_processes=num_processes,
                  cut_chars_from_name=cut_chars_from_name)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="This script cuts particles from micrographs"
    )
    parser.add_argument("--source", "-s", type=str, default=None,
                        help="Path to directory with .mrc files to cut out particles from")
    parser.add_argument("--target", "-t", type=str, default=None,
                        help="Path to directory in which .mrc files with cut out particles will be stored")
    parser.add_argument("--coordinates", "-c", type=str, default=None,
                        help=".star file with coordinates of particles")
    parser.add_argument("--diameter", "-d", type=int, default=None,
                        help="Diameter of particle to cut measured in pixels")
    parser.add_argument("--processes", "-p", type=int, default=None,
                        help="Number of processes to use")
    parser.add_argument("--chars", type=int, default=11,
                        help="Number of characters to remove from names of micrographs in file with picked particles")
    args = parser.parse_args()

    main(args.source, args.target, args.coordinates, args.diameter, args.processes, args.chars)
