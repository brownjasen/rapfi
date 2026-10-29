# ==============================================================================
# Dockerfile for building Rapfi Linux Binaries (Multi-ISA: SSE, AVX2, AVX512)
# ==============================================================================
# Usage:
#   docker build -t rapfi-builder .
#   docker run --rm -v ${PWD}/dist:/dist rapfi-builder cp -r /output/. /dist/
# ==============================================================================

FROM ubuntu:20.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    clang \
    tar \
    gzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY . .

# Build target binaries with static libstdc++ for portability across Linux distributions
RUN mkdir -p /output/bin && \
    # 1. AVX-512 Variant (Modern Intel/AMD CPUs: Zen 4+, Skylake-X+)
    echo "=== Building AVX-512 Variant ===" && \
    cmake -B build-avx512 -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_CXX_COMPILER=clang++ \
        -DUSE_AVX512=ON -DUSE_AVX2=ON -DUSE_SSE=ON -DUSE_BMI2=ON -DENABLE_LTO=ON \
        -DCMAKE_EXE_LINKER_FLAGS="-static-libgcc -static-libstdc++" && \
    cmake --build build-avx512 -j$(nproc) && \
    cp build-avx512/rapfi /output/bin/rapfi-linux-x64-avx512 && \
    \
    # 2. AVX2 Variant (Standard modern x86-64 CPUs: Haswell+, Zen 1~3)
    echo "=== Building AVX2 Variant ===" && \
    cmake -B build-avx2 -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_CXX_COMPILER=clang++ \
        -DUSE_AVX2=ON -DUSE_SSE=ON -DENABLE_LTO=ON \
        -DCMAKE_EXE_LINKER_FLAGS="-static-libgcc -static-libstdc++" && \
    cmake --build build-avx2 -j$(nproc) && \
    cp build-avx2/rapfi /output/bin/rapfi-linux-x64-avx2 && \
    \
    # 3. SSE Variant (Compatibility fallback for older CPUs / VPS)
    echo "=== Building SSE Variant ===" && \
    cmake -B build-sse -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_CXX_COMPILER=clang++ \
        -DUSE_SSE=ON -DENABLE_LTO=ON \
        -DCMAKE_EXE_LINKER_FLAGS="-static-libgcc -static-libstdc++" && \
    cmake --build build-sse -j$(nproc) && \
    cp build-sse/rapfi /output/bin/rapfi-linux-x64-sse && \
    \
    # Default binary symlink
    ln -s rapfi-linux-x64-avx2 /output/bin/rapfi

# Package into tar.gz archives like GitHub Releases
WORKDIR /output
RUN tar -czvf /output/rapfi-linux-x64-avx512.tar.gz -C /output/bin rapfi-linux-x64-avx512 && \
    tar -czvf /output/rapfi-linux-x64-avx2.tar.gz -C /output/bin rapfi-linux-x64-avx2 && \
    tar -czvf /output/rapfi-linux-x64-sse.tar.gz -C /output/bin rapfi-linux-x64-sse && \
    tar -czvf /output/rapfi-linux-x64-all.tar.gz -C /output bin

CMD ["cp", "-a", "/output/.", "/dist/"]
