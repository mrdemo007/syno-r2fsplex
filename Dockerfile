#Do not use yet under construction / merge

FROM ubuntu:18.04

ARG RAR_VERSION=5.7.3
ARG RAR2FS_VERSION=1.27.2
ARG S6_OVERLAY_VERSION=1.22.0.0
ARG PLEX_INSTALL=https://plex.tv/downloads/latest/1?channel=8&build=linux-ubuntu-x86_64&distro=ubuntu

ENV DEBIAN_FRONTEND="noninteractive" TERM="xterm"
ENV VERSION=latest
ENV CHANGE_DIR_RIGHTS="false"
ENV CHANGE_CONFIG_DIR_OWNERSHIP="true"
ENV HOME="/config"
ENV PLEX_MEDIA_SERVER_HOME="/usr/lib/plexmediaserver"
ENV PLEX_MEDIA_SERVER_INFO_DEVICE=docker
ENV PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS="6"
ENV PLEX_MEDIA_SERVER_USER=plex

# Update and get dependencies
RUN apt-get update
RUN apt-get install -y curl sudo wget xmlstarlet uuid-runtime curl libfuse-dev g++ make fuse

ENTRYPOINT ["/init"]

# Install S6 overlay
RUN curl -SL https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VERSION/s6-overlay-amd64.tar.gz \
    | tar xzC /

# Execute build rar2fs
RUN mkdir -p /tmp/unrar/ \
    && curl -SL https://www.rarlab.com/rar/unrarsrc-$RAR_VERSION.tar.gz \
    | tar -xzC /tmp \
    && make -C /tmp/unrar lib \
    && make -C /tmp/unrar install-lib

RUN mkdir -p /tmp/rar2fs/ \
    && curl -SL https://github.com/hasse69/rar2fs/releases/download/v$RAR2FS_VERSION/rar2fs-$RAR2FS_VERSION.tar.gz \
    | tar --strip-components 1 -xzC /tmp/rar2fs \
    && cd /tmp/rar2fs \
    && ./configure --with-unrar=/tmp/unrar --with-unrar-lib=/usr/lib/ \
    && make
    && cp /tmp/rar2fs/rar2fs /usr/local/bin/rar2fs
#    && /tmp/rar2fs/configure --with-unrar=/tmp/unrar --with-unrar-lib=/usr/lib/ \
#    && make -C /tmp/rar2fs

RUN mkdir -p /tmp/plex/ \
    && curl -o /tmp/plex/plexserver.deb -SL $PLEX_INSTALL \ 
    && dpkg -i /tmp/plexmediaserver.deb && \

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
RUN rm -rf /etc/default/plexmediaserver

EXPOSE 32400/tcp 3005/tcp 8324/tcp 32469/tcp 1900/udp 32410/udp 32412/udp 32413/udp 32414/udp
VOLUME /config /transcode

COPY root/ /

#rar2fs -f -o allow_other -o auto_unmount --seek-length=1 /data /nomorerar
