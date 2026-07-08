FROM registry.access.redhat.com/ubi10/ubi

RUN dnf upgrade -y -q && \
    dnf install -y glibc-langpack-en subscription-manager dnf-plugins-core

# Install jq
ARG JQ_VER=1.8.0
RUN ARCH=$([ "$(arch)" = "aarch64" ] && echo "arm64" || echo "amd64") && \
    curl -fsSL -o /usr/local/bin/jq "https://github.com/jqlang/jq/releases/download/jq-${JQ_VER}/jq-linux-${ARCH}" && \
    chmod +x /usr/local/bin/jq
