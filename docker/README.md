# Docker Images for FRP (frpc & frps)

This directory contains multi-platform Docker configurations for [FRP](https://github.com/fatedier/frp) client (`frpc`) and server (`frps`) across multiple Linux distribution variants.

## Supported Variants

| Variant | Base Image                            | Package Manager | Architectures                                              |
| ------- | ------------------------------------- | --------------- | ---------------------------------------------------------- |
| alpine  | `ghcr.io/snowdreamtech/alpine:3.24.1` | apk             | 386, amd64, arm/v6, arm/v7, arm64, ppc64le, riscv64, s390x |
| debian  | `ghcr.io/snowdreamtech/debian:13.6.0` | apt-get         | amd64, arm/v7, arm64, ppc64le, riscv64, s390x              |
| rocky   | `ghcr.io/snowdreamtech/rocky:10.2.0`  | dnf             | amd64, arm64, ppc64le, s390x                               |

## Directory Structure

```text
docker/
├── alpine/
│   ├── CHANGELOG.md
│   ├── Dockerfile.frpc
│   ├── Dockerfile.frps
│   └── entrypoint.d/
│       ├── 20-frpc-start.sh
│       └── 20-frps-start.sh
├── debian/
│   ├── CHANGELOG.md
│   ├── Dockerfile.frpc
│   ├── Dockerfile.frps
│   └── entrypoint.d/
│       ├── 20-frpc-start.sh
│       └── 20-frps-start.sh
└── rocky/
    ├── CHANGELOG.md
    ├── Dockerfile.frpc
    ├── Dockerfile.frps
    └── entrypoint.d/
        ├── 20-frpc-start.sh
        └── 20-frps-start.sh
```

## Features

- **Dual Flavors**: Dedicated images for client (`frpc`) and server (`frps`).
- **Web Dashboard Integration**: Pre-compiled with full web administration UI embedded.
- **Multi-Architecture Support**: Built for `amd64`, `arm64`, `arm/v7`, `riscv64`, `ppc64le`, `s390x`, `386`.
- **Modular Entrypoint**: Extensible initialization scripts via `/usr/local/bin/entrypoint.d/`.
- **Security Hardened**: Signed with Cosign keyless OIDC, SBOM attestations generated, vulnerability scanned with Trivy.

## Usage

### Running FRPS (Server)

```bash
docker run -d \
  --name frps \
  --restart always \
  --network host \
  -v /path/to/frps.toml:/etc/frp/frps.toml \
  snowdreamtech/frps:latest
```

### Running FRPC (Client)

```bash
docker run -d \
  --name frpc \
  --restart always \
  --network host \
  -v /path/to/frpc.toml:/etc/frp/frpc.toml \
  snowdreamtech/frpc:latest
```

## Building Locally

```bash
# Build Alpine frpc
docker build -f docker/alpine/Dockerfile.frpc -t frpc:alpine ./docker/alpine/

# Build Alpine frps
docker build -f docker/alpine/Dockerfile.frps -t frps:alpine ./docker/alpine/

# Build Debian frpc
docker build -f docker/debian/Dockerfile.frpc -t frpc:debian ./docker/debian/

# Build Debian frps
docker build -f docker/debian/Dockerfile.frps -t frps:debian ./docker/debian/
```
