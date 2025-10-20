#!/bin/bash
# This wrapper changes the directory to 'build' before execution.
# This ensures the game's internal relative asset path (../assets/...) resolves correctly.

# Get the absolute path of this script's directory (the project root, e.g., /path/to/project/)
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Define the absolute path to the build directory
BUILD_DIR="$SCRIPT_DIR/build"

# Crucial fix: Change directory to the 'build' folder.
# When the CWD is 'build', the game's internal path '../assets/' correctly resolves
# to the project root's 'assets/' folder.
cd "$BUILD_DIR"

# Execute the game binary. Since the CWD is now 'build', the binary is "./game".
# The "$@" passes any command-line arguments to the game
"./game" "$@"

