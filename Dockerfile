# builddate 20190603
# 18.10 is the latest that i can get working for now!
FROM ubuntu:19.04

ARG RAR_VERSION=5.7.3
ARG RAR2FS_VERSION=1.27.2
#ARG S6_OVERLAY_VERSION=1.22.1.0
ARG PLEX_INSTALL=https://plex.tv/downloads/latest/1?channel=8&build=linux-ubuntu-x86_64&distro=ubuntu
ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm \
    VERSION=20190603 \
    CHANGE_DIR_RIGHTS=false \
    CHANGE_CONFIG_DIR_OWNERSHIP=true \
    HOME=/config \
    PLEX_MEDIA_SERVER_HOME=/usr/lib/plexmediaserver \
    PLEX_MEDIA_SERVER_INFO_DEVICE=docker \
    PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS=6 \
    PLEX_MEDIA_SERVER_USER=plex \
    FUSE_THREAD_STACK=320000

ENTRYPOINT ["/init"]

# Update and get dependencies
RUN apt update \
    && apt upgrade -y \
    && apt install -y avahi-daemon dbus xmlstarlet uuid-runtime curl libfuse-dev g++ make fuse \
# Install S6 overlay
#    && curl -SL https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VERSION/s6-overlay-amd64.tar.gz \
#    | tar xzC / \
# Execute build rar2fs
    && mkdir -p /tmp/unrar/ \
    && curl -SL https://www.rarlab.com/rar/unrarsrc-$RAR_VERSION.tar.gz \
    | tar -xzC /tmp \
    && make -C /tmp/unrar lib \
    && make -C /tmp/unrar install-lib \
    && mkdir -p /tmp/rar2fs/ \
    && curl -SL https://github.com/hasse69/rar2fs/releases/download/v$RAR2FS_VERSION/rar2fs-$RAR2FS_VERSION.tar.gz \
    | tar --strip-components 1 -xzC /tmp/rar2fs \
    && cd /tmp/rar2fs \
    && ./configure --with-unrar=/tmp/unrar --with-unrar-lib=/usr/lib/ \
    && make \
    && cp /tmp/rar2fs/rar2fs /usr/local/bin/rar2fs \
# Add  plex user
    && useradd -U -d /config -s /bin/false plex \
    && usermod -G users plex \
# Install plex
    && mkdir -p /tmp/plex/ \
    && curl -o /tmp/plex/plexserver.deb -SL $PLEX_INSTALL \ 
    && dpkg -i /tmp/plex/plexserver.deb \
# Setup directories
    && mkdir -p /config /transcode /data /nomorerar \
# Cleanup
    && apt -y remove gcc make curl manpages libc-dev-bin libsepol1-dev linux-libc-dev geoip-database multiarch-support \
    && apt -y autoremove \
    && apt -y clean \
    && rm -rf /var/lib/apt/lists/* \ 
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/* \
    && rm -rf /etc/default/plexmediaserver/*
EXPOSE 32400/tcp 3005/tcp 8324/tcp 32469/tcp 1900/udp 32410/udp 32412/udp 32413/udp 32414/udp
CMD /usr/local/bin/rar2fs -f -o ro,allow_other -o auto_unmount --seek-length=1 /nomorerar /data
VOLUME /config /transcode /nomorerar
