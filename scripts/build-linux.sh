#!/usr/bin/env bash
set -e

# ==============================================================================
# Script to build and package Rapfi multi-ISA binaries on Linux / WSL
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

DIST_DIR="$SCRIPT_DIR/dist"
mkdir -p "$DIST_DIR/bin"

BUILD_TYPE="Release"
COMPILER_FLAGS="-static-libgcc -static-libstdc++"

echo "=========================================================="
echo " Building Rapfi for Linux (x86_64 Multi-ISA)"
echo " Output directory: $DIST_DIR"
echo "=========================================================="

# 1. AVX-512
echo ">>> [1/3] Building AVX-512 Variant..."
cmake -B build-avx512 -G Ninja \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DUSE_AVX512=ON -DUSE_AVX2=ON -DUSE_SSE=ON -DUSE_BMI2=ON -DENABLE_LTO=ON \
    -DCMAKE_EXE_LINKER_FLAGS="$COMPILER_FLAGS"
cmake --build build-avx512 -j$(nproc)
cp build-avx512/pbrain-rapfi "$DIST_DIR/bin/rapfi-linux-x64-avx512"
cp build-avx512/pbrain-rapfi "$DIST_DIR/bin/pbrain-rapfi-linux-x64-avx512"

# 2. AVX2
echo ">>> [2/3] Building AVX2 Variant..."
cmake -B build-avx2 -G Ninja \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DUSE_AVX2=ON -DUSE_SSE=ON -DENABLE_LTO=ON \
    -DCMAKE_EXE_LINKER_FLAGS="$COMPILER_FLAGS"
cmake --build build-avx2 -j$(nproc)
cp build-avx2/pbrain-rapfi "$DIST_DIR/bin/rapfi-linux-x64-avx2"
cp build-avx2/pbrain-rapfi "$DIST_DIR/bin/pbrain-rapfi-linux-x64-avx2"

# 3. SSE
echo ">>> [3/3] Building SSE Variant..."
cmake -B build-sse -G Ninja \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DUSE_SSE=ON -DENABLE_LTO=ON \
    -DCMAKE_EXE_LINKER_FLAGS="$COMPILER_FLAGS"
cmake --build build-sse -j$(nproc)
cp build-sse/pbrain-rapfi "$DIST_DIR/bin/rapfi-linux-x64-sse"
cp build-sse/pbrain-rapfi "$DIST_DIR/bin/pbrain-rapfi-linux-x64-sse"

# Default link
cp "$DIST_DIR/bin/rapfi-linux-x64-avx2" "$DIST_DIR/bin/rapfi"

# Tar packages
echo ">>> Packaging into tar.gz..."
tar -czvf "$DIST_DIR/rapfi-linux-x64-avx512.tar.gz" -C "$DIST_DIR/bin" rapfi-linux-x64-avx512 pbrain-rapfi-linux-x64-avx512
tar -czvf "$DIST_DIR/rapfi-linux-x64-avx2.tar.gz" -C "$DIST_DIR/bin" rapfi-linux-x64-avx2 pbrain-rapfi-linux-x64-avx2
tar -czvf "$DIST_DIR/rapfi-linux-x64-sse.tar.gz" -C "$DIST_DIR/bin" rapfi-linux-x64-sse pbrain-rapfi-linux-x64-sse
tar -czvf "$DIST_DIR/rapfi-linux-x64-all.tar.gz" -C "$DIST_DIR" bin

echo "=========================================================="
echo " Build & Packaging completed successfully!"
echo " Archives located at $DIST_DIR"
echo "=========================================================="
