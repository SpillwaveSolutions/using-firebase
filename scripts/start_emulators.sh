#!/bin/bash
# Start Firebase emulator suite with data persistence and debugging options
# Usage: ./start_emulators.sh [options]
#   --debug          Enable function debugging (inspect on port 9229)
#   --import <dir>   Import data from directory
#   --no-persist     Don't export data on exit
#   --only <list>    Start only specific emulators (comma-separated)

set -e

DATA_DIR="./emulator-data"
IMPORT_DIR=""
EXPORT_ON_EXIT="--export-on-exit=$DATA_DIR"
DEBUG_FLAG=""
ONLY_FLAG=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            DEBUG_FLAG="--inspect-functions"
            echo "🔍 Debug mode enabled (attach debugger to port 9229)"
            shift
            ;;
        --import)
            IMPORT_DIR="$2"
            shift 2
            ;;
        --no-persist)
            EXPORT_ON_EXIT=""
            shift
            ;;
        --only)
            ONLY_FLAG="--only $2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Set import flag
if [ -n "$IMPORT_DIR" ]; then
    IMPORT_FLAG="--import=$IMPORT_DIR"
elif [ -d "$DATA_DIR" ]; then
    IMPORT_FLAG="--import=$DATA_DIR"
    echo "📂 Importing existing data from $DATA_DIR"
else
    IMPORT_FLAG=""
    echo "📂 No existing data found, starting fresh"
fi

echo "🔥 Starting Firebase Emulators"
echo "==============================="
echo ""

# Build command
CMD="firebase emulators:start"
[ -n "$ONLY_FLAG" ] && CMD="$CMD $ONLY_FLAG"
[ -n "$IMPORT_FLAG" ] && CMD="$CMD $IMPORT_FLAG"
[ -n "$EXPORT_ON_EXIT" ] && CMD="$CMD $EXPORT_ON_EXIT"
[ -n "$DEBUG_FLAG" ] && CMD="$CMD $DEBUG_FLAG"

echo "Running: $CMD"
echo ""

# Execute
exec $CMD
