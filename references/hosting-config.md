# Firebase Hosting Reference

Configuration, rewrites, redirects, headers, and deployment.

## Contents

- [Basic Configuration](#basic-configuration)
- [Rewrites](#rewrites)
- [Redirects](#redirects)
- [Headers](#headers)
- [Preview Channels](#preview-channels)
- [Multi-site Hosting](#multi-site-hosting)

---

## Basic Configuration

### firebase.json

```json
{
  "hosting": {
    "public": "dist",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "cleanUrls": true,
    "trailingSlash": false
  }
}
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `public` | Directory to deploy | Required |
| `ignore` | Files to exclude | `["**/.*", "**/node_modules/**"]` |
| `cleanUrls` | Remove `.html` from URLs | `false` |
| `trailingSlash` | Add trailing slash | `false` |
| `appAssociation` | iOS/Android app association | - |
| `i18n` | Internationalization config | - |

---

## Rewrites

Route requests to different destinations.

### SPA (Single Page Application)

```json
{
  "hosting": {
    "public": "dist",
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

### Cloud Functions

```json
{
  "hosting": {
    "rewrites": [
      {
        "source": "/api/**",
        "function": {
          "functionId": "api",
          "region": "us-central1"
        }
      }
    ]
  }
}
```

**Shorthand (default region):**
```json
{
  "source": "/api/**",
  "function": "api"
}
```

### Cloud Run

```json
{
  "hosting": {
    "rewrites": [
      {
        "source": "/app/**",
        "run": {
          "serviceId": "my-service",
          "region": "us-central1"
        }
      }
    ]
  }
}
```

### Dynamic Links (Firebase Hosting)

```json
{
  "hosting": {
    "rewrites": [
      {
        "source": "/links/**",
        "dynamicLinks": true
      }
    ]
  }
}
```

### Combined Example

```json
{
  "hosting": {
    "public": "dist",
    "rewrites": [
      {
        "source": "/api/**",
        "function": "api"
      },
      {
        "source": "/admin/**",
        "run": {
          "serviceId": "admin-dashboard",
          "region": "us-central1"
        }
      },
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

**Order matters:** First matching rule wins.

---

## Redirects

### Basic Redirects

```json
{
  "hosting": {
    "redirects": [
      {
        "source": "/old-page",
        "destination": "/new-page",
        "type": 301
      },
      {
        "source": "/legacy/**",
        "destination": "https://legacy.example.com/:splat",
        "type": 302
      }
    ]
  }
}
```

### Redirect Types

| Type | Description |
|------|-------------|
| `301` | Permanent redirect (cached by browsers) |
| `302` | Temporary redirect |

### With Path Segments

```json
{
  "redirects": [
    {
      "source": "/blog/:slug",
      "destination": "/articles/:slug",
      "type": 301
    },
    {
      "source": "/users/:uid/profile",
      "destination": "/profiles/:uid",
      "type": 301
    }
  ]
}
```

### Glob Patterns

```json
{
  "redirects": [
    {
      "source": "/old/**",
      "destination": "/new/:splat",
      "type": 301
    },
    {
      "source": "/docs/v1/**",
      "destination": "/docs/latest/:splat",
      "type": 302
    }
  ]
}
```

### External Redirects

```json
{
  "redirects": [
    {
      "source": "/github",
      "destination": "https://github.com/myorg",
      "type": 302
    }
  ]
}
```

---

## Headers

### Cache Control

```json
{
  "hosting": {
    "headers": [
      {
        "source": "**/*.@(jpg|jpeg|gif|png|svg|webp)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000, immutable"
          }
        ]
      },
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      },
      {
        "source": "**/*.html",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "no-cache"
          }
        ]
      }
    ]
  }
}
```

### Security Headers

```json
{
  "hosting": {
    "headers": [
      {
        "source": "**",
        "headers": [
          {
            "key": "X-Content-Type-Options",
            "value": "nosniff"
          },
          {
            "key": "X-Frame-Options",
            "value": "DENY"
          },
          {
            "key": "X-XSS-Protection",
            "value": "1; mode=block"
          },
          {
            "key": "Referrer-Policy",
            "value": "strict-origin-when-cross-origin"
          },
          {
            "key": "Permissions-Policy",
            "value": "camera=(), microphone=(), geolocation=()"
          }
        ]
      }
    ]
  }
}
```

### CORS Headers

```json
{
  "hosting": {
    "headers": [
      {
        "source": "/api/**",
        "headers": [
          {
            "key": "Access-Control-Allow-Origin",
            "value": "*"
          },
          {
            "key": "Access-Control-Allow-Methods",
            "value": "GET, POST, OPTIONS"
          },
          {
            "key": "Access-Control-Allow-Headers",
            "value": "Content-Type, Authorization"
          }
        ]
      }
    ]
  }
}
```

### Content Security Policy

```json
{
  "headers": [
    {
      "source": "**",
      "headers": [
        {
          "key": "Content-Security-Policy",
          "value": "default-src 'self'; script-src 'self' 'unsafe-inline' https://apis.google.com; style-src 'self' 'unsafe-inline'"
        }
      ]
    }
  ]
}
```

---

## Preview Channels

Deploy to temporary URLs for testing.

### Create and Deploy

```bash
# Deploy to preview channel
firebase hosting:channel:deploy preview-feature-x

# With expiration
firebase hosting:channel:deploy preview --expires 7d
firebase hosting:channel:deploy preview --expires 30d

# List channels
firebase hosting:channel:list

# Delete channel
firebase hosting:channel:delete preview-feature-x
```

### Expiration Options

- `1h`, `2h`, ... (hours)
- `1d`, `7d`, `30d` (days)
- Max: 30 days

### Promote to Live

```bash
# Clone preview to live
firebase hosting:clone project-id:preview-channel project-id:live
```

### CI/CD Integration

```yaml
# GitHub Actions example
- name: Deploy to preview
  run: |
    firebase hosting:channel:deploy pr-${{ github.event.pull_request.number }} \
      --expires 7d \
      --token ${{ secrets.FIREBASE_TOKEN }}
```

---

## Multi-site Hosting

Host multiple sites from one project.

### Create Additional Sites

```bash
firebase hosting:sites:create my-admin-site
firebase hosting:sites:list
```

### Configure firebase.json

```json
{
  "hosting": [
    {
      "target": "main",
      "public": "dist/main",
      "rewrites": [
        { "source": "**", "destination": "/index.html" }
      ]
    },
    {
      "target": "admin",
      "public": "dist/admin",
      "rewrites": [
        { "source": "**", "destination": "/index.html" }
      ]
    }
  ]
}
```

### Apply Deploy Targets

```bash
firebase target:apply hosting main my-project
firebase target:apply hosting admin my-admin-site
```

This creates entries in `.firebaserc`:

```json
{
  "projects": {
    "default": "my-project"
  },
  "targets": {
    "my-project": {
      "hosting": {
        "main": ["my-project"],
        "admin": ["my-admin-site"]
      }
    }
  }
}
```

### Deploy Specific Sites

```bash
firebase deploy --only hosting:main
firebase deploy --only hosting:admin
firebase deploy --only hosting  # All sites
```

---

## Deployment

### Deploy Commands

```bash
# Deploy hosting only
firebase deploy --only hosting

# With message
firebase deploy --only hosting --message "Version 1.2.0"

# Specific site (multi-site)
firebase deploy --only hosting:main
```

### Rollback

```bash
# Rollback to previous version
firebase hosting:rollback
```

### View Deploys

```bash
# In console
firebase open hosting
```

---

## Complete Example

```json
{
  "hosting": {
    "public": "dist",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "cleanUrls": true,
    "trailingSlash": false,
    
    "redirects": [
      {
        "source": "/old/**",
        "destination": "/new/:splat",
        "type": 301
      }
    ],
    
    "rewrites": [
      {
        "source": "/api/**",
        "function": {
          "functionId": "api",
          "region": "us-central1"
        }
      },
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    
    "headers": [
      {
        "source": "**/*.@(jpg|jpeg|gif|png|svg|webp|js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      },
      {
        "source": "**",
        "headers": [
          {
            "key": "X-Content-Type-Options",
            "value": "nosniff"
          },
          {
            "key": "X-Frame-Options",
            "value": "DENY"
          }
        ]
      }
    ]
  }
}
```
