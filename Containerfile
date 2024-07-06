FROM ubuntu:20.04

LABEL com.github.containers.toolbox="true" \
      usage="This image is meant to be used with the toolbox or distrobox command" \
      summary="Minetest with extra addons portable" \
      maintainer="rafaelpalomaravalos@gmail.com"

ARG DEBIAN_FRONTEND=noninteractive

COPY extra-packages /
RUN apt-get update && \
    apt-get upgrade && \
    grep -v '^#' /extra-packages | xargs apt-get install -y
RUN rm /extra-packages

COPY dev-packages /
RUN apt-get update && \
    apt-get upgrade && \
    grep -v '^#' /dev-packages | xargs apt-get install -y
RUN rm /dev-packages

RUN mkdir -p /usr/src && cd /usr/src && \
    git clone --depth=1 https://github.com/minetest/irrlicht irrlichtmt --branch 1.9.0mt13 && \
    cmake -S irrlichtmt -B irrlichtmt/Release -DCMAKE_BUILD_TYPE=Release && \
    cmake --build irrlichtmt/Release --target install

RUN cd /usr/src && \
    git clone https://github.com/minetest/minetest --depth 1 --branch 5.8.0 && \
    cmake -S minetest -B minetest/Release -DCMAKE_BUILD_TYPE=Release -DIRRLICHTMT_BUILD_DIR=/usr/src/irrlichtmt/Release && \
    cmake --build minetest/Release && \
    cmake --build minetest/Release --target install

COPY pip-packages /
RUN pip3 install miney
RUN rm /pip-packages

WORKDIR /usr/local/share/games/minetest/mods
RUN git clone https://github.com/miney-py/mineysocket.git

RUN echo "secure.trusted_mods = mineysocket" >> /etc/minetest.conf
