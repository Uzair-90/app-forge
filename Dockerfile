FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    unzip \
    libsqlite3-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Tuist 3.36.0
RUN curl -L \
    https://github.com/tuist/tuist/releases/download/3.36.0/tuist-3.36.0-linux-x86_64.tar.gz \
    -o tuist.tar.gz \
    && tar -xzf tuist.tar.gz \
    && mv tuist /usr/local/bin/ \
    && chmod +x /usr/local/bin/tuist \
    && rm tuist.tar.gz

WORKDIR /workspace
ENTRYPOINT ["tuist"]
CMD ["--help"]
