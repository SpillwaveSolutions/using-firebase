# Firebase Authentication Reference

Authentication setup, providers, and server-side integration.

## Contents

- [Client Setup](#client-setup)
- [Authentication Providers](#authentication-providers)
- [Server-side Verification](#server-side-verification)
- [Custom Claims](#custom-claims)
- [Custom Tokens](#custom-tokens)
- [User Management](#user-management)

---

## Client Setup

### Web (Modular SDK)

```typescript
import { initializeApp } from "firebase/app";
import { 
  getAuth, 
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut,
  onAuthStateChanged
} from "firebase/auth";

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

// Listen for auth state changes
onAuthStateChanged(auth, (user) => {
  if (user) {
    console.log("Signed in:", user.uid, user.email);
  } else {
    console.log("Signed out");
  }
});
```

### Connect to Emulator

```typescript
import { connectAuthEmulator } from "firebase/auth";

if (location.hostname === "localhost") {
  connectAuthEmulator(auth, "http://127.0.0.1:9099");
}
```

---

## Authentication Providers

### Email/Password

```typescript
import { 
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  sendPasswordResetEmail,
  sendEmailVerification,
  updatePassword
} from "firebase/auth";

// Sign up
const userCredential = await createUserWithEmailAndPassword(auth, email, password);
const user = userCredential.user;

// Sign in
await signInWithEmailAndPassword(auth, email, password);

// Password reset
await sendPasswordResetEmail(auth, email);

// Email verification
await sendEmailVerification(auth.currentUser);

// Update password (requires recent sign-in)
await updatePassword(auth.currentUser, newPassword);
```

### Google Sign-in

```typescript
import { 
  GoogleAuthProvider, 
  signInWithPopup,
  signInWithRedirect,
  getRedirectResult
} from "firebase/auth";

const provider = new GoogleAuthProvider();
provider.addScope("https://www.googleapis.com/auth/contacts.readonly");

// Popup (desktop)
const result = await signInWithPopup(auth, provider);
const credential = GoogleAuthProvider.credentialFromResult(result);
const token = credential?.accessToken;
const user = result.user;

// Redirect (mobile-friendly)
await signInWithRedirect(auth, provider);
// On page load:
const result = await getRedirectResult(auth);
```

### Phone Authentication

```typescript
import { 
  RecaptchaVerifier,
  signInWithPhoneNumber
} from "firebase/auth";

// Setup reCAPTCHA
const recaptchaVerifier = new RecaptchaVerifier(auth, "recaptcha-container", {
  size: "invisible",
  callback: (response) => console.log("reCAPTCHA solved")
});

// Send verification code
const confirmationResult = await signInWithPhoneNumber(
  auth, 
  "+1234567890", 
  recaptchaVerifier
);

// Verify code
const credential = await confirmationResult.confirm(verificationCode);
const user = credential.user;
```

### Anonymous Sign-in

```typescript
import { signInAnonymously } from "firebase/auth";

const userCredential = await signInAnonymously(auth);
// User is now signed in anonymously
// user.isAnonymous === true
```

### Link Multiple Providers

```typescript
import { linkWithPopup, GoogleAuthProvider } from "firebase/auth";

// Link anonymous account to Google
const provider = new GoogleAuthProvider();
const result = await linkWithPopup(auth.currentUser, provider);
```

### Sign Out

```typescript
import { signOut } from "firebase/auth";

await signOut(auth);
```

---

## Server-side Verification

### Verify ID Token

**TypeScript (Admin SDK):**
```typescript
import { getAuth } from "firebase-admin/auth";

async function verifyToken(idToken: string) {
  try {
    const decodedToken = await getAuth().verifyIdToken(idToken);
    const uid = decodedToken.uid;
    const email = decodedToken.email;
    const emailVerified = decodedToken.email_verified;
    const customClaims = decodedToken;  // Includes custom claims
    
    return decodedToken;
  } catch (error) {
    console.error("Token verification failed:", error);
    throw error;
  }
}
```

**Python:**
```python
from firebase_admin import auth

def verify_token(id_token: str):
    try:
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token["uid"]
        email = decoded_token.get("email")
        return decoded_token
    except auth.InvalidIdTokenError:
        raise Exception("Invalid token")
    except auth.ExpiredIdTokenError:
        raise Exception("Token expired")
```

### In Cloud Functions (Callable)

```typescript
import { onCall, HttpsError } from "firebase-functions/v2/https";

export const secureFunction = onCall(async (request) => {
  // Auth is automatically verified for callable functions
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in");
  }
  
  const uid = request.auth.uid;
  const email = request.auth.token.email;
  const isAdmin = request.auth.token.admin === true;
  
  return { uid, email, isAdmin };
});
```

### In HTTP Functions

```typescript
import { onRequest } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";

export const secureApi = onRequest(async (req, res) => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader?.startsWith("Bearer ")) {
    res.status(401).json({ error: "Missing authorization header" });
    return;
  }
  
  const idToken = authHeader.split("Bearer ")[1];
  
  try {
    const decodedToken = await getAuth().verifyIdToken(idToken);
    // Token is valid
    res.json({ uid: decodedToken.uid });
  } catch (error) {
    res.status(401).json({ error: "Invalid token" });
  }
});
```

### Get ID Token (Client)

```typescript
import { getIdToken } from "firebase/auth";

// Get token for API calls
const idToken = await getIdToken(auth.currentUser);

// Force refresh
const freshToken = await getIdToken(auth.currentUser, true);

// Use in API call
const response = await fetch("/api/secure", {
  headers: {
    Authorization: `Bearer ${idToken}`
  }
});
```

---

## Custom Claims

Custom claims add role/permission data to tokens.

### Set Claims (Server-side)

```typescript
import { getAuth } from "firebase-admin/auth";

// Set claims
await getAuth().setCustomUserClaims(uid, {
  admin: true,
  role: "editor",
  accessLevel: 5,
  permissions: ["read", "write", "delete"]
});

// Get user with claims
const user = await getAuth().getUser(uid);
console.log(user.customClaims);  // { admin: true, role: "editor", ... }
```

**Python:**
```python
from firebase_admin import auth

# Set claims
auth.set_custom_user_claims(uid, {
    "admin": True,
    "role": "editor",
    "accessLevel": 5
})

# Get user
user = auth.get_user(uid)
print(user.custom_claims)
```

### Access Claims (Client)

```typescript
import { getIdTokenResult } from "firebase/auth";

const tokenResult = await getIdTokenResult(auth.currentUser);
const claims = tokenResult.claims;

if (claims.admin === true) {
  console.log("User is admin");
}

// Force refresh to get updated claims
const freshResult = await getIdTokenResult(auth.currentUser, true);
```

### Claims in Security Rules

```javascript
// Firestore
match /admin/{document=**} {
  allow read, write: if request.auth.token.admin == true;
}

match /content/{docId} {
  allow write: if request.auth.token.role == "editor";
}

// Storage
match /sensitive/{allPaths=**} {
  allow read: if request.auth.token.accessLevel >= 5;
}
```

### Claim Limits

- Max 1000 bytes total for all claims
- Reserved claims: `acr`, `amr`, `at_hash`, `aud`, `auth_time`, `azp`, `cnf`, `c_hash`, `exp`, `firebase`, `iat`, `iss`, `jti`, `nbf`, `nonce`, `sub`

---

## Custom Tokens

Create tokens for external auth systems or service-to-service auth.

### Create Custom Token

```typescript
import { getAuth } from "firebase-admin/auth";

// Simple token
const customToken = await getAuth().createCustomToken(uid);

// With additional claims
const customToken = await getAuth().createCustomToken(uid, {
  premiumAccount: true,
  subscriptionLevel: "gold"
});
```

**Python:**
```python
from firebase_admin import auth

# Simple token
custom_token = auth.create_custom_token(uid)

# With claims
custom_token = auth.create_custom_token(uid, {
    "premiumAccount": True
})
```

### Sign In with Custom Token (Client)

```typescript
import { signInWithCustomToken } from "firebase/auth";

const userCredential = await signInWithCustomToken(auth, customToken);
const user = userCredential.user;
```

---

## User Management

### Get User

```typescript
import { getAuth } from "firebase-admin/auth";

// By UID
const user = await getAuth().getUser(uid);

// By email
const user = await getAuth().getUserByEmail(email);

// By phone
const user = await getAuth().getUserByPhoneNumber(phoneNumber);

// Multiple users
const result = await getAuth().getUsers([
  { uid: "uid1" },
  { email: "user@example.com" },
  { phoneNumber: "+1234567890" }
]);
```

### Create User

```typescript
const user = await getAuth().createUser({
  email: "user@example.com",
  emailVerified: true,
  password: "secretPassword",
  displayName: "John Doe",
  photoURL: "http://example.com/photo.jpg",
  disabled: false
});
```

### Update User

```typescript
await getAuth().updateUser(uid, {
  email: "newemail@example.com",
  displayName: "New Name",
  password: "newPassword",
  emailVerified: true,
  disabled: false
});
```

### Delete User

```typescript
await getAuth().deleteUser(uid);

// Delete multiple
await getAuth().deleteUsers([uid1, uid2, uid3]);
```

### List Users

```typescript
// List all users (paginated)
const listUsersResult = await getAuth().listUsers(1000);

listUsersResult.users.forEach((user) => {
  console.log(user.uid, user.email);
});

// Paginate
if (listUsersResult.pageToken) {
  const nextPage = await getAuth().listUsers(1000, listUsersResult.pageToken);
}
```

### Revoke Refresh Tokens

```typescript
// Force sign out everywhere
await getAuth().revokeRefreshTokens(uid);

// User must reauthenticate
```

**Python:**
```python
from firebase_admin import auth

# Get user
user = auth.get_user(uid)
user = auth.get_user_by_email(email)

# Create user
user = auth.create_user(
    email="user@example.com",
    password="secretPassword",
    display_name="John Doe"
)

# Update user
auth.update_user(uid, email="new@example.com")

# Delete user
auth.delete_user(uid)

# List users
for user in auth.list_users().iterate_all():
    print(user.uid, user.email)
```
