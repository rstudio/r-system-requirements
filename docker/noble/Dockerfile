FROM ubuntu:noble

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl

# Install jq
RUN curl -fsSL -o /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    chmod +x /usr/local/bin/jq
