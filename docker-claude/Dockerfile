FROM clojure:temurin-21-tools-deps-alpine

RUN apk add --no-cache \
    bash \
    curl \
    git \
    github-cli \
    jq \
    nodejs \
    npm \
    openssh-client

RUN npm install -g @anthropic-ai/claude-code

COPY claude-config.json /root/.claude.json
RUN mkdir -p /root/.claude

WORKDIR /workspace

ENTRYPOINT ["/bin/bash"]
