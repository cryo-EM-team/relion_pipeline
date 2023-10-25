import argparse
import mrcfile
import pandas as pd
from tqdm import tqdm
import os

COLUMN_NAMES = [
    "_rlnVoltage",
    "_rlnDefocusU",
    "_rlnDefocusV",
    "_rlnDefocusAngle",
    "_rlnSphericalAberration",
    "_rlnDetectorPixelSize",
    "_rlnCtfFigureOfMerit",
    "_rlnMagnification",
    "_rlnAmplitudeContrast",
    "_rlnImageName",
    "_rlnCoordinateX",
    "_rlnCoordinateY",
    "_rlnNormCorrection",
    "_rlnMicrographName",
    "_rlnGroupName",
    "_rlnGroupNumber",
    "_rlnOriginX",
    "_rlnOriginY",
    "_rlnAngleRot",
    "_rlnAngleTilt",
    "_rlnAnglePsi",
    "_rlnClassNumber",
    "_rlnLogLikeliContribution",
    "_rlnRandomSubset",
    "_rlnParticleName",
    "_rlnOriginalParticleName",
    "_rlnNrOfSignificantSamples",
    "_rlnNrOfFrames",
    "_rlnMaxValueProbDistribution"
]

NAME_POST_FIXES = ['1', '2', 'f']


def cut_particles(source: str, target: str, coordinates: str, diameter: int):
    df = pd.read_csv(coordinates, delim_whitespace=True, skiprows=33, header=None)
    df.columns = COLUMN_NAMES
    for idx, row in tqdm(df.iterrows()):
        odd_pixel = diameter % 2
        minx = int(row['_rlnCoordinateX'] - diameter // 2)
        maxx = int(row['_rlnCoordinateX'] + diameter // 2 + odd_pixel)
        miny = int(row['_rlnCoordinateY'] - diameter // 2)
        maxy = int(row['_rlnCoordinateY'] + diameter // 2 + odd_pixel)
        micrograph_core_name = row['_rlnMicrographName'].split('/')[1].split('_st_movie.')[0]
        for fix in NAME_POST_FIXES:
            micrograph_name = f"{micrograph_core_name}_{fix}.mrc"
            micrograph_path = os.path.join(source, micrograph_name)
            if os.path.exists(micrograph_path):
                with mrcfile.open(micrograph_path) as mrc_source:
                    xlimit = mrc_source.data.shape[0]
                    ylimit = mrc_source.data.shape[1]
                    if minx > 0 and miny > 0 and maxx < xlimit and maxy < ylimit:
                        cut = mrc_source.data[minx:maxx, miny:maxy]
                        with mrcfile.new(os.path.join(target, f'{str(idx)}_{fix}.mrc')) as mrc_target:
                            mrc_target.set_data(cut)


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
    args = parser.parse_args()

    cut_particles(args.source, args.target, args.coordinates, args.diameter)
