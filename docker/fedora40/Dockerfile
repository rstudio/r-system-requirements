FROM fedora:40

RUN dnf upgrade -y -q && \
    dnf install -y glibc-langpack-en

# Install jq
RUN curl -fsSL -o /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    chmod +x /usr/local/bin/jq
