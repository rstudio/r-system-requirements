FROM opensuse/leap:15.2

RUN zypper --quiet --non-interactive update && \
    zypper --non-interactive install \
    curl

# Install jq
RUN curl -fsSL -o /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    chmod +x /usr/local/bin/jq
