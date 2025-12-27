# Security Rules Reference

Firestore and Storage security rules patterns.

## Contents

- [Firestore Rules Basics](#firestore-rules-basics)
- [Common Patterns](#common-patterns)
- [Helper Functions](#helper-functions)
- [Data Validation](#data-validation)
- [Custom Claims](#custom-claims)
- [Storage Rules](#storage-rules)
- [Testing Rules](#testing-rules)

---

## Firestore Rules Basics

### Structure

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Rules go here
  }
}
```

### Match Patterns

```javascript
// Single document
match /users/{userId} {
  // Rules for /users/user123
}

// Wildcard - any document in collection
match /posts/{postId} {
  // Rules for /posts/*
}

// Recursive wildcard - document and all subcollections
match /users/{userId}/{document=**} {
  // Rules for /users/user123 and /users/user123/orders/order1, etc.
}

// Subcollection
match /users/{userId}/orders/{orderId} {
  // Rules for /users/*/orders/*
}
```

### Operations

```javascript
match /users/{userId} {
  allow read;                    // get + list
  allow write;                   // create + update + delete
  
  allow get;                     // Single document read
  allow list;                    // Collection query
  allow create;                  // New document
  allow update;                  // Existing document
  allow delete;                  // Remove document
}
```

### Request Objects

```javascript
// request.auth - Authentication state
request.auth                      // null if not authenticated
request.auth.uid                  // User ID
request.auth.token.email          // Email
request.auth.token.email_verified // Boolean
request.auth.token.phone_number   // Phone
request.auth.token.name           // Display name
request.auth.token.<claim>        // Custom claims

// request.resource - Incoming data (for writes)
request.resource.data             // Document data being written
request.resource.data.title       // Specific field

// request.time - Server timestamp
request.time                      // Current server time
```

### Resource Object

```javascript
// resource.data - Existing document data (for reads/updates)
resource.data                     // Current document data
resource.data.authorId            // Specific field

// resource.__name__ - Document path
resource.__name__
```

---

## Common Patterns

### Owner-Only Access

```javascript
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}

// Shorthand function
function isOwner(userId) {
  return request.auth != null && request.auth.uid == userId;
}

match /users/{userId} {
  allow read, write: if isOwner(userId);
}
```

### Authenticated Users Only

```javascript
match /posts/{postId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null;
  allow update, delete: if request.auth != null 
                        && resource.data.authorId == request.auth.uid;
}
```

### Public Read, Authenticated Write

```javascript
match /articles/{articleId} {
  allow read: if true;
  allow write: if request.auth != null;
}
```

### Author Check on Update/Delete

```javascript
match /posts/{postId} {
  allow read: if true;
  allow create: if request.auth != null 
                && request.resource.data.authorId == request.auth.uid;
  allow update, delete: if request.auth != null 
                        && resource.data.authorId == request.auth.uid;
}
```

### Time-based Access

```javascript
match /events/{eventId} {
  // Only allow access before event ends
  allow read: if request.time < resource.data.endTime;
  
  // Only allow updates within 24 hours of creation
  allow update: if request.time < resource.data.createdAt + duration.value(24, 'h');
}
```

### Rate Limiting Pattern

```javascript
match /messages/{messageId} {
  allow create: if request.auth != null
    && (
      !exists(/databases/$(database)/documents/rateLimit/$(request.auth.uid))
      || get(/databases/$(database)/documents/rateLimit/$(request.auth.uid)).data.lastMessage 
         < request.time - duration.value(1, 'm')
    );
}
```

---

## Helper Functions

### Define Reusable Functions

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Authentication helpers
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isSignedIn() && request.auth.token.admin == true;
    }
    
    function hasRole(role) {
      return isSignedIn() && request.auth.token.role == role;
    }
    
    // Document helpers
    function isAuthor() {
      return isSignedIn() && resource.data.authorId == request.auth.uid;
    }
    
    function willBeAuthor() {
      return isSignedIn() && request.resource.data.authorId == request.auth.uid;
    }
    
    // Data access helpers
    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    
    function userExists(userId) {
      return exists(/databases/$(database)/documents/users/$(userId));
    }
    
    // Apply rules
    match /posts/{postId} {
      allow read: if true;
      allow create: if isSignedIn() && willBeAuthor();
      allow update: if isAuthor() || isAdmin();
      allow delete: if isAuthor() || isAdmin();
    }
    
    match /users/{userId} {
      allow read: if isSignedIn();
      allow write: if isOwner(userId);
    }
    
    match /admin/{document=**} {
      allow read, write: if isAdmin();
    }
  }
}
```

---

## Data Validation

### Required Fields

```javascript
match /posts/{postId} {
  allow create: if request.resource.data.keys().hasAll(['title', 'content', 'authorId'])
                && request.resource.data.title is string
                && request.resource.data.content is string;
}
```

### Field Types

```javascript
function isValidPost() {
  let data = request.resource.data;
  return data.title is string
      && data.content is string
      && data.views is int
      && data.published is bool
      && data.tags is list
      && data.metadata is map
      && data.createdAt is timestamp;
}
```

### String Length

```javascript
function isValidPost() {
  let data = request.resource.data;
  return data.title.size() >= 1 
      && data.title.size() <= 100
      && data.content.size() <= 10000;
}
```

### Allowed Values

```javascript
function isValidStatus() {
  return request.resource.data.status in ['draft', 'published', 'archived'];
}

function isValidPriority() {
  let p = request.resource.data.priority;
  return p >= 1 && p <= 5;
}
```

### Array Validation

```javascript
function isValidTags() {
  let tags = request.resource.data.tags;
  return tags.size() <= 10
      && tags.hasAll(tags.toSet().toList());  // No duplicates
}
```

### Immutable Fields

```javascript
match /posts/{postId} {
  allow update: if request.resource.data.authorId == resource.data.authorId
                && request.resource.data.createdAt == resource.data.createdAt;
}
```

### Only Allow Specific Fields to Change

```javascript
function onlyTheseFieldsChanged(fields) {
  return request.resource.data.diff(resource.data).affectedKeys().hasOnly(fields);
}

match /users/{userId} {
  allow update: if isOwner(userId)
                && onlyTheseFieldsChanged(['name', 'bio', 'avatar']);
}
```

### Comprehensive Validation Example

```javascript
match /posts/{postId} {
  function isValidCreate() {
    let data = request.resource.data;
    return data.keys().hasAll(['title', 'content', 'authorId', 'createdAt'])
        && data.keys().hasOnly(['title', 'content', 'authorId', 'createdAt', 'tags', 'status'])
        && data.title is string
        && data.title.size() >= 1
        && data.title.size() <= 100
        && data.content is string
        && data.content.size() <= 50000
        && data.authorId == request.auth.uid
        && data.createdAt == request.time
        && (!('tags' in data) || (data.tags is list && data.tags.size() <= 10))
        && (!('status' in data) || data.status in ['draft', 'published']);
  }
  
  allow create: if isSignedIn() && isValidCreate();
}
```

---

## Custom Claims

Custom claims are set via Admin SDK and available in rules.

### Setting Claims (Server-side)

```typescript
// Node.js Admin SDK
import { getAuth } from "firebase-admin/auth";

await getAuth().setCustomUserClaims(uid, {
  admin: true,
  role: "editor",
  accessLevel: 5,
  departments: ["engineering", "product"]
});
```

```python
# Python Admin SDK
from firebase_admin import auth

auth.set_custom_user_claims(uid, {
    "admin": True,
    "role": "editor",
    "accessLevel": 5
})
```

### Using Claims in Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAdmin() {
      return request.auth.token.admin == true;
    }
    
    function hasRole(role) {
      return request.auth.token.role == role;
    }
    
    function hasMinAccessLevel(level) {
      return request.auth.token.accessLevel >= level;
    }
    
    function isInDepartment(dept) {
      return dept in request.auth.token.departments;
    }
    
    match /admin/{document=**} {
      allow read, write: if isAdmin();
    }
    
    match /content/{docId} {
      allow read: if true;
      allow write: if hasRole('editor') || hasRole('admin');
    }
    
    match /sensitive/{docId} {
      allow read, write: if hasMinAccessLevel(5);
    }
    
    match /departments/{deptId}/{document=**} {
      allow read, write: if isInDepartment(deptId);
    }
  }
}
```

---

## Storage Rules

### Basic Structure

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Rules go here
  }
}
```

### Request Objects (Storage)

```javascript
request.auth                  // Same as Firestore
request.resource              // File being uploaded
request.resource.name         // File path
request.resource.size         // File size in bytes
request.resource.contentType  // MIME type
request.resource.metadata     // Custom metadata

resource                      // Existing file (for reads/deletes)
resource.name
resource.size
resource.contentType
resource.metadata
```

### Common Patterns

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // User-specific folders
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Profile pictures with validation
    match /profiles/{userId}/avatar.{ext} {
      allow read: if true;
      allow write: if request.auth.uid == userId
                   && request.resource.size < 5 * 1024 * 1024  // 5MB
                   && request.resource.contentType.matches('image/.*')
                   && ext.matches('jpg|jpeg|png|gif');
    }
    
    // Public read, authenticated write
    match /public/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Private uploads (only owner can access)
    match /private/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // File type validation
    match /documents/{docId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
                    && request.resource.contentType in [
                      'application/pdf',
                      'application/msword',
                      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                    ]
                    && request.resource.size < 10 * 1024 * 1024;  // 10MB
    }
    
    // Admin-only
    match /admin/{allPaths=**} {
      allow read, write: if request.auth.token.admin == true;
    }
  }
}
```

### Metadata Validation

```javascript
match /uploads/{fileId} {
  allow create: if request.auth != null
                && request.resource.metadata.uploadedBy == request.auth.uid
                && request.resource.metadata.category in ['photo', 'document', 'video'];
}
```

---

## Testing Rules

### Firebase Emulator Testing

```typescript
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment
} from "@firebase/rules-unit-testing";
import { readFileSync } from "fs";

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "demo-test",
    firestore: {
      rules: readFileSync("firestore.rules", "utf8")
    }
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

