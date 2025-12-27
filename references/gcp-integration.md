# GCP Integration Reference

Firebase-GCP relationship, IAM, monitoring, secrets, and GCP services.

## Contents

- [Firebase and GCP](#firebase-and-gcp)
- [Service Accounts](#service-accounts)
- [IAM Roles](#iam-roles)
- [Secret Manager](#secret-manager)
- [Cloud Logging](#cloud-logging)
- [Cloud Monitoring](#cloud-monitoring)
- [BigQuery Export](#bigquery-export)
- [Other GCP Services](#other-gcp-services)

---

## Firebase and GCP

Firebase projects **are** GCP projects with Firebase services enabled.

**Shared resources:**
- Project ID
- Billing account
- IAM permissions
- Service accounts
- APIs and services
- Cloud Console access

**Access:**
- Firebase Console: console.firebase.google.com
- GCP Console: console.cloud.google.com
- Same project, different views

---

## Service Accounts

### Default Service Accounts

| Service Account | Purpose |
|-----------------|---------|
| `PROJECT_ID@appspot.gserviceaccount.com` | App Engine, Cloud Functions default |
| `firebase-adminsdk-xxxxx@PROJECT_ID.iam.gserviceaccount.com` | Admin SDK operations |
| `PROJECT_NUMBER@cloudbuild.gserviceaccount.com` | Cloud Build |
| `PROJECT_NUMBER-compute@developer.gserviceaccount.com` | Compute Engine default |

### Create Service Account

```bash
# Create
gcloud iam service-accounts create my-service-account \
  --display-name="My Service Account" \
  --project=PROJECT_ID

# Grant roles
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:my-service-account@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/datastore.user"

# Create key (for local development)
gcloud iam service-accounts keys create key.json \
  --iam-account=my-service-account@PROJECT_ID.iam.gserviceaccount.com
```

### Use Service Account in Code

```typescript
// Local development with key file
import { initializeApp, cert } from "firebase-admin/app";

const serviceAccount = require("./key.json");
initializeApp({
  credential: cert(serviceAccount)
});

// In Cloud Functions (automatic)
initializeApp();  // Uses default credentials
```

```python
# Local development
import firebase_admin
from firebase_admin import credentials

cred = credentials.Certificate("key.json")
firebase_admin.initialize_app(cred)

# In Cloud Functions (automatic)
firebase_admin.initialize_app()
```

### Application Default Credentials

```bash
# Set for local development
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"

# Or use gcloud
gcloud auth application-default login
```

---

## IAM Roles

### Firebase-specific Roles

| Role | Description |
|------|-------------|
| `roles/firebase.admin` | Full Firebase access |
| `roles/firebase.viewer` | Read-only Firebase access |
| `roles/firebase.developAdmin` | Deploy and develop |
| `roles/firebase.analyticsViewer` | View Analytics |
| `roles/firebase.growthViewer` | View A/B Testing, Remote Config |
| `roles/firebase.qualityViewer` | View Crashlytics, Performance |

### Cloud Functions Roles

| Role | Description |
|------|-------------|
| `roles/cloudfunctions.admin` | Full functions access |
| `roles/cloudfunctions.developer` | Deploy and update |
| `roles/cloudfunctions.invoker` | Invoke HTTP functions |
| `roles/cloudfunctions.viewer` | View only |

### Firestore Roles

| Role | Description |
|------|-------------|
| `roles/datastore.owner` | Full Firestore access |
| `roles/datastore.user` | Read/write data |
| `roles/datastore.viewer` | Read-only |
| `roles/datastore.indexAdmin` | Manage indexes |

### Storage Roles

| Role | Description |
|------|-------------|
| `roles/storage.admin` | Full Storage access |
| `roles/storage.objectAdmin` | Manage objects |
| `roles/storage.objectCreator` | Create objects |
| `roles/storage.objectViewer` | View objects |

### Grant Roles

```bash
# To user
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:email@example.com" \
  --role="roles/firebase.admin"

# To service account
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/datastore.user"

# View current bindings
gcloud projects get-iam-policy PROJECT_ID
```

---

## Secret Manager

### Via Firebase CLI (Recommended for Functions)

```bash
# Set secret
firebase functions:secrets:set API_KEY

# Get metadata
firebase functions:secrets:get API_KEY

# Access value
firebase functions:secrets:access API_KEY

# List all
firebase functions:secrets:list

# Delete
firebase functions:secrets:destroy API_KEY
```

### Via GCP (Direct)

```bash
# Create secret
echo -n "secret-value" | gcloud secrets create API_KEY --data-file=-

# Add version
echo -n "new-value" | gcloud secrets versions add API_KEY --data-file=-

# Access latest version
gcloud secrets versions access latest --secret=API_KEY

# List secrets
gcloud secrets list

# Delete
gcloud secrets delete API_KEY
```

### Use in Cloud Functions

```typescript
import { defineSecret } from "firebase-functions/params";
import { onRequest } from "firebase-functions/v2/https";

const apiKey = defineSecret("API_KEY");
const dbPassword = defineSecret("DB_PASSWORD");

export const secureEndpoint = onRequest(
  { secrets: [apiKey, dbPassword] },
  (req, res) => {
    const key = apiKey.value();
    const password = dbPassword.value();
    res.json({ status: "ok" });
  }
);
```

### Grant Access to Secret

```bash
# Grant function's service account access
gcloud secrets add-iam-policy-binding API_KEY \
  --member="serviceAccount:PROJECT_ID@appspot.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

---

## Cloud Logging

### View Logs

```bash
# Firebase CLI
firebase functions:log
firebase functions:log --only myFunction
firebase functions:log -n 100

# gcloud
gcloud logging read "resource.type=cloud_function" --limit=50
gcloud logging read "resource.type=cloud_function AND resource.labels.function_name=myFunction"
```

### Structured Logging in Functions

```typescript
import { logger } from "firebase-functions";

export const myFunction = onRequest((req, res) => {
  // Log levels
  logger.debug("Debug info");
  logger.info("Info message");
  logger.warn("Warning");
  logger.error("Error occurred");
  
  // Structured data
  logger.info("Request received", {
    method: req.method,
    path: req.path,
    userId: req.headers["x-user-id"]
  });
  
  res.send("OK");
});
```

### Python Logging

```python
import logging

logging.info("Info message")
logging.warning("Warning")
logging.error("Error", extra={"userId": "123"})
```

### Log-based Metrics

Create metrics from log entries in GCP Console:
1. Logging > Logs-based Metrics
2. Create Metric
3. Define filter (e.g., `severity>=ERROR`)
4. Use in Cloud Monitoring dashboards/alerts

---

## Cloud Monitoring

### View Metrics

**GCP Console:** Monitoring > Metrics Explorer

**Key metrics for Cloud Functions:**
- `cloudfunctions.googleapis.com/function/execution_count`
- `cloudfunctions.googleapis.com/function/execution_times`
- `cloudfunctions.googleapis.com/function/active_instances`
- `cloudfunctions.googleapis.com/function/user_memory_bytes`

**Firestore metrics:**
- `firestore.googleapis.com/document/read_count`
- `firestore.googleapis.com/document/write_count`
- `firestore.googleapis.com/document/delete_count`

### Create Alerts

```bash
# Create notification channel first
gcloud beta monitoring channels create \
  --display-name="Email Alerts" \
  --type=email \
  --channel-labels=email_address=alerts@example.com

# Create alert policy
gcloud alpha monitoring policies create \
  --display-name="High Error Rate" \
  --condition-display-name="Error rate > 5%" \
  --condition-filter='resource.type="cloud_function" AND metric.type="cloudfunctions.googleapis.com/function/execution_count" AND metric.labels.status!="ok"'
```

### Custom Metrics

```typescript
import { Monitoring } from "@google-cloud/monitoring";

const monitoring = new Monitoring.MetricServiceClient();
const projectId = process.env.GCLOUD_PROJECT;

async function writeCustomMetric(value: number) {
  const dataPoint = {
    interval: { endTime: { seconds: Date.now() / 1000 } },
    value: { doubleValue: value }
  };
  
  const timeSeriesData = {
    metric: { type: `custom.googleapis.com/my_metric` },
    resource: { type: "global", labels: { project_id: projectId } },
    points: [dataPoint]
  };
  
  await monitoring.createTimeSeries({
    name: `projects/${projectId}`,
    timeSeries: [timeSeriesData]
  });
}
```

---

## BigQuery Export

### Enable Firebase → BigQuery Export

**Firebase Console:**
1. Project Settings > Integrations
2. BigQuery > Link
3. Select data to export:
   - Analytics
   - Crashlytics
   - Cloud Messaging
   - Performance Monitoring

### Query Firebase Data

```sql
-- Analytics events
SELECT
  event_name,
  COUNT(*) as event_count,
  COUNT(DISTINCT user_pseudo_id) as unique_users
FROM `project_id.analytics_123456789.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20240101' AND '20240131'
GROUP BY event_name
ORDER BY event_count DESC;

-- Crashlytics crashes
SELECT
  issue_id,
  COUNT(*) as crash_count,
  ANY_VALUE(issue_title) as title
FROM `project_id.firebase_crashlytics.package_name_ANDROID`
WHERE event_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY issue_id
ORDER BY crash_count DESC;
```

### Export Firestore to BigQuery

Use Firestore Extension or Cloud Function:

```typescript
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { BigQuery } from "@google-cloud/bigquery";

const bigquery = new BigQuery();

export const syncToBigQuery = onDocumentWritten(
  "orders/{orderId}",
  async (event) => {
    const data = event.data?.after.data();
    if (!data) return;
    
    await bigquery
      .dataset("firebase_sync")
      .table("orders")
      .insert([{
        order_id: event.params.orderId,
        ...data,
        synced_at: new Date().toISOString()
      }]);
  }
);
```

---

## Other GCP Services

### Cloud Tasks (Delayed Execution)

```typescript
import { CloudTasksClient } from "@google-cloud/tasks";

const client = new CloudTasksClient();

async function scheduleTask(payload: object, delaySeconds: number) {
  const project = process.env.GCLOUD_PROJECT!;
  const location = "us-central1";
  const queue = "my-queue";
  
  const task = {
    httpRequest: {
      httpMethod: "POST" as const,
      url: `https://${location}-${project}.cloudfunctions.net/processTask`,
      body: Buffer.from(JSON.stringify(payload)).toString("base64"),
      headers: { "Content-Type": "application/json" }
    },
    scheduleTime: {
      seconds: Math.floor(Date.now() / 1000) + delaySeconds
    }
  };
  
  await client.createTask({
    parent: client.queuePath(project, location, queue),
    task
  });
}
```

### Cloud Pub/Sub

```typescript
import { PubSub } from "@google-cloud/pubsub";

const pubsub = new PubSub();

// Publish message
async function publishMessage(topicName: string, data: object) {
  const topic = pubsub.topic(topicName);
  const messageBuffer = Buffer.from(JSON.stringify(data));
  await topic.publish(messageBuffer);
}

// Subscribe in Cloud Function
import { onMessagePublished } from "firebase-functions/v2/pubsub";

export const handleMessage = onMessagePublished("my-topic", (event) => {
  const data = event.data.message.json;
  console.log("Received:", data);
});
```

### Cloud Scheduler

Managed by Firebase for scheduled functions. View in GCP Console:
- Cloud Scheduler > Jobs

```bash
# List scheduled jobs
gcloud scheduler jobs list

# Manually trigger
gcloud scheduler jobs run my-scheduled-function
```

### Cloud Storage (Direct Access)

```typescript
import { Storage } from "@google-cloud/storage";

const storage = new Storage();

// Upload file
await storage.bucket("my-bucket").upload("local-file.txt", {
  destination: "remote-path/file.txt"
});

// Download file
await storage.bucket("my-bucket")
  .file("remote-path/file.txt")
  .download({ destination: "local-file.txt" });

// Generate signed URL
const [url] = await storage.bucket("my-bucket")
  .file("private-file.txt")
  .getSignedUrl({
    action: "read",
    expires: Date.now() + 15 * 60 * 1000 // 15 minutes
  });
```

### VPC Connector (Private Network)

Connect Cloud Functions to VPC for private resources:

```typescript
import { onRequest } from "firebase-functions/v2/https";

export const privateNetworkFunction = onRequest(
  {
    vpcConnector: "my-vpc-connector",
    vpcConnectorEgressSettings: "ALL_TRAFFIC"
  },
  async (req, res) => {
    // Can now access private IPs
    res.send("Connected to VPC");
  }
);
```

```bash
# Create VPC connector
gcloud compute networks vpc-access connectors create my-vpc-connector \
  --region=us-central1 \
  --network=default \
  --range=10.8.0.0/28
```
