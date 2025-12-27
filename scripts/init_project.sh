#!/bin/bash
# Initialize a Firebase project with functions, Firestore, hosting, and emulators
# Usage: ./init_project.sh [project-id]
# If project-id is omitted, prompts for selection

set -e

PROJECT_ID="${1:-}"
FEATURES="firestore,functions,hosting,storage,emulators"

echo "🔥 Firebase Project Initialization"
echo "==================================="

# Check Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Install with: npm install -g firebase-tools"
    exit 1
fi

# Check authentication
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not authenticated. Run: firebase login"
    exit 1
fi

# Initialize with project
if [ -n "$PROJECT_ID" ]; then
    echo "📁 Initializing with project: $PROJECT_ID"
    firebase init $FEATURES --project "$PROJECT_ID"
else
    echo "📁 Initializing Firebase (will prompt for project selection)"
    firebase init $FEATURES
fi

# Post-init recommendations
echo ""
echo "✅ Firebase initialized successfully!"
echo ""
echo "📋 Next steps:"
echo "   1. Review firebase.json configuration"
echo "   2. Set up firestore.rules and storage.rules"
echo "   3. Configure functions/ directory"
echo "   4. Start emulators: firebase emulators:start"
echo ""
echo "📚 Emulator ports (defaults):"
echo "   • Auth:      http://localhost:9099"
echo "   • Functions: http://localhost:5001"
echo "   • Firestore: http://localhost:8080"
echo "   • Storage:   http://localhost:9199"
echo "   • Hosting:   http://localhost:5000"
echo "   • UI:        http://localhost:4000"
