#!/bin/bash
# Import Firestore data from a local directory or GCS bucket
# Usage: ./import_firestore.sh [options]
#   --input <path>      Local directory or gs:// bucket path (required)
#   --collections <list> Comma-separated list of collections (default: all)
#   --emulator          Import to local emulator instead of production

set -e

INPUT_PATH=""
COLLECTIONS=""
TO_EMULATOR=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --input|-i)
            INPUT_PATH="$2"
            shift 2
            ;;
        --collections|-c)
            COLLECTIONS="$2"
            shift 2
            ;;
        --emulator)
            TO_EMULATOR=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$INPUT_PATH" ]; then
    echo "❌ --input <path> is required"
    echo "Usage: ./import_firestore.sh --input <path> [--emulator] [--collections <list>]"
    exit 1
fi

echo "🔥 Firestore Import"
echo "==================="

if [ "$TO_EMULATOR" = true ]; then
    # Import to emulator
    echo "Target: Local Emulator"
    echo "Source: $INPUT_PATH"
    echo ""
    
    # Check if emulator is running
    if ! curl -s http://localhost:8080/ > /dev/null 2>&1; then
        echo "❌ Firestore emulator not running on port 8080"
        echo "   Start emulators first: firebase emulators:start"
        exit 1
    fi
    
    # For emulator, we use the emulators:start --import flag
    # This script provides guidance for already-running emulators
    echo "To import data into the emulator:"
    echo ""
    echo "Option 1: Start emulators with import flag"
    echo "   firebase emulators:start --import=$INPUT_PATH"
    echo ""
    echo "Option 2: Use REST API (if emulator supports it)"
    echo "   curl -X POST 'http://localhost:8080/emulator/v1/projects/PROJECT_ID/databases/(default)/documents:importDocuments'"
    echo ""
    echo "💡 Tip: The easiest approach is to stop emulators and restart with --import"
    
else
    # Import to production
    PROJECT=$(firebase use 2>/dev/null | grep -oP '(?<=Active Project: ).*' || echo "")
    
    if [ -z "$PROJECT" ]; then
        echo "❌ No active project. Run: firebase use <project-id>"
        exit 1
    fi
    
    echo "Target: $PROJECT (PRODUCTION)"
    echo "Source: $INPUT_PATH"
    echo ""
    
    # Strong warning for production import
    echo "⚠️  WARNING: This imports data to PRODUCTION Firestore"
    echo "   This operation can overwrite existing documents!"
    echo ""
    read -p "Type the project ID to confirm: " CONFIRM_PROJECT
    
    if [ "$CONFIRM_PROJECT" != "$PROJECT" ]; then
        echo "❌ Project ID doesn't match. Import cancelled."
        exit 1
    fi
    
    # Validate GCS path for production
    if [[ "$INPUT_PATH" != gs://* ]]; then
        echo "❌ Production import requires a GCS bucket path (gs://bucket-name/path)"
        exit 1
    fi
    
    CMD="gcloud firestore import $INPUT_PATH --project=$PROJECT"
    
    if [ -n "$COLLECTIONS" ]; then
        IFS=',' read -ra COLL_ARRAY <<< "$COLLECTIONS"
        for coll in "${COLL_ARRAY[@]}"; do
            CMD="$CMD --collection-ids=$coll"
        done
    fi
    
    echo "Running: $CMD"
    eval $CMD
    
    echo ""
    echo "✅ Import initiated!"
    echo "   Monitor progress in Cloud Console > Firestore > Import/Export"
fi