test("unauthenticated users cannot read private data", async () => {
  const db = testEnv.unauthenticatedContext().firestore();
  await assertFails(db.collection("users").doc("user123").get());
});

test("users can read their own data", async () => {
  const db = testEnv.authenticatedContext("user123").firestore();
  
  // Setup: create document first with admin context
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().collection("users").doc("user123").set({
      name: "Test User"
    });
  });
  
  await assertSucceeds(db.collection("users").doc("user123").get());
});

test("users cannot read other users data", async () => {
  const db = testEnv.authenticatedContext("user123").firestore();
  await assertFails(db.collection("users").doc("user456").get());
});

test("admins can read all data", async () => {
  const db = testEnv.authenticatedContext("admin", {
    admin: true  // Custom claim
  }).firestore();
  
  await assertSucceeds(db.collection("admin").doc("config").get());
});

test("validates required fields on create", async () => {
  const db = testEnv.authenticatedContext("user123").firestore();
  
  // Missing required field
  await assertFails(db.collection("posts").add({
    title: "Test"
    // Missing content
  }));
  
  // All required fields
  await assertSucceeds(db.collection("posts").add({
    title: "Test",
    content: "Content",
    authorId: "user123"
  }));
});
```

### Run Tests

```bash
# Start emulator and run tests
firebase emulators:exec --only firestore "npm test"

# Or with emulators already running
npm test
```

### Deploy Rules

```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
```
