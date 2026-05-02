# WASM build image: Ubuntu 24.04 + amd64 (required by Victron scripts; use on Apple Silicon with compose platform).
# yq is preinstalled so we avoid snap inside Docker.
FROM --platform=linux/amd64 ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -yq && apt-get install -y --no-install-recommends \
    ca-certificates curl sudo lsb-release rsync python3 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://github.com/mikefarah/yq/releases/download/v4.45.4/yq_linux_amd64" -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

RUN useradd -m -s /bin/bash builder \
    && echo 'builder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/builder \
    && chmod 0440 /etc/sudoers.d/builder

USER builder
WORKDIR /work

COPY --chmod=755 docker/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
