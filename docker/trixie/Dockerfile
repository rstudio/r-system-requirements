FROM debian:13

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl

# Install jq
RUN curl -fsSL -o /usr/local/bin/jq https://github.com/jqlang/jq/releases/download/jq-1.8.1/jq-linux-amd64 && \
    chmod +x /usr/local/bin/jq
