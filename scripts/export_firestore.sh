#!/bin/bash
# Export Firestore data to a local directory or GCS bucket
# Usage: ./export_firestore.sh [options]
#   --output <path>     Local directory or gs:// bucket path (default: ./firestore-export)
#   --collections <list> Comma-separated list of collections (default: all)
#   --emulator          Export from local emulator instead of production

set -e

OUTPUT_PATH="./firestore-export"
COLLECTIONS=""
FROM_EMULATOR=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --output|-o)
            OUTPUT_PATH="$2"
            shift 2
            ;;
        --collections|-c)
            COLLECTIONS="$2"
            shift 2
            ;;
        --emulator)
            FROM_EMULATOR=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "🔥 Firestore Export"
echo "==================="

if [ "$FROM_EMULATOR" = true ]; then
    # Export from emulator
    echo "Source: Local Emulator"
    echo "Output: $OUTPUT_PATH"
    echo ""
    
    # Check if emulator is running
    if ! curl -s http://localhost:8080/ > /dev/null 2>&1; then
        echo "❌ Firestore emulator not running on port 8080"
        echo "   Start emulators first: firebase emulators:start"
        exit 1
    fi
    
    echo "Exporting emulator data..."
    curl -X POST "http://localhost:8080/emulator/v1/projects/$(firebase use)/databases/(default)/documents:exportDocuments" \
        -H "Content-Type: application/json" \
        -d "{\"outputUriPrefix\": \"$OUTPUT_PATH\"}" || {
        # Fallback: Use emulator export via firebase CLI
        echo "Using firebase emulators:export..."
        firebase emulators:export "$OUTPUT_PATH"
    }
else
    # Export from production
    PROJECT=$(firebase use 2>/dev/null | grep -oP '(?<=Active Project: ).*' || echo "")
    
    if [ -z "$PROJECT" ]; then
        echo "❌ No active project. Run: firebase use <project-id>"
        exit 1
    fi
    
    echo "Source: $PROJECT (PRODUCTION)"
    echo "Output: $OUTPUT_PATH"
    echo ""
    
    # Warning for production export
    echo "⚠️  This exports from PRODUCTION Firestore"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Export cancelled."
        exit 0
    fi
    
    # Build gcloud command
    if [[ "$OUTPUT_PATH" == gs://* ]]; then
        BUCKET="$OUTPUT_PATH"
    else
        echo "❌ Production export requires a GCS bucket (gs://bucket-name/path)"
        echo "   For local exports, use --emulator flag"
        exit 1
    fi
    
    CMD="gcloud firestore export $BUCKET --project=$PROJECT"
    
    if [ -n "$COLLECTIONS" ]; then
        # Convert comma-separated to space-separated for gcloud
        COLL_FLAGS=""
        IFS=',' read -ra COLL_ARRAY <<< "$COLLECTIONS"
        for coll in "${COLL_ARRAY[@]}"; do
            COLL_FLAGS="$COLL_FLAGS --collection-ids=$coll"
        done
        CMD="$CMD $COLL_FLAGS"
    fi
    
    echo "Running: $CMD"
    eval $CMD
fi

echo ""
echo "✅ Export complete!"
echo "   Location: $OUTPUT_PATH"
