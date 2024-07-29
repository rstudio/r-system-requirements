FROM centos:7

# Use vault.centos.org since CentOS 7 is EOL and the official mirrors are no longer available
RUN sed -i -e 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/*

RUN yum update -y -q

# Install jq
RUN curl -fsSL -o /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    chmod +x /usr/local/bin/jq
