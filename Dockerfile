FROM continuumio/miniconda3

RUN apt-get update && apt-get install -y cmake git build-essential mpi-default-bin mpi-default-dev libfftw3-dev libtiff-dev libpng-dev ghostscript libxft-dev && \
    rm -rf /var/lib/apt/lists/*

RUN conda create -y --name topaz topaz pytorch-cuda=11.7 cudatoolkit -c tbepler -c pytorch -c nvidia && \
    conda create -y --name class_ranker python=3.9 pytorch=1.10 numpy=1.20 pytorch-cuda=11.7 cudatoolkit -c tbepler -c pytorch -c nvidia && \
    conda clean -ya

WORKDIR /tmp/relion
RUN git clone https://github.com/3dem/relion.git /tmp/relion && \
    git checkout master && \
    mkdir build && cd build && cmake -DCUDA=ON .. && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/relion

ADD setup /setup
ENV CTFFIND_EXE=/setup/ctffind

WORKDIR /relion
CMD bash /setup/process.sh
