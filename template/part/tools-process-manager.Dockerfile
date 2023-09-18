###################################################
## Process manager
## https://github.com/just-containers/s6-overlay
## https://skarnet.org/software/s6-rc/
###################################################
ARG S6_OVERLAY_VERSION=3.1.5.0
#RUN curl -L https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz | tar -C / -Jxp && \
#    curl -L https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz | tar -C / -Jxp
RUN mkdir -p /tmp/s6-overlay && cd /tmp/s6-overlay && \
    wget https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz && \
    wget https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz.sha256 && \
    wget https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-$(uname -m).tar.xz && \
    wget https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-$(uname -m).tar.xz.sha256 && \
    sha256sum -c *.sha256 && \
    tar -C / -Jxpf s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf s6-overlay-$(uname -m).tar.xz && \
    rm -rf /tmp/s6-overlay
ENTRYPOINT ["/init"]
COPY --link --chown=root:root ./s6-overlay /etc/s6-overlay
# https://github.com/just-containers/s6-overlay#container-environment
# Stop by sending a termination signal to the supervision tree if any startup commands fail
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS 2
# Avoid loggin to the terminal when image is executed with `docker run -it...`
ENV S6_CMD_USE_TERMINAL 1
# inform init stage 3 that it should attempt to sync filesystems before stopping the container
ENV S6_SYNC_DISKS 1
# 1 will only print warnings and errors, and 0 will only print errors
ENV S6_VERBOSITY 1
# Grace time in ms to non supervised services
ENV S6_KILL_GRACETIME 200
# 0 will send kill signal to command, then to the supervisor (0 will do the reverse)
# FIXME : this option is not compatible with in-out term actions
#ENV S6_CMD_RECEIVE_SIGNALS 1
RUN chmod a+x /etc/s6-overlay/scripts/* \
              /etc/s6-overlay/s6-rc.d/*/run \
              /etc/s6-overlay/s6-rc.d/*/finish