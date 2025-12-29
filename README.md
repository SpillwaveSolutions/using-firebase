# Firebase Development Skill

[![Skill Standard](https://img.shields.io/badge/standard-AgentSkills.io-blue)](https://agentskills.io/home)
[![SkillzWave](https://img.shields.io/badge/marketplace-SkillzWave.ai-orange)](https://skillzwave.ai/skill/SpillwaveSolutions__using-firebase__using-firebase__SKILL/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A comprehensive Claude Code skill for Firebase development on GCP-hosted applications.

## Overview

This skill provides complete guidance for developing Firebase applications:

| Feature | Description |
|---------|-------------|
| **Firestore** | CRUD operations, queries, transactions, data modeling |
| **Cloud Functions** | 1st and 2nd generation, TypeScript and Python |
| **Security Rules** | Firestore and Cloud Storage rule patterns |
| **Authentication** | Integration patterns and session management |
| **Hosting** | Configuration, rewrites, headers, and caching |
| **GCP Integration** | BigQuery, Cloud Tasks, Pub/Sub, and more |

## Quick Start

1. **Initialize project**: `scripts/init_project.sh [project-id]`
2. **Start emulators**: `scripts/start_emulators.sh`
3. **Deploy**: `scripts/deploy.sh`

See [SKILL.md](SKILL.md) for full documentation.

## Installation

### Skilz Universal Installer (Recommended)

The recommended way to install this skill across different AI coding agents is using the **skilz** universal installer.

#### Install Skilz

```bash
pip install skilz
```

#### Claude Code

Install to user home (available in all projects):

```bash
skilz install -g https://github.com/SpillwaveSolutions/using-firebase
```

Install to current project only:

```bash
skilz install -g https://github.com/SpillwaveSolutions/using-firebase --project
```

#### OpenCode

Install for [OpenCode](https://opencode.ai):

```bash
skilz install -g https://github.com/SpillwaveSolutions/using-firebase --agent opencode
```

Project-level install:

```bash
skilz install -g https://github.com/SpillwaveSolutions/using-firebase --project --agent opencode
```

#### Gemini CLI

Project-level install for Gemini:

```bash
skilz install -g https://github.com/SpillwaveSolutions/using-firebase --agent gemini
```

#### OpenAI Codex

Install for OpenAI Codex:

```bash
skilz install -g https://github.com/SpillwaveSolutions/using-firebase --agent codex
```

Project-level install:

```bash
skilz install -g https://github.com/SpillwaveSolutions/using-firebase --project --agent codex
```

#### Git URL Options

You can use either HTTPS or SSH URLs:

```bash
# HTTPS URL
skilz install -g https://github.com/SpillwaveSolutions/using-firebase

# SSH URL
skilz install --git git@github.com:SpillwaveSolutions/using-firebase.git
```

#### Other Supported Agents

Skilz supports 14+ coding agents including Windsurf, Qwen Code, Cursor, and more.

For the full list of supported platforms, visit [SkillzWave.ai/platforms](https://skillzwave.ai/platforms/) or see the [skilz-cli GitHub repository](https://github.com/SpillwaveSolutions/skilz-cli).

### Manual Installation

Copy this skill to your Claude Code skills directory:

```bash
cp -r using-firebase ~/.claude/skills/
```

Or clone from the repository and install via the Claude Code skill manager.

## Reference Documentation

| Reference | Description |
|-----------|-------------|
| [firestore.md](references/firestore.md) | CRUD, queries, transactions, data modeling |
| [functions-triggers.md](references/functions-triggers.md) | All Cloud Functions trigger types |
| [functions-patterns.md](references/functions-patterns.md) | Error handling, secrets, App Check |
| [security-rules.md](references/security-rules.md) | Firestore and Storage rules |
| [auth-integration.md](references/auth-integration.md) | Authentication setup |
| [hosting-config.md](references/hosting-config.md) | Hosting configuration |
| [gcp-integration.md](references/gcp-integration.md) | GCP service integration |
| [cli-commands.md](references/cli-commands.md) | Firebase CLI reference |

## Scripts

| Script | Description |
|--------|-------------|
| `init_project.sh` | Initialize Firebase project with Firestore, Functions, Hosting |
| `start_emulators.sh` | Start emulator suite with data persistence |
| `deploy.sh` | Deploy with safety confirmations |
| `deploy_functions.sh` | Deploy Cloud Functions with granular control |
| `manage_secrets.sh` | Manage Cloud Functions secrets |
| `export_firestore.sh` | Export Firestore data |
| `import_firestore.sh` | Import Firestore data |
| `setup_python_functions.py` | Create Python Cloud Functions project |

## Asset Templates

| File | Use |
|------|-----|
| `assets/firebase.json.template` | Copy to `firebase.json` and customize |
| `assets/firestore.rules.template` | Copy to `firestore.rules` |
| `assets/storage.rules.template` | Copy to `storage.rules` |
| `assets/tsconfig.functions.json` | Copy to `functions/tsconfig.json` |

## Standards

This skill follows the [AgentSkills.io](https://agentskills.io/home) standard for agentic skills, ensuring compatibility across multiple AI coding assistants.

## Marketplace

Find this skill and more at [SkillzWave.ai](https://skillzwave.ai/) - the largest marketplace for agentic AI skills.

**Direct link**: [using-firebase on SkillzWave](https://skillzwave.ai/skill/SpillwaveSolutions__using-firebase__using-firebase__SKILL/)

## About

This skill is developed and maintained by the community. For more developer tools and resources, visit [SpillWave.com - Leaders in AI Agent Development](https://spillwave.com/).

## License

MIT License - feel free to use, modify, and distribute.

## Contributing

Contributions are welcome! Please submit issues and pull requests to improve this skill.
