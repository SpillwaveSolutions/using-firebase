# Cloud Functions Triggers Reference

Complete reference for all Cloud Functions trigger types with 1st gen, 2nd gen, TypeScript, and Python examples.

## Contents

- [Generation Comparison](#generation-comparison)
- [Firestore Triggers](#firestore-triggers)
- [Authentication Triggers](#authentication-triggers)
- [Storage Triggers](#storage-triggers)
- [HTTP Triggers](#http-triggers)
- [Callable Functions](#callable-functions)
- [Scheduled Functions](#scheduled-functions)
- [Pub/Sub Triggers](#pubsub-triggers)

---

## Generation Comparison

| Feature | 1st Generation | 2nd Generation |
|---------|----------------|----------------|
| Concurrency | 1 request/instance | Up to 1000/instance |
| HTTP Timeout | 9 minutes | 60 minutes |
| Memory | Up to 8 GB | Up to 32 GB |
| vCPU | Tied to memory | Configurable (up to 4) |
| Min instances | Yes | Yes |
| Secrets | Config (deprecated) | Secret Manager |
| Auth triggers | Full support | Blocking only |
| Built on | Cloud Functions | Cloud Run + Eventarc |

**Recommendation:** Use 2nd gen for new projects. Use 1st gen only for auth onCreate/onDelete triggers.

---

## Firestore Triggers

### 2nd Generation (Recommended)

**TypeScript:**
```typescript
import {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentDeleted,
  onDocumentWritten
} from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

initializeApp();
const db = getFirestore();

// Document created
export const onUserCreated = onDocumentCreated(
  "users/{userId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    
    const data = snapshot.data();
    const userId = event.params.userId;
    console.log(`New user: ${userId}`, data);
    
    // Example: Create related document
    await db.collection("profiles").doc(userId).set({
      userId,
      createdAt: new Date()
    });
  }
);

// Document updated
export const onUserUpdated = onDocumentUpdated(
  "users/{userId}",
  (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const userId = event.params.userId;
    
    if (before?.email !== after?.email) {
      console.log(`Email changed for ${userId}: ${before?.email} → ${after?.email}`);
    }
  }
);

// Document deleted
export const onUserDeleted = onDocumentDeleted(
  "users/{userId}",
  async (event) => {
    const userId = event.params.userId;
    // Cleanup related data
    await db.collection("profiles").doc(userId).delete();
  }
);

// Any write (create, update, delete)
export const onUserWrite = onDocumentWritten(
  "users/{userId}",
  (event) => {
    const before = event.data?.before.exists ? event.data.before.data() : null;
    const after = event.data?.after.exists ? event.data.after.data() : null;
    
    if (!before && after) console.log("Created");
    else if (before && !after) console.log("Deleted");
    else console.log("Updated");
  }
);

// With options
export const onOrderCreated = onDocumentCreated(
  {
    document: "orders/{orderId}",
    region: "us-central1",
    memory: "1GiB",
    timeoutSeconds: 300
  },
  async (event) => {
    // Process order
  }
);
```

**Python:**
```python
from firebase_functions.firestore_fn import (
    on_document_created,
    on_document_updated,
    on_document_deleted,
    on_document_written,
    Event,
    Change,
    DocumentSnapshot
)
from firebase_admin import initialize_app, firestore

initialize_app()
db = firestore.client()

@on_document_created(document="users/{userId}")
def on_user_created(event: Event[DocumentSnapshot]) -> None:
    if not event.data:
        return
    
    data = event.data.to_dict()
    user_id = event.params["userId"]
    print(f"New user: {user_id}, data: {data}")

@on_document_updated(document="users/{userId}")
def on_user_updated(event: Event[Change[DocumentSnapshot]]) -> None:
    before = event.data.before.to_dict() if event.data.before.exists else {}
    after = event.data.after.to_dict() if event.data.after.exists else {}
    user_id = event.params["userId"]
    print(f"User {user_id} updated: {before} → {after}")

@on_document_deleted(document="users/{userId}")
def on_user_deleted(event: Event[DocumentSnapshot]) -> None:
    user_id = event.params["userId"]
    print(f"User deleted: {user_id}")
```

### 1st Generation

```typescript
import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

export const onUserCreatedV1 = functions.firestore
  .document("users/{userId}")
  .onCreate((snapshot, context) => {
    const data = snapshot.data();
    const userId = context.params.userId;
    console.log(`New user: ${userId}`, data);
    return null;
  });

export const onUserUpdatedV1 = functions.firestore
  .document("users/{userId}")
  .onUpdate((change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    return null;
  });

export const onUserDeletedV1 = functions.firestore
  .document("users/{userId}")
  .onDelete((snapshot, context) => {
    return null;
  });

export const onUserWriteV1 = functions.firestore
  .document("users/{userId}")
  .onWrite((change, context) => {
    const before = change.before.exists ? change.before.data() : null;
    const after = change.after.exists ? change.after.data() : null;
    return null;
  });

// With region
export const onOrderCreatedV1 = functions
  .region("europe-west1")
  .firestore
  .document("orders/{orderId}")
  .onCreate((snapshot, context) => {
    return null;
  });
```

---

## Authentication Triggers

### Basic Auth Triggers (1st Gen Only)

```typescript
import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

// User created
export const onUserCreate = functions.auth.user().onCreate((user) => {
  console.log(`New user: ${user.uid}`);
  console.log(`Email: ${user.email}`);
  console.log(`Display name: ${user.displayName}`);
  console.log(`Photo URL: ${user.photoURL}`);
  console.log(`Provider: ${user.providerData}`);
  
  // Create user profile
  return admin.firestore().collection("profiles").doc(user.uid).set({
    email: user.email,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
});

// User deleted
export const onUserDelete = functions.auth.user().onDelete((user) => {
  console.log(`User deleted: ${user.uid}`);
  
  // Cleanup user data
  return admin.firestore().collection("profiles").doc(user.uid).delete();
});
```

### Blocking Functions (2nd Gen)

Intercept and modify authentication before completion:

**TypeScript:**
```typescript
import { beforeUserCreated, beforeUserSignedIn } from "firebase-functions/v2/identity";
import { HttpsError } from "firebase-functions/v2/https";

// Block or modify user creation
export const validateNewUser = beforeUserCreated((event) => {
  const user = event.data;
  
  // Block non-company emails
  if (!user.email?.endsWith("@company.com")) {
    throw new HttpsError("invalid-argument", "Only company emails allowed");
  }
  
  // Return modifications
  return {
    displayName: user.displayName?.toUpperCase(),
    customClaims: {
      role: "employee",
      department: "general"
    }
  };
});

// Block or modify sign-in
export const validateSignIn = beforeUserSignedIn((event) => {
  const user = event.data;
  
  // Check if user is banned
  if (user.customClaims?.banned) {
    throw new HttpsError("permission-denied", "Account is suspended");
  }
  
  return {
    sessionClaims: {
      signInTime: new Date().toISOString()
    }
  };
});
```

**Python:**
```python
from firebase_functions.identity_fn import (
    before_user_created,
    before_user_signed_in,
    AuthBlockingEvent
)
from firebase_functions.https_fn import HttpsError

@before_user_created()
def validate_new_user(event: AuthBlockingEvent) -> dict | None:
    user = event.data
    
    if not user.email or not user.email.endswith("@company.com"):
        raise HttpsError(
            code="invalid-argument",
            message="Only company emails allowed"
        )
    
    return {
        "customClaims": {"role": "employee"}
    }
```

---

## Storage Triggers

### 2nd Generation

**TypeScript:**
```typescript
import {
  onObjectFinalized,
  onObjectDeleted,
  onObjectArchived,
  onObjectMetadataUpdated
} from "firebase-functions/v2/storage";
import { getStorage } from "firebase-admin/storage";
import * as path from "path";

// Object uploaded/overwritten (finalized)
export const processUpload = onObjectFinalized(
  { cpu: 2, memory: "2GiB" },
  async (event) => {
    const filePath = event.data.name;        // Full path
    const bucket = event.data.bucket;        // Bucket name
    const contentType = event.data.contentType;
    const size = event.data.size;
    const metadata = event.data.metadata;    // Custom metadata
    
    console.log(`File uploaded: ${filePath}`);
    console.log(`Content type: ${contentType}`);
    console.log(`Size: ${size} bytes`);
    
    // Skip if not an image
    if (!contentType?.startsWith("image/")) {
      console.log("Not an image, skipping");
      return;
    }
    
    // Skip if already a thumbnail
    const fileName = path.basename(filePath);
    if (fileName.startsWith("thumb_")) {
      console.log("Already a thumbnail, skipping");
      return;
    }
    
    // Process image
    const storage = getStorage().bucket(bucket);
    const file = storage.file(filePath);
    // ... generate thumbnail
  }
);

// Object deleted
export const onFileDeleted = onObjectDeleted((event) => {
  console.log(`File deleted: ${event.data.name}`);
});

// Specific bucket
export const onBackupUploaded = onObjectFinalized(
  { bucket: "my-backup-bucket" },
  (event) => {
    console.log(`Backup uploaded: ${event.data.name}`);
  }
);
```

**Python:**
```python
from firebase_functions import storage_fn
from firebase_admin import storage
import pathlib

@storage_fn.on_object_finalized()
def process_upload(event: storage_fn.CloudEvent[storage_fn.StorageObjectData]) -> None:
    file_path = pathlib.PurePath(event.data.name)
    content_type = event.data.content_type
    bucket_name = event.data.bucket
    
    print(f"File uploaded: {file_path}")
    print(f"Content type: {content_type}")
    
    if not content_type or not content_type.startswith("image/"):
        print("Not an image, skipping")
        return
    
    if file_path.name.startswith("thumb_"):
        print("Already a thumbnail, skipping")
        return
    
    # Process image
    bucket = storage.bucket(bucket_name)
    blob = bucket.blob(str(file_path))
    # ... process
```

### 1st Generation

```typescript
import * as functions from "firebase-functions/v1";

export const processUploadV1 = functions.storage
  .object()
  .onFinalize((object) => {
    const filePath = object.name;
    const contentType = object.contentType;
    return null;
  });

// Specific bucket
export const onBackupV1 = functions.storage
  .bucket("my-backup-bucket")
  .object()
  .onFinalize((object) => {
    return null;
  });
```

---

## HTTP Triggers

### 2nd Generation

**TypeScript:**
```typescript
import { onRequest } from "firebase-functions/v2/https";
import * as express from "express";

// Simple HTTP function
export const helloWorld = onRequest((req, res) => {
  res.send("Hello World!");
});

// With CORS
export const api = onRequest({ cors: true }, (req, res) => {
  res.json({ message: "CORS enabled" });
});

// With specific origins
export const secureApi = onRequest(
  { cors: ["https://myapp.com", "https://admin.myapp.com"] },
  (req, res) => {
    res.json({ message: "Secure API" });
  }
);

// With options
export const heavyApi = onRequest(
  {
    region: "us-central1",
    memory: "4GiB",
    timeoutSeconds: 540,
    minInstances: 1,      // Keep warm
    maxInstances: 100,
    concurrency: 500
  },
  (req, res) => {
    res.json({ status: "ok" });
  }
);

// Express app
const app = express();
app.get("/users/:id", (req, res) => {
  res.json({ userId: req.params.id });
});
app.post("/users", (req, res) => {
  res.json({ created: true, data: req.body });
});

export const expressApi = onRequest(app);
```

**Python:**
```python
from firebase_functions import https_fn, options

@https_fn.on_request()
def hello_world(req: https_fn.Request) -> https_fn.Response:
    return https_fn.Response("Hello World!")

@https_fn.on_request(
    cors=options.CorsOptions(
        cors_origins=["*"],
        cors_methods=["GET", "POST"]
    )
)
def cors_enabled(req: https_fn.Request) -> https_fn.Response:
    import json
    return https_fn.Response(
        json.dumps({"message": "CORS enabled"}),
        content_type="application/json"
    )

@https_fn.on_request(
    memory=options.MemoryOption.GB_1,
    timeout_sec=300
)
def heavy_processing(req: https_fn.Request) -> https_fn.Response:
    # Process...
    return https_fn.Response("Done")
```

---

## Callable Functions

Type-safe client SDK with automatic authentication.

### 2nd Generation

**TypeScript:**
```typescript
import { onCall, HttpsError } from "firebase-functions/v2/https";

export const processOrder = onCall(async (request) => {
  // Input validation
  const { orderId, items } = request.data;
  if (!orderId || !items?.length) {
    throw new HttpsError("invalid-argument", "Missing orderId or items");
  }
  
  // Authentication check
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be logged in");
  }
  
  const uid = request.auth.uid;
  const email = request.auth.token.email;
  
  // Custom claims check
  if (request.auth.token.role !== "admin") {
    throw new HttpsError("permission-denied", "Admin access required");
  }
  
  // Process and return
  return { success: true, orderId, processedBy: uid };
});

// With options
export const heavyCallable = onCall(
  {
    memory: "2GiB",
    timeoutSeconds: 300,
    enforceAppCheck: true  // Require App Check
  },
  async (request) => {
    return { status: "processed" };
  }
);
```

**Python:**
```python
from firebase_functions import https_fn
from typing import Any

@https_fn.on_call()
def process_order(req: https_fn.CallableRequest) -> Any:
    # Authentication check
    if not req.auth:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Must be logged in"
        )
    
    # Input validation
    order_id = req.data.get("orderId")
    if not order_id:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Missing orderId"
        )
    
    return {
        "success": True,
        "orderId": order_id,
        "uid": req.auth.uid
    }
```

### HttpsError Codes

| Code | HTTP | Description |
|------|------|-------------|
| `ok` | 200 | Success |
| `invalid-argument` | 400 | Invalid input |
| `failed-precondition` | 400 | State not valid for operation |
| `out-of-range` | 400 | Value out of range |
| `unauthenticated` | 401 | Not authenticated |
| `permission-denied` | 403 | No permission |
| `not-found` | 404 | Resource not found |
| `already-exists` | 409 | Resource already exists |
| `resource-exhausted` | 429 | Quota exceeded |
| `cancelled` | 499 | Operation cancelled |
| `internal` | 500 | Internal error |
| `unimplemented` | 501 | Not implemented |
| `unavailable` | 503 | Service unavailable |
| `deadline-exceeded` | 504 | Timeout |

### Client SDK Call

```typescript
import { getFunctions, httpsCallable } from "firebase/functions";

const functions = getFunctions();
const processOrder = httpsCallable(functions, "processOrder");

try {
  const result = await processOrder({ orderId: "123", items: ["a", "b"] });
  console.log(result.data);
} catch (error) {
  console.error(error.code, error.message);
}
```

---

## Scheduled Functions

### 2nd Generation

**TypeScript:**
```typescript
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore } from "firebase-admin/firestore";

// Every 5 minutes
export const frequentTask = onSchedule("every 5 minutes", async (event) => {
  console.log("Running frequent task...");
});

// Cron syntax
export const dailyCleanup = onSchedule(
  {
    schedule: "0 2 * * *",  // 2 AM daily
    timeZone: "America/New_York",
    timeoutSeconds: 1800,
    memory: "2GiB"
  },
  async (event) => {
    const db = getFirestore();
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 30);
    
    const snapshot = await db.collection("logs")
      .where("createdAt", "<", cutoff)
      .limit(500)
      .get();
    
    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    
    console.log(`Deleted ${snapshot.size} old logs`);
  }
);

// Weekly report
export const weeklyReport = onSchedule(
  {
    schedule: "0 9 * * 1",  // Monday 9 AM
    timeZone: "America/Los_Angeles"
  },
  async (event) => {
    console.log("Generating weekly report...");
  }
);
```

**Python:**
```python
from firebase_functions import scheduler_fn

@scheduler_fn.on_schedule(schedule="every 5 minutes")
def frequent_task(event: scheduler_fn.ScheduledEvent) -> None:
    print("Running frequent task...")

@scheduler_fn.on_schedule(
    schedule="0 2 * * *",
    timezone="America/New_York"
)
def daily_cleanup(event: scheduler_fn.ScheduledEvent) -> None:
    print("Running daily cleanup...")
```

### Schedule Syntax

**App Engine style:**
- `every 5 minutes`
- `every 24 hours`
- `every monday 09:00`

**Cron syntax:** `minute hour day month weekday`
- `0 * * * *` - Every hour
- `0 2 * * *` - Daily at 2 AM
- `0 9 * * 1` - Every Monday at 9 AM
- `0 0 1 * *` - First of every month
- `*/15 * * * *` - Every 15 minutes

---

## Pub/Sub Triggers

### 2nd Generation

**TypeScript:**
```typescript
import { onMessagePublished } from "firebase-functions/v2/pubsub";

export const processPubSub = onMessagePublished(
  "my-topic",
  async (event) => {
    // Parse message
    const message = event.data.message;
    const data = message.json;        // Parsed JSON
    const rawData = message.data;     // Base64 string
    const attributes = message.attributes;
    const messageId = message.messageId;
    const publishTime = message.publishTime;
    
    console.log("Message:", data);
    console.log("Attributes:", attributes);
  }
);

// With options
export const heavyPubSub = onMessagePublished(
  {
    topic: "heavy-processing",
    memory: "4GiB",
    timeoutSeconds: 540
  },
  async (event) => {
    // Process...
  }
);
```

**Python:**
```python
from firebase_functions import pubsub_fn
import json

@pubsub_fn.on_message_published(topic="my-topic")
def process_pubsub(event: pubsub_fn.CloudEvent[pubsub_fn.MessagePublishedData]) -> None:
    message = event.data.message
    
    # Parse JSON data
    if message.data:
        data = json.loads(base64.b64decode(message.data).decode())
        print(f"Message data: {data}")
    
    # Attributes
    if message.attributes:
        print(f"Attributes: {message.attributes}")
```

### 1st Generation

```typescript
import * as functions from "firebase-functions/v1";

export const processPubSubV1 = functions.pubsub
  .topic("my-topic")
  .onPublish((message, context) => {
    const data = message.json;
    const attributes = message.attributes;
    return null;
  });
```
