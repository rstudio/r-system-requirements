FROM opensuse/leap:15.6

# Use mirrorcache as openSUSE 15.6 mirrors seem particularly unreliable
RUN sed -i 's|http://download.opensuse.org|https://mirrorcache.opensuse.org|g' /etc/zypp/repos.d/*.repo

RUN zypper --quiet --non-interactive update && \
    zypper --non-interactive install curl

# Install jq
RUN curl -fsSL -o /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.7/jq-linux64 && \
    chmod +x /usr/local/bin/jq
