FROM alpine:latest

LABEL com.github.containers.toolbox="true" \
      usage="This image is meant to be used with the toolbox or distrobox command" \
      summary="Minetest with extra addons portable" \
      maintainer="rafaelpalomaravalos@gmail.com"

COPY extra-packages /
RUN apk update && \
    apk upgrade && \
    xargs -a /extra-packages apk add --no-cache
RUN rm /extra-packages

COPY dev-packages /
RUN apk update && \
    apk upgrade && \
    xargs -a /dev-packages apk add --no-cache
RUN rm /dev-packages

RUN apk add --no-cache git cmake build-base

RUN mkdir -p /usr/src && cd /usr/src && \
    git clone --depth=1 https://github.com/minetest/irrlicht irrlichtmt --branch 1.9.0mt13 && \
    cmake -S irrlichtmt -B irrlichtmt/Release -DCMAKE_BUILD_TYPE=Release && \
    cmake --build irrlichtmt/Release --target install

RUN cd /usr/src && \
    git clone https://github.com/minetest/minetest --depth 1 --branch 5.8.0 && \
    cmake -S minetest -B minetest/Release -DCMAKE_BUILD_TYPE=Release -DIRRLICHTMT_BUILD_DIR=/usr/src/irrlichtmt/Release && \
    cmake --build minetest/Release && \
    cmake --build minetest/Release --target install

RUN echo "**** compile lua-socket****" && \
  LUA_VER=$(ls /usr/include | grep '^lua[0-9]\.[0-9]$' | sed 's/^lua//') && \
  mkdir -p /tmp/luasocket && \
  LUASOCKET_VER=$(curl -sX GET "https://api.github.com/repos/lunarmodules/luasocket/releases/latest" \
    | jq -r .tag_name) && \
  curl -o /tmp/luasocket.tar.gz \
    -L "https://github.com/lunarmodules/luasocket/archive/${LUASOCKET_VER}.tar.gz" && \
  tar xf /tmp/luasocket.tar.gz -C \
    /tmp/luasocket --strip-components=1 && \
  cd /tmp/luasocket && \
  make PLAT=linux LUAV=${LUA_VER} && \
  make install && \
  echo "**** compile lua-cjson****" && \
  LUA_VER=$(ls /usr/include | grep '^lua[0-9]\.[0-9]$' | sed 's/^lua//') && \
  mkdir -p /tmp/luacjson && \
  LUACJSON_VER=2.1.0 && \
  curl -o /tmp/luacjson.tar.gz \
    -L "https://github.com/mpx/lua-cjson/archive/refs/tags/${LUACJSON_VER}.tar.gz" && \
  tar xf /tmp/luacjson.tar.gz -C \
    /tmp/luacjson --strip-components=1 && \
  cd /tmp/luacjson && \
  make LUA_VERSION=${LUA_VER} LUA_INCLUDE_DIR=/usr/include/lua${LUA_VER} && \
  make install && \
  rm -rf \
    /tmp/*

WORKDIR /usr/local/share/games/minetest/mods
RUN git clone https://github.com/miney-py/mineysocket.git

RUN echo "secure.trusted_mods = mineysocket" >> /etc/minetest.conf
