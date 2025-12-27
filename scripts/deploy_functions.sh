#!/bin/bash
# Deploy Cloud Functions with options for specific functions
# Usage: ./deploy_functions.sh [options] [function-names...]
#   --dry-run        Preview changes without deploying
#   --force          Skip confirmation prompt
#   --codebase <cb>  Deploy specific codebase only
#   <function-names> Space-separated list of specific functions to deploy

set -e

DRY_RUN=""
FORCE=false
CODEBASE=""
FUNCTIONS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN="--dry-run"
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --codebase)
            CODEBASE="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            FUNCTIONS+=("$1")
            shift
            ;;
    esac
done

# Get current project
PROJECT=$(firebase use 2>/dev/null | grep -oP '(?<=Active Project: ).*' || echo "unknown")

echo "🔥 Firebase Functions Deployment"
echo "================================="
echo "Project: $PROJECT"
echo ""

# Build target string
if [ ${#FUNCTIONS[@]} -gt 0 ]; then
    # Specific functions
    FUNC_LIST=$(IFS=,; echo "${FUNCTIONS[*]}")
    TARGET="functions:$FUNC_LIST"
    echo "Functions: ${FUNCTIONS[*]}"
else
    # All functions
    TARGET="functions"
    echo "Functions: all"
fi

if [ -n "$CODEBASE" ]; then
    echo "Codebase: $CODEBASE"
fi

if [ -n "$DRY_RUN" ]; then
    echo "Mode: DRY RUN"
fi
echo ""

# Confirmation
if [ "$FORCE" = false ] && [ -z "$DRY_RUN" ]; then
    read -p "Deploy functions to $PROJECT? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
fi

# Build command
CMD="firebase deploy --only $TARGET $DRY_RUN"
[ -n "$CODEBASE" ] && CMD="$CMD --codebase $CODEBASE"

echo "Running: $CMD"
echo ""

eval $CMD

echo ""
echo "✅ Functions deployment complete!"
echo ""
echo "📋 Useful commands:"
echo "   • View logs:        firebase functions:log"
echo "   • Specific logs:    firebase functions:log --only <functionName>"
echo "   • Delete function:  firebase functions:delete <functionName>"
echo "   • List secrets:     firebase functions:secrets:list"
