#!/bin/bash
# Manage secrets for Cloud Functions (2nd generation)
# Usage: ./manage_secrets.sh <command> <secret-name> [value]
#   set <name>       Set a secret (prompts for value or reads from stdin)
#   get <name>       Get a secret value
#   list             List all secrets
#   delete <name>    Delete a secret
#   access <name>    Grant function access to a secret

set -e

COMMAND="${1:-}"
SECRET_NAME="${2:-}"

show_usage() {
    echo "Usage: ./manage_secrets.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "   set <name>       Set a secret (prompts for value)"
    echo "   get <name>       Get a secret value"
    echo "   list             List all secrets"
    echo "   delete <name>    Delete a secret"
    echo "   versions <name>  List secret versions"
    echo ""
    echo "Examples:"
    echo "   ./manage_secrets.sh set API_KEY"
    echo "   ./manage_secrets.sh get API_KEY"
    echo "   ./manage_secrets.sh list"
    echo "   echo 'myvalue' | ./manage_secrets.sh set API_KEY"
}

if [ -z "$COMMAND" ]; then
    show_usage
    exit 1
fi

PROJECT=$(firebase use 2>/dev/null | grep -oP '(?<=Active Project: ).*' || echo "")
if [ -z "$PROJECT" ]; then
    echo "❌ No active project. Run: firebase use <project-id>"
    exit 1
fi

echo "🔐 Firebase Secrets Manager"
echo "==========================="
echo "Project: $PROJECT"
echo ""

case $COMMAND in
    set)
        if [ -z "$SECRET_NAME" ]; then
            echo "❌ Secret name required"
            echo "Usage: ./manage_secrets.sh set <secret-name>"
            exit 1
        fi
        
        echo "Setting secret: $SECRET_NAME"
        firebase functions:secrets:set "$SECRET_NAME"
        
        echo ""
        echo "✅ Secret set successfully!"
        echo ""
        echo "📋 To use in a function (TypeScript):"
        echo "   import { defineSecret } from 'firebase-functions/params';"
        echo "   const ${SECRET_NAME,,} = defineSecret('$SECRET_NAME');"
        echo ""
        echo "   export const myFunc = onRequest({ secrets: [${SECRET_NAME,,}] }, (req, res) => {"
        echo "       const value = ${SECRET_NAME,,}.value();"
        echo "   });"
        ;;
        
    get)
        if [ -z "$SECRET_NAME" ]; then
            echo "❌ Secret name required"
            exit 1
        fi
        
        echo "Getting secret: $SECRET_NAME"
        firebase functions:secrets:get "$SECRET_NAME"
        ;;
        
    list)
        echo "Listing secrets..."
        firebase functions:secrets:list
        ;;
        
    delete)
        if [ -z "$SECRET_NAME" ]; then
            echo "❌ Secret name required"
            exit 1
        fi
        
        echo "⚠️  This will permanently delete secret: $SECRET_NAME"
        read -p "Continue? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            firebase functions:secrets:destroy "$SECRET_NAME"
            echo "✅ Secret deleted"
        else
            echo "Cancelled."
        fi
        ;;
        
    versions)
        if [ -z "$SECRET_NAME" ]; then
            echo "❌ Secret name required"
            exit 1
        fi
        
        echo "Listing versions for: $SECRET_NAME"
        gcloud secrets versions list "$SECRET_NAME" --project="$PROJECT"
        ;;
        
    *)
        echo "❌ Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac
