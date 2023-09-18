###################################################
## SUPERCRONIC Stuff
## https://github.com/aptible/supercronic
###################################################
ENV SUPERCRONIC_OPTIONS=""
ONBUILD ARG INSTALL_CRON=0
ONBUILD RUN if [ -n "$INSTALL_CRON" ] && ! (type supercronic > /dev/null 2>&1); then \
     SUPERCRONIC="supercronic-${TARGETOS}-${TARGETARCH}" \
     && SUPERCRONIC_URL="https://github.com/aptible/supercronic/releases/download/v0.2.26/${SUPERCRONIC}" \
     && echo ${SUPERCRONIC_URL} \
     && if [ "$TARGETARCH" = "arm64" ]; then SUPERCRONIC_SHA1SUM=e4801adb518ffedfd930ab3a82db042cb78a0a41; \
        elif [ "$TARGETARCH" = "amd64" ]; then SUPERCRONIC_SHA1SUM=7a79496cf8ad899b99a719355d4db27422396735; \
        else echo "Target arch '${TARGETOS}/${TARGETARCH}' is not supported"; exit 1; fi \
     && curl -fsSLO "${SUPERCRONIC_URL}" \
     && echo "${SUPERCRONIC_SHA1SUM} ${SUPERCRONIC}" | sha1sum -c - \
     && chmod +x "${SUPERCRONIC}" \
     && mv "${SUPERCRONIC}" "/usr/local/bin/${SUPERCRONIC}" \
     && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic; \
  fi