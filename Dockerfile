FROM continuumio/miniconda3

ARG CTFFIND_URL=https://grigoriefflab.umassmed.edu/system/tdf?path=ctffind-4.1.14-linux64.tar.gz&file=1&type=node&id=26

RUN apt-get update && apt-get install -y wget cmake git build-essential mpi-default-bin mpi-default-dev libfftw3-dev libtiff-dev libpng-dev ghostscript libxft-dev
RUN git clone https://github.com/3dem/relion.git /tmp/relion
WORKDIR /tmp/relion
RUN git checkout master
RUN mkdir build && cd build && cmake ..
RUN cd build && make -j$(nproc) && make install

RUN mkdir /setup

RUN wget -O /tmp/ctffind.gz $CTFFIND_URL && mkdir /tmp/ctffind && tar xf /tmp/ctffind.gz -C /tmp/ctffind && mv /tmp/ctffind/bin/ctffind /setup/
ENV CTFFIND_EXE=/setup/ctffind

RUN conda install topaz -c tbepler -c pytorch
RUN git clone https://github.com/tbepler/topaz.git /tmp/topaz && mv /tmp/topaz/relion_run_topaz/*.py /setup/
ENV RELION_PYTHON_EXECUTABLE=/opt/conda/bin/python
ENV RELION_TOPAZ_EXECUTABLE=/opt/conda/bin/topaz

WORKDIR /relion
CMD bash /setup/process.sh
