FROM debian:12

ARG CTFFIND_URL=https://grigoriefflab.umassmed.edu/system/tdf?path=ctffind-4.1.14-linux64.tar.gz&file=1&type=node&id=26

RUN apt-get update && apt-get install -y wget cmake git build-essential mpi-default-bin mpi-default-dev libfftw3-dev libtiff-dev libpng-dev ghostscript libxft-dev

RUN git clone https://github.com/3dem/relion.git /tmp/relion

WORKDIR /tmp/relion

RUN git checkout master

RUN mkdir build && cd build && cmake ..

RUN cd build && make -j$(nproc) && make install

RUN mkdir /setup

RUN wget -O /tmp/ctffind.gz $CTFFIND_URL && tar xf /tmp/ctffind.gz -C /setup && mv /setup/bin/ctffind /setup/ && rm -rf /setup/bin

ENV CTFFIND_EXE=/setup/ctffind

WORKDIR /relion

CMD bash /setup/process.sh