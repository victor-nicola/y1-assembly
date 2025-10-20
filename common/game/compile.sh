#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

# --- Determine Absolute Script Directory ---
# 1. Get the directory where the script file ($0) is located.
# 2. Use 'cd' and 'pwd' to resolve this path to its absolute form.
# This ensures all paths are absolute, allowing the script to be run from anywhere.
SRC_DIR="$(dirname "$0")"
SRC_DIR="$(cd "$SRC_DIR" && pwd)"

# Define directory variables based on the absolute script path
BUILD_DIR="$SRC_DIR/build"
LIB_DIR="$SRC_DIR/lib"

# Define library paths using absolute paths
SDL3_INCLUDE="$LIB_DIR/SDL/include"
SDL3_LIB="$LIB_DIR/SDL/build_sdl"

SDL3TTF_INCLUDE="$LIB_DIR/SDL_ttf/include"
SDL3TTF_LIB="$LIB_DIR/SDL_ttf/build"

# Create the build directory if it doesn't exist
mkdir -p "$BUILD_DIR"

echo "Compiling game..."

# Compile the source files and link libraries
gcc \
    "$SRC_DIR"/src/main.s \
    "$SRC_DIR"/src/game_loop.s \
    "$SRC_DIR"/src/menu.s \
    "$SRC_DIR"/src/text_renderer.s \
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

# --- New Step: Generate Portable Runtime Wrapper ---
echo "Generating run.sh wrapper script in project root..."
# The RUN_SCRIPT is placed in the project root (SRC_DIR)
RUN_SCRIPT="$SRC_DIR/run.sh"

# Use a here-doc to create the wrapper script
cat <<EOF > "$RUN_SCRIPT"
#!/bin/bash
# This wrapper changes the directory to 'build' before execution.
# This ensures the game's internal relative asset path (../assets/...) resolves correctly.

# Get the absolute path of this script's directory (the project root, e.g., /path/to/project/)
SCRIPT_DIR="\$(dirname "\$(readlink -f "\$0")")"

# Define the absolute path to the build directory
BUILD_DIR="\$SCRIPT_DIR/build"

# Crucial fix: Change directory to the 'build' folder.
# When the CWD is 'build', the game's internal path '../assets/' correctly resolves
# to the project root's 'assets/' folder.
cd "\$BUILD_DIR"

# Execute the game binary. Since the CWD is now 'build', the binary is "./game".
# The "\$@" passes any command-line arguments to the game
"./game" "\$@"

EOF

# Make the wrapper executable
chmod +x "$RUN_SCRIPT"

echo "Build complete: $BUILD_DIR/game"
echo "To run the game from anywhere, use: $SRC_DIR/run.sh"
