# ############################################################################ #
# NOTES
#
# Make sure to run this on a 64bit platform with a modern CPU!
#
# Make sure to install all dependencies, including static versions of libraries.
#
# Build static rocksdb library
#
# > make clean
# > make static_lib
# > make install-static
#
# Build shared rocksd library
#
# > make clean
# > make shared_lib
# > make install-shared
#
# Do NOT build static and shared libraries in the same invocation of make.
# You MUST call `make clean` inbetween when switching between both builds

# ############################################################################ #
FROM alpine AS builder

ARG VERSION=6.15.5

RUN apk update && apk add --no-cache \
    # Build Dependencies \
    curl \
    binutils \
    make \
    musl-dev \
    linux-headers \
    bash \
    perl \
    g++ \
    # Rocksdb dependencies \
    gflags-dev \
    bzip2-dev \
    bzip2-static \
    lz4-dev \
    lz4-static \
    snappy-dev \
    snappy-static \
    zlib-dev \
    zlib-static \
    zstd-dev \
    zstd-static

RUN curl -sL "https://github.com/facebook/rocksdb/archive/v${VERSION}.tar.gz" -o- | tar xz

WORKDIR /rocksdb-${VERSION}

# Patch Makefile
RUN sed -i -e 's/install -C/install -c/g' Makefile

# Build static library
RUN make static_lib && \
    make install-static && \
    strip --strip-unneeded /usr/local/lib/librocksdb.a

# Build shared library
RUN make clean && \
    make shared_lib && \
    make install-shared

# Install license info
RUN install -Dm644 COPYING /usr/local/share/licenses/rocksdb/COPYING && \
    install -Dm644 LICENSE.Apache /usr/local/share/licenses/rocksdb/LICENSE.Apache

# ############################################################################ #
FROM alpine

RUN apk add --no-cache \
    musl-dev \
    bzip2-dev \
    bzip2-static \
    gflags-dev \
    lz4-dev \
    lz4-static \
    snappy-dev \
    snappy-static \
    zlib-dev \
    zlib-static \
    zstd-dev \
    zstd-static

COPY --from=builder /usr/local/lib/*rocksdb* /usr/local/lib/
COPY --from=builder /usr/local/lib/pkgconfig/rocksdb.pc /usr/local/lib/pkgconfig/
COPY --from=builder /usr/local/include/rocksdb /usr/local/include/rocksdb/
COPY --from=builder /usr/local/share/licenses/rocksdb /usr/local/share/licenses/rocksdb/

