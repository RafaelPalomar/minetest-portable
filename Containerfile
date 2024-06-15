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

COPY pip-packages /
RUN pip3 install miney
RUN rm /pip-packages

WORKDIR /usr/share/games/minetest/mods
RUN git clone https://github.com/miney-py/mineysocket.git

RUN echo "secure.trusted_mods = mineysocket" >> /etc/minetest.conf
