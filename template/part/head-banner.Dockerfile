{% if meta.banner == true -%}
{% if image_type == 'regular' -%}
ARG BUILD_CONTEXT
ARG BUILD_DATE
ARG BUILD_DESC
ARG BUILD_NAME
ARG BUILD_REVISION
ENV IMAGE_NAME="$BUILD_NAME"
LABEL maintainer="https://thecodingmachine.com/"
LABEL org.opencontainers.image.authors="Mistral Oz <m.oz@thecodingmachine.com>, Julien Neuhart, David Négrier <d.negrier@thecodingmachine.com>"
LABEL org.opencontainers.image.description="$BUILD_DESC"
LABEL org.opencontainers.image.documentation="https://hub.docker.com/r/${BUILD_NAME}"
LABEL org.opencontainers.image.licenses="MIT License"
LABEL org.opencontainers.image.revision="$BUILD_REVISION"
LABEL org.opencontainers.image.title="$BUILD_NAME"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/${BUILD_NAME}/tags"
LABEL org.opencontainers.image.vcs-url="https://github.com/thecodingmachine/docker-images-php"
{%- endif -%}
LABEL org.opencontainers.image.created="$BUILD_DATE"
LABEL org.opencontainers.image.source="https://github.com/thecodingmachine/docker-images-php/blob/{{version.global}}/Dockerfile.${BUILD_NAME}"
{%- endif -%}
