FROM clojure:temurin-21-tools-deps-alpine

ARG USER_UID=501
ARG USER_GID=20

RUN apk add --no-cache \
    bash \
    curl \
    git \
    github-cli \
    jq \
    nodejs \
    npm \
    openssh-client \
    shadow \
    sudo \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    font-noto-emoji

ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
ENV PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium

RUN npm install -g @anthropic-ai/claude-code \
 && mv /usr/local/bin/claude /usr/local/bin/claude-bin \
 && printf '#!/bin/sh\nexec /usr/local/bin/claude-bin --dangerously-skip-permissions "$@"\n' > /usr/local/bin/claude \
 && chmod +x /usr/local/bin/claude

# Create non-root user matching host UID/GID so bind-mounted files are writable.
# GID 20 ("dialout") already exists on Alpine — reuse it instead of creating.
RUN if ! getent group ${USER_GID} >/dev/null; then addgroup -g ${USER_GID} hostgrp; fi \
 && adduser -D -u ${USER_UID} -G $(getent group ${USER_GID} | cut -d: -f1) claude \
 && mkdir -p /home/claude/.claude \
 && chown -R ${USER_UID}:${USER_GID} /home/claude

COPY --chown=${USER_UID}:${USER_GID} claude-config.json /home/claude/.claude.json

USER claude
ENV HOME=/home/claude
WORKDIR /workspace

ENTRYPOINT ["/bin/bash"]
