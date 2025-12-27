#!/bin/bash
# Deploy Firebase project with confirmation and options
# Usage: ./deploy.sh [options]
#   --dry-run        Preview changes without deploying
#   --only <target>  Deploy specific targets (hosting, functions, firestore, storage)
#   --except <target> Deploy all except specified targets
#   --force          Skip confirmation prompt
#   --message <msg>  Add deployment message (for hosting)

set -e

DRY_RUN=""
ONLY_FLAG=""
EXCEPT_FLAG=""
FORCE=false
MESSAGE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN="--dry-run"
            shift
            ;;
        --only)
            ONLY_FLAG="--only $2"
            shift 2
            ;;
        --except)
            EXCEPT_FLAG="--except $2"
            shift 2
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --message|-m)
            MESSAGE="--message \"$2\""
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Get current project
PROJECT=$(firebase use 2>/dev/null | grep -oP '(?<=Active Project: ).*' || echo "unknown")

echo "🔥 Firebase Deployment"
echo "======================"
echo "Project: $PROJECT"
echo ""

# Show what will be deployed
if [ -n "$ONLY_FLAG" ]; then
    echo "Targets: ${ONLY_FLAG#--only }"
elif [ -n "$EXCEPT_FLAG" ]; then
    echo "Targets: all except ${EXCEPT_FLAG#--except }"
else
    echo "Targets: all (hosting, functions, firestore rules, storage rules)"
fi

if [ -n "$DRY_RUN" ]; then
    echo "Mode: DRY RUN (no changes will be made)"
fi
echo ""

# Confirmation
if [ "$FORCE" = false ] && [ -z "$DRY_RUN" ]; then
    read -p "Deploy to $PROJECT? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
fi

# Build and execute command
CMD="firebase deploy $ONLY_FLAG $EXCEPT_FLAG $DRY_RUN $MESSAGE"
echo "Running: $CMD"
echo ""

eval $CMD

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Useful commands:"
echo "   • View logs:     firebase functions:log"
echo "   • Rollback:      firebase hosting:rollback (hosting only)"
echo "   • Open console:  firebase open"
