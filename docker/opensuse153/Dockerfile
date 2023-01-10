FROM opensuse/leap:15.3

# Use mirrorcache to mitigate openSUSE mirror flakiness
RUN sed -i 's|http://download.opensuse.org|https://mirrorcache.opensuse.org|g' /etc/zypp/repos.d/*.repo && \
    zypper --quiet --non-interactive update && \
    zypper --non-interactive install \
    curl && \
    zypper clean --all

# Install jq
RUN curl -fsSL -o /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    chmod +x /usr/local/bin/jq
