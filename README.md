# Base

![Docker Image Version](https://img.shields.io/docker/v/snowdreamtech/base)
![Docker Image Size](https://img.shields.io/docker/image-size/snowdreamtech/base/latest)
![Docker Pulls](https://img.shields.io/docker/pulls/snowdreamtech/base)
![Docker Stars](https://img.shields.io/docker/stars/snowdreamtech/base)

Docker base template providing standardized container foundations with flexible entrypoint systems, multi-architecture support, and consistent configuration patterns across Alpine, Debian, and Rocky Linux distributions.

## Overview

The Docker base template serves as a foundational starting point for building containerized applications. It provides:

- **Standardized Dockerfiles** with OCI annotations and best practices
- **Flexible entrypoint system** supporting custom initialization scripts
- **Consistent environment variable configuration** across all variants
- **Multi-architecture support** for diverse hardware platforms
- **User/group management** with PUID/PGID support for permission handling
- **Three distribution variants**: Alpine (lightweight), Debian (default/widely-compatible), Rocky (enterprise)

## Quick Start

```bash
# Pull and run the default Debian variant
docker pull snowdreamtech/base:debian
docker run -d --name=base -e TZ=Asia/Shanghai snowdreamtech/base:debian

# Or use docker-compose
docker-compose up -d
```

## Distribution Variants

### Debian (Default)

The recommended variant for most use cases, providing wide compatibility and extensive package availability.

```bash
docker run -d \
  --name=base \
  -e TZ=Asia/Shanghai \
  --restart unless-stopped \
  snowdreamtech/base:debian
```

**Supported Architectures**: i386, amd64, arm32v5, arm32v7, arm64, mips64le, ppc64le, s390x

**Base Image**: `snowdreamtech/debian:13.5.0`

### Alpine

Lightweight variant optimized for minimal image size and fast startup times.

```bash
docker run -d \
  --name=base \
  -e TZ=Asia/Shanghai \
  --restart unless-stopped \
  snowdreamtech/base:alpine
```

**Supported Architectures**: i386, amd64, arm32v6, arm32v7, arm64, ppc64le, riscv64, s390x

**Base Image**: `snowdreamtech/alpine:3.24.0`

### Rocky

Enterprise-focused variant based on Rocky Linux, ideal for production environments requiring RHEL compatibility.

```bash
docker run -d \
  --name=base \
  -e TZ=Asia/Shanghai \
  --restart unless-stopped \
  snowdreamtech/base:rocky
```

**Supported Architectures**: i386, amd64, arm32v5, arm32v7, arm64, mips64le, ppc64le, s390x

**Base Image**: `snowdreamtech/rocky:10.2.0`

## Build Instructions

### Single Architecture Build

```bash
# Build Debian variant
docker build -t snowdreamtech/base:debian ./docker/debian/

# Build Alpine variant
docker build -t snowdreamtech/base:alpine ./docker/alpine/

# Build Rocky variant
docker build -t snowdreamtech/base:rocky ./docker/rocky/
```

### Multi-Architecture Build

Build images for multiple architectures using `docker buildx`:

```bash
# Create and use a buildx builder
docker buildx create --use --name build --node build --driver-opt network=host

# Build Debian for multiple architectures
docker buildx build \
  --platform=linux/386,linux/amd64,linux/arm/v5,linux/arm/v7,linux/arm64,linux/mips64le,linux/ppc64le,linux/s390x \
  -t snowdreamtech/base:debian \
  ./docker/debian/ \
  --push

# Build Alpine for multiple architectures
docker buildx build \
  --platform=linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64,linux/ppc64le,linux/riscv64,linux/s390x \
  -t snowdreamtech/base:alpine \
  ./docker/alpine/ \
  --push

# Build Rocky for multiple architectures
docker buildx build \
  --platform=linux/386,linux/amd64,linux/arm/v5,linux/arm/v7,linux/arm64,linux/mips64le,linux/ppc64le,linux/s390x \
  -t snowdreamtech/base:rocky \
  ./docker/rocky/ \
  --push
```

## Environment Variables

All variants support the following environment variables for runtime configuration:

| Variable | Default | Description |
|----------|---------|-------------|
| `KEEPALIVE` | `0` | Keep container running (1=enabled, 0=disabled) |
| `CAP_NET_BIND_SERVICE` | `0` | Enable binding to privileged ports (<1024) |
| `LANG` | `C.UTF-8` | Locale setting for UTF-8 character support |
| `UMASK` | `022` | Default file creation mask |
| `DEBUG` | `false` | Enable debug output in entrypoint scripts |
| `PGID` | `0` | Primary group ID for custom user creation |
| `PUID` | `0` | User ID for custom user creation |
| `USER` | `root` | Username for custom user creation |
| `WORKDIR` | `/root` | Working directory path |
| `TZ` | - | Timezone (e.g., `Asia/Shanghai`, `America/New_York`) |

**Debian-specific**:

| Variable | Default | Description |
|----------|---------|-------------|
| `DEBIAN_FRONTEND` | `noninteractive` | Debian package installation mode |

### Custom User Creation

Create a non-root user with specific UID/GID at build time:

```bash
docker build \
  --build-arg PUID=1000 \
  --build-arg PGID=1000 \
  --build-arg USER=appuser \
  -t snowdreamtech/base:debian-custom \
  ./docker/debian/
```

Or at runtime (requires rebuilding the image):

```bash
docker run -d \
  --name=base \
  -e PUID=1000 \
  -e PGID=1000 \
  -e USER=appuser \
  snowdreamtech/base:debian
```

**Note**: User creation only occurs when `PUID≠0`, `PGID≠0`, and `USER≠root`.

## Docker Compose Examples

### Simple Configuration

```yaml
services:
  base:
    image: snowdreamtech/base:debian
    container_name: base
    environment:
      - TZ=Asia/Shanghai
    restart: unless-stopped
```

### Advanced Configuration

```yaml
services:
  base:
    image: snowdreamtech/base:debian
    container_name: base
    environment:
      - TZ=Asia/Shanghai
      - DEBUG=true
      - KEEPALIVE=1
    volumes:
      - /path/to/data:/data
    restart: unless-stopped
```

## Semantic Versioning Tags

Images follow semantic versioning with the format: `{major}.{minor}.{patch}-{variant}`

Examples:

- `snowdreamtech/base:13.5.0-debian`
- `snowdreamtech/base:3.24.0-alpine`
- `snowdreamtech/base:10.2.0-rocky`

This format allows:

- **Full version pinning**: `13.5.0-debian` (exact version)
- **Variant latest tag**: `latest-debian` (tracks most recent release for Debian)
- **Global latest tag**: `latest` (tracks most recent release, defaults to Debian)

## Architecture Support

Each distribution variant supports multiple CPU architectures for deployment across diverse hardware platforms:

| Variant | Architectures |
|---------|---------------|
| **Debian** | i386, amd64, arm32v5, arm32v7, arm64, mips64le, ppc64le, s390x |
| **Alpine** | i386, amd64, arm32v6, arm32v7, arm64, ppc64le, riscv64, s390x |
| **Rocky** | i386, amd64, arm32v5, arm32v7, arm64, mips64le, ppc64le, s390x |

Docker automatically selects the appropriate architecture for your platform when pulling images.

## Entrypoint System

The base template includes a flexible entrypoint system that executes custom initialization scripts before starting your application.

### How It Works

1. The `docker-entrypoint.sh` script runs at container startup
2. It executes all executable scripts in `/usr/local/bin/entrypoint.d/` in lexical order
3. Each script receives the container's command-line arguments
4. If any script fails, the container stops (fail-fast behavior)

### Adding Custom Initialization

Create custom initialization scripts in your derived Dockerfile:

```dockerfile
FROM snowdreamtech/base:debian

# Add your custom initialization script
COPY my-init.sh /usr/local/bin/entrypoint.d/20-my-init.sh
RUN chmod +x /usr/local/bin/entrypoint.d/20-my-init.sh

# Your application setup
COPY app /app
CMD ["/app/start.sh"]
```

### Debug Mode

Enable debug output to troubleshoot entrypoint execution:

```bash
docker run -e DEBUG=true snowdreamtech/base:debian
```

Output example:

```
→ [ENTRYPOINT] Executing all scripts in /usr/local/bin/entrypoint.d
→ Running /usr/local/bin/entrypoint.d/10-base-init.sh
→ [ENTRYPOINT] Done.
```

## Development

### Prerequisites

- Docker (>= 20.10)
- Docker Buildx plugin

### Building Locally

```bash
# Build all variants
make build

# Build specific variant
docker build -t base:debian ./docker/debian/
docker build -t base:alpine ./docker/alpine/
docker build -t base:rocky ./docker/rocky/
```

### Testing

```bash
# Test default configuration
docker run --rm base:debian id

# Test custom user creation
docker build --build-arg PUID=1000 --build-arg PGID=1000 --build-arg USER=testuser -t base:debian-test ./docker/debian/
docker run --rm base:debian-test id
# Expected: uid=1000(testuser) gid=1000(testuser)

# Test DEBUG mode
docker run --rm -e DEBUG=true base:debian
```

## Reference

1. [使用 buildx 构建多平台 Docker 镜像](https://icloudnative.io/posts/multiarch-docker-with-buildx/)
2. [如何使用 docker buildx 构建跨平台 Go 镜像](https://waynerv.com/posts/building-multi-architecture-images-with-docker-buildx/#buildx-%E7%9A%84%E8%B7%A8%E5%B9%B3%E5%8F%B0%E6%9E%84%E5%BB%BA%E7%AD%96%E7%95%A5)
3. [Building Multi-Arch Images for Arm and x86 with Docker Desktop](https://www.docker.com/blog/multi-arch-images/)
4. [How to Rapidly Build Multi-Architecture Images with Buildx](https://www.docker.com/blog/how-to-rapidly-build-multi-architecture-images-with-buildx/)
5. [Faster Multi-Platform Builds: Dockerfile Cross-Compilation Guide](https://www.docker.com/blog/faster-multi-platform-builds-dockerfile-cross-compilation-guide/)
6. [docker/buildx](https://github.com/docker/buildx)

## Contact (备注：base)

* Email: <sn0wdr1am@qq.com>
* QQ: 3217680847
* QQ群: 949022145
* WeChat/微信群: sn0wdr1am

## License

MIT
