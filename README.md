# Firebase Development Skill

A comprehensive Claude Code skill for Firebase development on GCP-hosted applications.

## Overview

This skill provides complete guidance for:
- **Firestore**: CRUD operations, queries, transactions, data modeling
- **Cloud Functions**: 1st and 2nd generation, TypeScript and Python
- **Security Rules**: Firestore and Cloud Storage
- **Authentication**: Integration patterns and session management
- **Hosting**: Configuration, rewrites, and headers
- **GCP Integration**: BigQuery, Cloud Tasks, and more

## Installation

Copy this skill to your Claude Code skills directory:

```bash
cp -r using-firebase ~/.claude/skills/
```

Or clone from the repository and install via the Claude Code skill manager.

## Installing with Skilz (Universal Installer)

The recommended way to install this skill across different AI coding agents is using the **skilz** universal installer.

### Install Skilz

```bash
pip install skilz
```

### Git URL Options

You can use either `-g` or `--git` with HTTPS or SSH URLs:

```bash
# HTTPS URL
skilz install -g https://github.com/SpillwaveSolutions/using-firebase

# SSH URL
skilz install --git git@github.com:SpillwaveSolutions/using-firebase.git
```

### Claude Code

Install to user home (available in all projects):
```bash
skilz install -g https://github.com/SpillwaveSolutions/using-firebase
```

Install to current project only:
```bash
skilz install -g https://github.com/SpillwaveSolutions/using-firebase --project
```

### OpenCode

Install for [OpenCode](https://opencode.ai):
```bash
skilz install -g https://github.com/SpillwaveSolutions/using-firebase --agent opencode
```

Project-level install:
```bash
skilz install -g https://github.com/SpillwaveSolutions/using-firebase --project --agent opencode
```

### Gemini

Project-level install for Gemini:
```bash
skilz install -g https://github.com/SpillwaveSolutions/using-firebase --agent gemini
```

### OpenAI Codex

Install for OpenAI Codex:
```bash
skilz install -g https://github.com/SpillwaveSolutions/using-firebase --agent codex
```

Project-level install:
```bash
skilz install -g https://github.com/SpillwaveSolutions/using-firebase --project --agent codex
```

### Other Supported Agents

Skilz supports 14+ coding agents including Windsurf, Qwen Code, and more.

For complete documentation and the full list of supported agents, visit [AgentSkills.io](https://agentskills.io/home).

## Quick Start

1. **Initialize project**: `scripts/init_project.sh [project-id]`
2. **Start emulators**: `scripts/start_emulators.sh`
3. **Deploy**: `scripts/deploy.sh`

See [SKILL.md](SKILL.md) for full documentation.

## Resources

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

## Marketplace

Find more Agentic Skills at [SkillzWave.ai](https://skillzwave.ai/) - the largest marketplace for agentic AI skills.

## About

This skill is developed and maintained by the community. For more developer tools and resources, visit [SpillWave.com - Leaders in AI Agent Development](https://spillwave.com/).

## License

MIT License - feel free to use, modify, and distribute.

## Contributing

Contributions are welcome! Please submit issues and pull requests to improve this skill.
