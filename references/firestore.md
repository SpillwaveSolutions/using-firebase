# Firestore Database Reference

Complete reference for Firestore operations, queries, and data modeling.

## Contents

- [Data Model](#data-model)
- [Initialization](#initialization)
- [CRUD Operations](#crud-operations)
- [Queries](#queries)
- [Real-time Listeners](#real-time-listeners)
- [Transactions & Batches](#transactions--batches)
- [Data Modeling Patterns](#data-modeling-patterns)
- [Indexes](#indexes)
- [Offline Persistence](#offline-persistence)

---

## Data Model

Firestore stores data in **documents** organized into **collections**:

```
users (collection)
  └── user123 (document)
        ├── name: "John"           # field
        ├── email: "j@example.com" # field
        ├── address: {             # nested map
        │     city: "NYC",
        │     zip: "10001"
        │   }
        └── tags: ["admin", "dev"] # array
```

**Limits:**
- Document size: 1 MB max
- Document path depth: 100 levels max
- Field name: 1,500 bytes max
- Subcollection nesting: unlimited

## Initialization

### JavaScript/TypeScript (Client SDK)

```typescript
import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
```

### JavaScript/TypeScript (Admin SDK)

```typescript
import { initializeApp, cert } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

initializeApp({ credential: cert(serviceAccount) });
// Or in Cloud Functions: initializeApp();
const db = getFirestore();
```

### Python (Admin SDK)

```python
import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("serviceAccount.json")
firebase_admin.initialize_app(cred)
# Or in Cloud Functions: firebase_admin.initialize_app()
db = firestore.client()
```

---

## CRUD Operations

### Create / Set Document

**JavaScript/TypeScript:**
```typescript
import { doc, setDoc, addDoc, collection } from "firebase/firestore";

// Set with explicit ID
await setDoc(doc(db, "users", "user123"), {
  name: "John",
  email: "john@example.com",
  createdAt: new Date()
});

// Add with auto-generated ID
const docRef = await addDoc(collection(db, "users"), {
  name: "Jane",
  email: "jane@example.com"
});
console.log("New doc ID:", docRef.id);

// Merge with existing document (partial update, creates if missing)
await setDoc(doc(db, "users", "user123"), 
  { lastLogin: new Date() }, 
  { merge: true }
);
```

**Python:**
```python
# Set with explicit ID
db.collection("users").document("user123").set({
    "name": "John",
    "email": "john@example.com",
    "createdAt": firestore.SERVER_TIMESTAMP
})

# Add with auto-generated ID
update_time, doc_ref = db.collection("users").add({
    "name": "Jane",
    "email": "jane@example.com"
})

# Merge
db.collection("users").document("user123").set(
    {"lastLogin": firestore.SERVER_TIMESTAMP}, 
    merge=True
)
```

### Read Document

**JavaScript/TypeScript:**
```typescript
import { doc, getDoc, collection, getDocs } from "firebase/firestore";

// Single document
const docSnap = await getDoc(doc(db, "users", "user123"));
if (docSnap.exists()) {
  console.log("Data:", docSnap.data());
  console.log("ID:", docSnap.id);
} else {
  console.log("Document not found");
}

// All documents in collection
const querySnapshot = await getDocs(collection(db, "users"));
querySnapshot.forEach((doc) => {
  console.log(doc.id, "=>", doc.data());
});
```

**Python:**
```python
# Single document
doc = db.collection("users").document("user123").get()
if doc.exists:
    print(f"Data: {doc.to_dict()}")
    print(f"ID: {doc.id}")

# All documents
docs = db.collection("users").stream()
for doc in docs:
    print(f"{doc.id} => {doc.to_dict()}")
```

### Update Document

**JavaScript/TypeScript:**
```typescript
import { doc, updateDoc, arrayUnion, arrayRemove, increment, deleteField, serverTimestamp } from "firebase/firestore";

const userRef = doc(db, "users", "user123");

// Simple update
await updateDoc(userRef, {
  name: "John Doe",
  "address.city": "Los Angeles"  // Nested field (dot notation)
});

// Special operations
await updateDoc(userRef, {
  tags: arrayUnion("newTag"),        // Add to array (if not exists)
  oldTags: arrayRemove("deprecated"), // Remove from array
  loginCount: increment(1),           // Atomic increment
  updatedAt: serverTimestamp(),       // Server timestamp
  deprecatedField: deleteField()      // Delete field
});
```

**Python:**
```python
from google.cloud.firestore_v1 import ArrayUnion, ArrayRemove, Increment, DELETE_FIELD

user_ref = db.collection("users").document("user123")

# Simple update
user_ref.update({
    "name": "John Doe",
    "address.city": "Los Angeles"
})

# Special operations
user_ref.update({
    "tags": ArrayUnion(["newTag"]),
    "oldTags": ArrayRemove(["deprecated"]),
    "loginCount": Increment(1),
    "updatedAt": firestore.SERVER_TIMESTAMP,
    "deprecatedField": DELETE_FIELD
})
```

### Delete Document

**JavaScript/TypeScript:**
```typescript
import { doc, deleteDoc } from "firebase/firestore";

await deleteDoc(doc(db, "users", "user123"));

// Note: Deleting a document does NOT delete subcollections
// Delete subcollections recursively with a Cloud Function or batch
```

**Python:**
```python
db.collection("users").document("user123").delete()
```

---

## Queries

### Query Operators

| Operator | Description |
|----------|-------------|
| `==` | Equal to |
| `!=` | Not equal to |
| `<` | Less than |
| `<=` | Less than or equal |
| `>` | Greater than |
| `>=` | Greater than or equal |
| `array-contains` | Array contains value |
| `array-contains-any` | Array contains any of values |
| `in` | Field equals any of values |
| `not-in` | Field doesn't equal any values |

### Basic Queries

**JavaScript/TypeScript:**
```typescript
import { collection, query, where, orderBy, limit, getDocs, startAfter, endBefore } from "firebase/firestore";

const usersRef = collection(db, "users");

// Simple equality
const q1 = query(usersRef, where("status", "==", "active"));

// Comparison
const q2 = query(usersRef, where("age", ">=", 18));

// Multiple conditions (AND)
const q3 = query(usersRef, 
  where("status", "==", "active"),
  where("age", ">=", 18)
);

// Ordering and limiting
const q4 = query(usersRef,
  where("status", "==", "active"),
  orderBy("createdAt", "desc"),
  limit(10)
);

// Execute query
const snapshot = await getDocs(q4);
snapshot.forEach((doc) => console.log(doc.id, doc.data()));
```

**Python:**
```python
from google.cloud.firestore_v1 import FieldFilter, Query

users_ref = db.collection("users")

# Simple equality
docs = users_ref.where(filter=FieldFilter("status", "==", "active")).stream()

# Multiple conditions
docs = (users_ref
    .where(filter=FieldFilter("status", "==", "active"))
    .where(filter=FieldFilter("age", ">=", 18))
    .order_by("createdAt", direction=Query.DESCENDING)
    .limit(10)
    .stream())

for doc in docs:
    print(f"{doc.id} => {doc.to_dict()}")
```

### Array Queries

```typescript
// Array contains single value
const q = query(usersRef, where("tags", "array-contains", "admin"));

// Array contains any of values (max 30 values)
const q = query(usersRef, where("tags", "array-contains-any", ["admin", "moderator"]));
```

### IN Queries

```typescript
// Field in list (max 30 values)
const q = query(usersRef, where("status", "in", ["active", "pending"]));

// Field not in list
const q = query(usersRef, where("status", "not-in", ["banned", "deleted"]));
```

### OR Queries

```typescript
import { or, and } from "firebase/firestore";

// OR conditions
const q = query(usersRef, 
  or(
    where("status", "==", "active"),
    where("role", "==", "admin")
  )
);

// Complex: (status=active AND age>=18) OR (role=admin)
const q = query(usersRef,
  or(
    and(where("status", "==", "active"), where("age", ">=", 18)),
    where("role", "==", "admin")
  )
);
```

### Collection Group Queries

Query across all subcollections with the same name:

```typescript
import { collectionGroup, query, where, getDocs } from "firebase/firestore";

// Query all "comments" subcollections across all documents
const q = query(
  collectionGroup(db, "comments"),
  where("author", "==", "user123")
);

const snapshot = await getDocs(q);
```

**Requires index:** Collection group queries require a composite index with collection group scope.

### Pagination with Cursors

```typescript
import { query, orderBy, limit, startAfter, getDocs } from "firebase/firestore";

// First page
const first = query(usersRef, orderBy("name"), limit(25));
const firstSnapshot = await getDocs(first);
const lastDoc = firstSnapshot.docs[firstSnapshot.docs.length - 1];

// Next page
const next = query(usersRef, 
  orderBy("name"), 
  startAfter(lastDoc),  // Start after last document
  limit(25)
);
const nextSnapshot = await getDocs(next);

// Other cursor functions:
// startAt(doc)    - Start at document (inclusive)
// startAfter(doc) - Start after document (exclusive)
// endAt(doc)      - End at document (inclusive)
// endBefore(doc)  - End before document (exclusive)
```

---

## Real-time Listeners

### Document Listener

**JavaScript/TypeScript:**
```typescript
import { doc, onSnapshot } from "firebase/firestore";

const unsubscribe = onSnapshot(doc(db, "users", "user123"), (doc) => {
  if (doc.exists()) {
    console.log("Current data:", doc.data());
  }
});

// Stop listening
unsubscribe();
```

### Collection/Query Listener

```typescript
import { collection, query, where, onSnapshot } from "firebase/firestore";

const q = query(collection(db, "users"), where("status", "==", "active"));

const unsubscribe = onSnapshot(q, (snapshot) => {
  // Process changes
  snapshot.docChanges().forEach((change) => {
    if (change.type === "added") {
      console.log("New:", change.doc.id, change.doc.data());
    }
    if (change.type === "modified") {
      console.log("Modified:", change.doc.id, change.doc.data());
    }
    if (change.type === "removed") {
      console.log("Removed:", change.doc.id);
    }
  });
  
  // Or get all current docs
  snapshot.forEach((doc) => console.log(doc.id, doc.data()));
});
```

### Error Handling

```typescript
const unsubscribe = onSnapshot(
  doc(db, "users", "user123"),
  (doc) => { /* handle data */ },
  (error) => { console.error("Listen error:", error); }
);
```

**Python:**
```python
def on_snapshot(doc_snapshot, changes, read_time):
    for doc in doc_snapshot:
        print(f"Received: {doc.to_dict()}")

doc_watch = db.collection("users").document("user123").on_snapshot(on_snapshot)

# Stop listening
doc_watch.unsubscribe()
```

---

## Transactions & Batches

### Transactions

Atomic read-then-write operations. All reads must come before writes.

**JavaScript/TypeScript:**
```typescript
import { runTransaction, doc } from "firebase/firestore";

try {
  await runTransaction(db, async (transaction) => {
    const userRef = doc(db, "users", "user123");
    const userDoc = await transaction.get(userRef);
    
    if (!userDoc.exists()) {
      throw "Document does not exist!";
    }
    
    const newBalance = userDoc.data().balance + 100;
    transaction.update(userRef, { balance: newBalance });
  });
  console.log("Transaction succeeded");
} catch (e) {
  console.error("Transaction failed:", e);
}
```

**Python:**
```python
from google.cloud.firestore_v1 import transactional

@transactional
def update_balance(transaction, user_ref, amount):
    snapshot = user_ref.get(transaction=transaction)
    new_balance = snapshot.get("balance") + amount
    transaction.update(user_ref, {"balance": new_balance})

transaction = db.transaction()
user_ref = db.collection("users").document("user123")
update_balance(transaction, user_ref, 100)
```

### Batched Writes

Multiple write operations as single atomic unit (no reads).

**JavaScript/TypeScript:**
```typescript
import { writeBatch, doc } from "firebase/firestore";

const batch = writeBatch(db);

// Add operations
batch.set(doc(db, "users", "user1"), { name: "User 1" });
batch.update(doc(db, "users", "user2"), { status: "active" });
batch.delete(doc(db, "users", "user3"));

// Commit all at once
await batch.commit();
```

**Python:**
```python
batch = db.batch()

batch.set(db.collection("users").document("user1"), {"name": "User 1"})
batch.update(db.collection("users").document("user2"), {"status": "active"})
batch.delete(db.collection("users").document("user3"))

batch.commit()
```

**Limits:**
- Max 500 operations per batch/transaction
- Transactions retry up to 5 times on contention
- Transactions require online connectivity

---

## Data Modeling Patterns

### Embedding vs References

**Embed (denormalize)** when:
- Data is read together frequently
- Embedded data rarely changes
- You want single-read performance

```javascript
// Embedded author info
{
  title: "My Post",
  content: "...",
  author: {           // Embedded
    id: "user123",
    name: "John",
    avatar: "url..."
  }
}
```

**Reference** when:
- Data changes frequently
- Many-to-many relationships
- Data is large or unbounded

```javascript
// Reference only
{
  title: "My Post",
  content: "...",
  authorId: "user123"  // Reference - fetch author separately
}
```

### Subcollections vs Root Collections

**Subcollections** for:
- Parent-child relationships
- Querying within a parent context
- Natural hierarchies

```
posts/{postId}/comments/{commentId}
users/{userId}/orders/{orderId}
```

**Root collections** for:
- Cross-parent queries
- Many-to-many relationships
- Independent entities

```
comments (with postId field)
orders (with userId field)
```

### Aggregations

Firestore doesn't support aggregation queries. Options:

1. **Maintain counters** (recommended for counts):
```typescript
// In transaction or Cloud Function
await updateDoc(doc(db, "stats", "global"), {
  userCount: increment(1)
});
```

2. **count() for simple counts**:
```typescript
import { getCountFromServer, collection, query, where } from "firebase/firestore";

const q = query(collection(db, "users"), where("active", "==", true));
const snapshot = await getCountFromServer(q);
console.log("Count:", snapshot.data().count);
```

3. **Distributed counters** for high-write scenarios

---

## Indexes

### Single-field Indexes

Automatically created for every field. Enable:
- Simple equality/comparison queries
- Ordering by single field

### Composite Indexes

Required for queries with multiple fields or collection groups.

**firestore.indexes.json:**
```json
{
  "indexes": [
    {
      "collectionGroup": "posts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "comments",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "author", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": [
    {
      "collectionGroup": "posts",
      "fieldPath": "content",
      "indexes": []
    }
  ]
}
```

Deploy: `firebase deploy --only firestore:indexes`

**Tip:** Run query, error message includes link to create required index automatically.

---

## Offline Persistence

### Enable (Web)

```typescript
import { enableIndexedDbPersistence, getFirestore } from "firebase/firestore";

const db = getFirestore();
await enableIndexedDbPersistence(db);
// Now queries work offline
```

### Enable (Mobile)

Enabled by default on iOS/Android.

### Check Pending Writes

```typescript
import { onSnapshot } from "firebase/firestore";

onSnapshot(doc(db, "users", "user123"), (doc) => {
  const source = doc.metadata.hasPendingWrites ? "Local" : "Server";
  console.log(source, "data:", doc.data());
});
```

### Wait for Server Sync

```typescript
import { waitForPendingWrites } from "firebase/firestore";

await waitForPendingWrites(db);
console.log("All pending writes synced to server");
```
