# Firebase CLI Commands Reference

Quick reference for Firebase CLI commands organized by service.

## Contents

- [Authentication](#authentication)
- [Project Management](#project-management)
- [Initialization](#initialization)
- [Deployment](#deployment)
- [Emulators](#emulators)
- [Cloud Functions](#cloud-functions)
- [Firestore](#firestore)
- [Hosting](#hosting)
- [Storage](#storage)

---

## Authentication

```bash
firebase login                      # Interactive browser login
firebase login --no-localhost       # For SSH/headless environments
firebase login:ci                   # Generate CI token
firebase login:add                  # Add additional account
firebase login:list                 # List authorized accounts
firebase login:use <email>          # Switch active account
firebase logout                     # Sign out current account
```

## Project Management

```bash
firebase projects:list              # List all accessible projects
firebase projects:create <id>       # Create new project
firebase use                        # Show active project
firebase use <project-id>           # Switch active project
firebase use --add                  # Add project alias interactively
firebase use <alias>                # Switch to aliased project
firebase open                       # Open project in browser console
firebase open hosting               # Open specific service in console
firebase open functions
firebase open firestore
firebase open auth
```

## Initialization

```bash
firebase init                       # Interactive init (select features)
firebase init <features>            # Init specific features
# Features: firestore, functions, hosting, storage, emulators, database, remoteconfig

# Common combinations
firebase init firestore functions hosting emulators
firebase init hosting               # Static site only
firebase init functions             # Functions only
```

## Deployment

```bash
# Full deployment
firebase deploy                     # Deploy all configured features
firebase deploy --only <targets>    # Deploy specific targets
firebase deploy --except <targets>  # Deploy all except specified

# Target examples
firebase deploy --only hosting
firebase deploy --only functions
firebase deploy --only firestore               # Rules + indexes
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage                 # Storage rules
firebase deploy --only functions:myFunction    # Single function
firebase deploy --only functions:func1,func2  # Multiple functions

# Options
firebase deploy --dry-run           # Preview without deploying
firebase deploy --force             # Skip confirmation prompts
firebase deploy --message "v1.2"    # Add deploy message (hosting)
```

## Emulators

```bash
# Starting emulators
firebase emulators:start                              # Start all configured
firebase emulators:start --only functions,firestore   # Specific emulators
firebase emulators:start --project <id>               # With specific project

# Data persistence
firebase emulators:start --import=./data              # Import saved data
firebase emulators:start --export-on-exit=./data      # Export on shutdown
firebase emulators:start --import=./data --export-on-exit  # Both

# Debugging
firebase emulators:start --inspect-functions          # Enable debugger (port 9229)

# Running tests
firebase emulators:exec "npm test"                    # Run command then shutdown
firebase emulators:exec --only firestore "npm test"   # With specific emulators

# Emulator info
firebase emulators:export ./backup                    # Export current data

# Default ports
# Auth:      9099
# Functions: 5001
# Firestore: 8080
# Database:  9000
# Hosting:   5000
# Pub/Sub:   8085
# Storage:   9199
# UI:        4000
```

## Cloud Functions

```bash
# Logs
firebase functions:log                          # View recent logs
firebase functions:log --only <function>        # Specific function logs
firebase functions:log -n 100                   # Last N log entries

# Management
firebase functions:list                         # List deployed functions
firebase functions:delete <function>            # Delete a function
firebase functions:delete <func> --region <r>   # Delete in specific region

# Secrets (2nd generation)
firebase functions:secrets:set <NAME>           # Set secret (prompts for value)
firebase functions:secrets:get <NAME>           # View secret metadata
firebase functions:secrets:access <NAME>        # View secret value
firebase functions:secrets:destroy <NAME>       # Delete secret
firebase functions:secrets:list                 # List all secrets
firebase functions:secrets:prune                # Remove unused secrets

# Configuration (1st generation - deprecated)
firebase functions:config:set key=value         # Set config
firebase functions:config:get                   # Get all config
firebase functions:config:unset key             # Remove config
```

## Firestore

```bash
# Indexes
firebase firestore:indexes                      # List indexes
firebase firestore:indexes > indexes.json       # Export index config

# Data management
firebase firestore:delete <path>                # Delete document
firebase firestore:delete <path> --recursive    # Delete collection recursively
firebase firestore:delete <path> -r --force     # Skip confirmation

# Rules
firebase deploy --only firestore:rules          # Deploy rules only
```

## Hosting

```bash
# Deployment
firebase deploy --only hosting                  # Deploy hosting
firebase hosting:disable                        # Take site offline

# Preview channels
firebase hosting:channel:create <id>            # Create preview channel
firebase hosting:channel:deploy <id>            # Deploy to channel
firebase hosting:channel:deploy <id> --expires 7d  # With expiration
firebase hosting:channel:list                   # List channels
firebase hosting:channel:delete <id>            # Delete channel
firebase hosting:clone <src>:<ch> <dst>:live    # Promote to live

# Rollback
firebase hosting:rollback                       # Rollback to previous version

# Sites (multi-site hosting)
firebase hosting:sites:list                     # List sites
firebase hosting:sites:create <id>              # Create new site
firebase hosting:sites:delete <id>              # Delete site
firebase target:apply hosting <target> <site>   # Apply deploy target
```

## Storage

```bash
firebase deploy --only storage                  # Deploy storage rules
```

## Useful Options (Global)

```bash
--project <id>          # Override active project
--config <file>         # Use alternate firebase.json
--debug                 # Enable debug logging
--json                  # Output as JSON (for scripting)
--non-interactive       # Disable prompts (CI/CD)
--token <token>         # Use CI token for auth
```

## .firebaserc Project Aliases

```json
{
  "projects": {
    "default": "my-project-dev",
    "staging": "my-project-staging", 
    "production": "my-project-prod"
  }
}
```

Switch with: `firebase use staging` or `firebase use production`
