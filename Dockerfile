#Do not use yet under construction / merge

FROM ubuntu:18.04

ARG RAR_VERSION=5.7.3
ARG RAR2FS_VERSION=1.27.2

ENV DEBIAN_FRONTEND="noninteractive" TERM="xterm"

# Install required packages
ADD ["https://github.com/just-containers/s6-overlay/releases/download/v1.17.2.0/s6-overlay-amd64.tar.gz", "/tmp/"]
ADD ["https://www.rarlab.com/rar/unrarsrc-$RAR_VERSION.tar.gz", "/tmp/"]
ADD ["https://github.com/hasse69/rar2fs/releases/download/v$RAR2FS_VERSION/rar2fs-$RAR2FS_VERSION.tar.gz", "/tmp/"]

ENTRYPOINT ["/init"]

# Execute build image
RUN mkdir /tmp/rar2fs
RUN tar xzf "/tmp/s6-overlay-amd64.tar.gz" -C /
RUN tar xzvf "/tmp/unrarsrc-$RAR_VERSION.tar.gz"
RUN tar --strip-components 1 -xzvf "rar2fs-$RAR2FS_VERSION.tar.gz -C /tmp/rar2fs 

# Update and get dependencies
RUN apt-get update
RUN apt-get install -y curl sudo wget xmlstarlet uuid-runtime curl fuse-dev g++ make tar fuse libstdc++ bash

# Execute build rar2fs
WORKDIR /unrar
RUN make lib; make install-lib
WORKDIR /rar2fs
RUN ./configure --with-unrar=../unrar --with-unrar-lib=/usr/lib/
RUN make
COPY /rar2fs/rar2fs /usr/local/bin/rar2fs


# Add user
RUN useradd -U -d /config -s /bin/false plex
RUN usermod -G users plex

# Setup directories
RUN mkdir -p /config /transcode /data

# Cleanup
RUN apt-get -y autoremove
RUN apt-get -y clean
RUN rm -rf /var/lib/apt/lists/* 
RUN rm -rf /tmp/*
RUN rm -rf var/tmp/*

EXPOSE 32400/tcp 3005/tcp 8324/tcp 32469/tcp 1900/udp 32410/udp 32412/udp 32413/udp 32414/udp
VOLUME /config /transcode

ENV VERSION=latest CHANGE_DIR_RIGHTS="false" CHANGE_CONFIG_DIR_OWNERSHIP="true" HOME="/config"

COPY root/ /

#rar2fs -f -o allow_other -o auto_unmount --seek-length=1 /data /nomorerar
