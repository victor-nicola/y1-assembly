#!/bin/bash
set -e

SRC_DIR="$(dirname "$0")"
BUILD_DIR="$SRC_DIR/build"
LIB_DIR="$SRC_DIR/lib"

SDL3_INCLUDE="$LIB_DIR/SDL/include"
SDL3_LIB="$LIB_DIR/SDL/build_sdl"

SDL3TTF_INCLUDE="$LIB_DIR/SDL_ttf/include"
SDL3TTF_LIB="$LIB_DIR/SDL_ttf/build"

mkdir -p "$BUILD_DIR"

gcc \
    "$SRC_DIR"/main.s \
    "$SRC_DIR"/game_loop.s \
    "$SRC_DIR"/menu.s \
    "$SRC_DIR"/text_renderer.s \
    -o "$BUILD_DIR/game" \
    -I"$SDL3_INCLUDE" \
    -I"$SDL3TTF_INCLUDE" \
    -L"$SDL3_LIB" \
    -L"$SDL3TTF_LIB" \
    -lSDL3 \
    -lSDL3_ttf \
    -lm \
    -Wl,-rpath,"$SDL3_LIB:$SDL3TTF_LIB" \
    -no-pie \
    -g

echo "Build complete: $BUILD_DIR/game"
