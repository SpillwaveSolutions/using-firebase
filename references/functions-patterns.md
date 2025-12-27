# Cloud Functions Patterns Reference

Error handling, optimization, secrets, testing, and best practices.

## Contents

- [Error Handling](#error-handling)
- [Secrets Management](#secrets-management)
- [Global Options](#global-options)
- [Performance Optimization](#performance-optimization)
- [Idempotency](#idempotency)
- [Retry Behavior](#retry-behavior)
- [Logging](#logging)
- [Testing with Emulators](#testing-with-emulators)

---

## Error Handling

### Callable Functions

```typescript
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";

export const safeCallable = onCall(async (request) => {
  try {
    // Validate input
    if (!request.data?.id) {
      throw new HttpsError("invalid-argument", "ID is required");
    }
    
    // Check authentication
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be logged in");
    }
    
    // Check permissions
    if (!request.auth.token.admin) {
      throw new HttpsError("permission-denied", "Admin access required");
    }
    
    // Business logic
    const result = await processData(request.data);
    return { success: true, result };
    
  } catch (error) {
    // Re-throw HttpsError as-is
    if (error instanceof HttpsError) {
      throw error;
    }
    
    // Log unexpected errors
    logger.error("Unexpected error:", error);
    
    // Return generic error to client
    throw new HttpsError("internal", "An unexpected error occurred");
  }
});
```

### Background Functions (Event Triggers)

```typescript
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";

export const processDocument = onDocumentCreated(
  "orders/{orderId}",
  async (event) => {
    try {
      const data = event.data?.data();
      if (!data) {
        logger.warn("No data in document");
        return;  // Don't retry - data won't appear
      }
      
      await processOrder(data);
      logger.info("Order processed successfully", { orderId: event.params.orderId });
      
    } catch (error) {
      // Log error with context
      logger.error("Failed to process order", {
        orderId: event.params.orderId,
        error: error.message,
        stack: error.stack
      });
      
      // Throwing will trigger retry (if retries enabled)
      throw error;
    }
  }
);
```

### Python Error Handling

```python
from firebase_functions import https_fn
from firebase_functions.firestore_fn import on_document_created, Event, DocumentSnapshot
import logging

@https_fn.on_call()
def safe_callable(req: https_fn.CallableRequest):
    try:
        if not req.data.get("id"):
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="ID is required"
            )
        
        if not req.auth:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
                message="Must be logged in"
            )
        
        result = process_data(req.data)
        return {"success": True, "result": result}
        
    except https_fn.HttpsError:
        raise
    except Exception as e:
        logging.exception("Unexpected error")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message="An unexpected error occurred"
        )
```

---

## Secrets Management

### 2nd Generation (Recommended)

**Define and use secrets:**
```typescript
import { defineSecret } from "firebase-functions/params";
import { onRequest, onCall } from "firebase-functions/v2/https";

// Define secrets
const apiKey = defineSecret("API_KEY");
const dbPassword = defineSecret("DB_PASSWORD");

// HTTP function with secrets
export const secureApi = onRequest(
  { secrets: [apiKey, dbPassword] },
  async (req, res) => {
    const key = apiKey.value();
    const password = dbPassword.value();
    
    // Use secrets...
    res.json({ status: "ok" });
  }
);

// Callable with secrets
export const secureCallable = onCall(
  { secrets: [apiKey] },
  async (request) => {
    const key = apiKey.value();
    return { success: true };
  }
);
```

**CLI commands:**
```bash
firebase functions:secrets:set API_KEY        # Set secret (prompts for value)
firebase functions:secrets:get API_KEY        # View metadata
firebase functions:secrets:access API_KEY     # View value
firebase functions:secrets:destroy API_KEY    # Delete
firebase functions:secrets:list               # List all
```

### Python Secrets

```python
from firebase_functions import https_fn
from firebase_functions.params import SecretParam

API_KEY = SecretParam("API_KEY")

@https_fn.on_request(secrets=[API_KEY])
def secure_api(req: https_fn.Request) -> https_fn.Response:
    key = API_KEY.value
    # Use key...
    return https_fn.Response("OK")
```

### Environment Parameters (Non-secret)

```typescript
import { defineString, defineInt, defineBool } from "firebase-functions/params";

const apiUrl = defineString("API_URL");
const maxRetries = defineInt("MAX_RETRIES", { default: 3 });
const debugMode = defineBool("DEBUG_MODE", { default: false });

export const myFunction = onRequest((req, res) => {
  const url = apiUrl.value();
  const retries = maxRetries.value();
  const debug = debugMode.value();
  
  res.json({ url, retries, debug });
});
```

Set via `.env` files:
```bash
# .env.local (development)
API_URL=http://localhost:3000
DEBUG_MODE=true

# .env.production
API_URL=https://api.production.com
DEBUG_MODE=false
```

---

## Global Options

### Set Defaults for All Functions

```typescript
import { setGlobalOptions } from "firebase-functions/v2";

setGlobalOptions({
  region: "us-central1",
  memory: "512MiB",
  timeoutSeconds: 120,
  maxInstances: 10,
  minInstances: 0,
  concurrency: 80
});
```

### Per-Function Override

```typescript
export const heavyFunction = onRequest(
  {
    memory: "4GiB",
    timeoutSeconds: 540,
    maxInstances: 50,
    minInstances: 1,  // Keep warm
    concurrency: 500,
    cpu: 2
  },
  (req, res) => {
    res.send("Heavy processing complete");
  }
);
```

### Available Options

| Option | Description | Default |
|--------|-------------|---------|
| `region` | Deployment region | us-central1 |
| `memory` | Memory allocation | 256MiB |
| `timeoutSeconds` | Max execution time | 60 (HTTP: 60, Event: 540) |
| `minInstances` | Minimum warm instances | 0 |
| `maxInstances` | Maximum instances | 100 |
| `concurrency` | Requests per instance | 80 |
| `cpu` | vCPU count | 1 |
| `vpcConnector` | VPC connector | - |
| `ingressSettings` | Ingress rules | ALLOW_ALL |
| `labels` | Custom labels | {} |

### Memory/CPU Combinations

| Memory | Default CPU |
|--------|-------------|
| 128MiB - 512MiB | 0.083 |
| 1GiB | 0.5 |
| 2GiB | 1 |
| 4GiB | 2 |
| 8GiB+ | 2 (can specify up to 4) |

---

## Performance Optimization

### Reduce Cold Starts

**1. Use minInstances:**
```typescript
export const lowLatencyApi = onRequest(
  { minInstances: 1 },
  (req, res) => res.send("Fast!")
);
```

**2. Lazy-load dependencies:**
```typescript
// ❌ Bad: Loaded on every cold start
import * as heavyLib from "heavy-library";

// ✅ Good: Loaded only when needed
let heavyLib: typeof import("heavy-library") | null = null;

async function getHeavyLib() {
  if (!heavyLib) {
    heavyLib = await import("heavy-library");
  }
  return heavyLib;
}
```

**3. Reuse connections with global scope:**
```typescript
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

// Initialize once, reuse across invocations
const app = initializeApp();
const db = getFirestore();

export const myFunction = onRequest(async (req, res) => {
  // db is reused
  const doc = await db.collection("users").doc("123").get();
  res.json(doc.data());
});
```

**4. Use concurrency (2nd gen):**
```typescript
export const highThroughput = onRequest(
  { concurrency: 500 },  // Handle 500 concurrent requests per instance
  (req, res) => res.send("OK")
);
```

### Optimize Memory Usage

```typescript
// Stream large files instead of loading into memory
import { getStorage } from "firebase-admin/storage";

export const processLargeFile = onObjectFinalized(async (event) => {
  const bucket = getStorage().bucket(event.data.bucket);
  const file = bucket.file(event.data.name);
  
  // Stream instead of download
  const stream = file.createReadStream();
  
  for await (const chunk of stream) {
    // Process chunk by chunk
  }
});
```

---

## Idempotency

Background functions may execute multiple times. Design for idempotency.

### Use Event ID for Deduplication

```typescript
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore } from "firebase-admin/firestore";

const db = getFirestore();

export const processOnce = onDocumentCreated(
  "orders/{orderId}",
  async (event) => {
    const eventId = event.id;
    const lockRef = db.collection("processedEvents").doc(eventId);
    
    // Atomic check-and-set
    try {
      await db.runTransaction(async (transaction) => {
        const lockDoc = await transaction.get(lockRef);
        
        if (lockDoc.exists) {
          console.log("Already processed, skipping");
          return;
        }
        
        // Mark as processed
        transaction.set(lockRef, {
          processedAt: new Date(),
          orderId: event.params.orderId
        });
        
        // Do actual processing
        await processOrder(event.data?.data());
      });
    } catch (error) {
      console.error("Transaction failed:", error);
      throw error;
    }
  }
);
```

### Idempotent Operations

```typescript
// ❌ Not idempotent - will double-charge
await chargeCustomer(customerId, amount);

// ✅ Idempotent - uses idempotency key
await chargeCustomer(customerId, amount, { idempotencyKey: event.id });

// ❌ Not idempotent - counter will be wrong
await updateDoc(docRef, { count: increment(1) });

// ✅ Idempotent - set to absolute value
await setDoc(docRef, { count: newTotal });
```

---

## Retry Behavior

### Event-triggered Functions

By default, background functions retry on failure:
- **Firestore triggers:** Retry for up to 7 days
- **Pub/Sub triggers:** Configurable, default exponential backoff
- **Storage triggers:** Retry for up to 7 days

**Disable retries:**
```typescript
export const noRetry = onDocumentCreated(
  {
    document: "orders/{orderId}",
    retry: false
  },
  async (event) => {
    // Will not retry on failure
  }
);
```

### Handle Retries Gracefully

```typescript
export const withRetryHandling = onDocumentCreated(
  "orders/{orderId}",
  async (event) => {
    const eventTime = new Date(event.time);
    const now = new Date();
    const ageMinutes = (now.getTime() - eventTime.getTime()) / 60000;
    
    // Give up after 30 minutes of retries
    if (ageMinutes > 30) {
      console.warn("Event too old, giving up", { age: ageMinutes });
      return;  // Return without throwing to stop retries
    }
    
    try {
      await processOrder(event.data?.data());
    } catch (error) {
      if (isTransient(error)) {
        throw error;  // Retry
      } else {
        console.error("Permanent failure, not retrying", error);
        return;  // Don't retry
      }
    }
  }
);

function isTransient(error: any): boolean {
  // Network errors, rate limits, etc.
  return error.code === "UNAVAILABLE" || 
         error.code === "DEADLINE_EXCEEDED" ||
         error.code === "RESOURCE_EXHAUSTED";
}
```

---

## Logging

### Structured Logging

```typescript
import { logger } from "firebase-functions";

export const myFunction = onRequest((req, res) => {
  // Simple logs
  logger.debug("Debug message");
  logger.info("Info message");
  logger.warn("Warning message");
  logger.error("Error message");
  
  // Structured logging (recommended)
  logger.info("Processing request", {
    path: req.path,
    method: req.method,
    userId: req.headers["x-user-id"]
  });
  
  // With severity
  logger.write({
    severity: "INFO",
    message: "Custom log entry",
    customField: "value"
  });
  
  res.send("OK");
});
```

### Python Logging

```python
import logging

# Cloud Functions picks up standard logging
logging.info("Info message")
logging.warning("Warning message")
logging.error("Error message")

# With structured data
logging.info("Processing request", extra={
    "path": req.path,
    "method": req.method
})
```

### View Logs

```bash
firebase functions:log                      # All functions
firebase functions:log --only myFunction    # Specific function
firebase functions:log -n 100               # Last 100 entries

# In GCP Console: Logging > Logs Explorer
# Filter: resource.type="cloud_function"
```

---

## Testing with Emulators

### Setup

```bash
firebase emulators:start --only functions,firestore
```

### Unit Testing (TypeScript/Jest)

```typescript
import { describe, it, beforeAll, afterAll } from "@jest/globals";
import {
  initializeTestEnvironment,
  RulesTestEnvironment
} from "@firebase/rules-unit-testing";

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "demo-test",
    firestore: {
      host: "localhost",
      port: 8080
    }
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

describe("Cloud Functions", () => {
  it("should create profile on user creation", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    
    // Trigger function by creating user document
    await db.collection("users").doc("user123").set({
      name: "Test User",
      email: "test@example.com"
    });
    
    // Wait for function to process
    await new Promise((resolve) => setTimeout(resolve, 2000));
    
    // Verify profile was created
    const profile = await db.collection("profiles").doc("user123").get();
    expect(profile.exists).toBe(true);
  });
});
```

### Test Callable Functions

```typescript
import { getFunctions, httpsCallable, connectFunctionsEmulator } from "firebase/functions";

const functions = getFunctions();
connectFunctionsEmulator(functions, "localhost", 5001);

const myCallable = httpsCallable(functions, "myCallable");

test("callable function works", async () => {
  const result = await myCallable({ input: "test" });
  expect(result.data.success).toBe(true);
});
```

### Run Tests

```bash
# Start emulators and run tests
firebase emulators:exec "npm test"

# With specific emulators
firebase emulators:exec --only functions,firestore "npm test"
```

## App Check Integration

App Check protects your backend resources from abuse by verifying requests come from legitimate apps.

### Enable App Check for Callable Functions

```typescript
import { onCall, HttpsError } from "firebase-functions/v2/https";

export const protectedFunction = onCall(
  {
    enforceAppCheck: true,  // Reject requests without valid App Check token
    consumeAppCheckToken: true  // Prevent token replay attacks
  },
  async (request) => {
    // request.app contains App Check token info
    if (!request.app) {
      throw new HttpsError("failed-precondition", "App Check required");
    }

    return { data: "Protected data" };
  }
);
```

### Verify App Check in HTTP Functions

```typescript
import { onRequest } from "firebase-functions/v2/https";
import { getAppCheck } from "firebase-admin/app-check";

export const protectedEndpoint = onRequest(async (req, res) => {
  const appCheckToken = req.header("X-Firebase-AppCheck");

  if (!appCheckToken) {
    res.status(401).json({ error: "Missing App Check token" });
    return;
  }

  try {
    await getAppCheck().verifyToken(appCheckToken);
    res.json({ data: "Protected data" });
  } catch (error) {
    res.status(401).json({ error: "Invalid App Check token" });
  }
});
```

### Client-Side Setup (Web)

```typescript
import { initializeAppCheck, ReCaptchaV3Provider } from "firebase/app-check";

const appCheck = initializeAppCheck(app, {
  provider: new ReCaptchaV3Provider("YOUR_RECAPTCHA_SITE_KEY"),
  isTokenAutoRefreshEnabled: true
});
```

### Debug Mode for Development

```typescript
// Enable debug mode for local development
if (process.env.NODE_ENV === "development") {
  (self as any).FIREBASE_APPCHECK_DEBUG_TOKEN = true;
}
```

### Best Practices

1. **Enforce in production**: Always set `enforceAppCheck: true` for sensitive endpoints
2. **Consume tokens**: Use `consumeAppCheckToken: true` to prevent replay attacks
3. **Gradual rollout**: Monitor App Check metrics before enforcing
4. **Debug tokens**: Use debug tokens for development and CI/CD pipelines
