FROM nvidia/cuda:12.2.2-devel-ubuntu22.04

RUN apt-get update && apt-get install -y cmake git wget build-essential mpi-default-bin mpi-default-dev libfftw3-dev libtiff-dev libpng-dev ghostscript libxft-dev && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="/root/miniconda3/bin:$PATH"
RUN wget \
    https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && mkdir /root/.conda \
    && bash Miniconda3-latest-Linux-x86_64.sh -b \
    && rm -f Miniconda3-latest-Linux-x86_64.sh \
    && conda init

RUN conda create -y --name topaz topaz pytorch==1.7.1 torchvision==0.8.2 torchaudio==0.7.2 cudatoolkit=11.0 fsspec -c tbepler -c pytorch -c nvidia -c conda-forge && \
    conda create -y --name class_ranker python=3.9 pytorch=1.10 numpy=1.20 pytorch-cuda=11.7 cudatoolkit -c tbepler -c pytorch -c nvidia && \
    conda create -y --name particle_cut numpy mrcfile pandas tqdm -c conda-forge && \
    conda clean -ya

WORKDIR /tmp/relion
RUN git clone https://github.com/3dem/relion.git /tmp/relion && \
    git checkout master && \
    mkdir build && cd build && cmake -DCUDA=ON .. && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/relion

ADD setup /setup
ADD processing /processing
ENV CTFFIND_EXE=/setup/ctffind
ENV MOTIONCOR2_EXE=/setup/motioncor

WORKDIR /relion
CMD bash /setup/process.sh
