#!/usr/bin/env python3
"""
Set up Python Cloud Functions project structure.
Usage: python setup_python_functions.py [--path <dir>] [--codebase <name>]

Creates a complete Python functions directory with:
- main.py with example functions (HTTP, Firestore trigger, scheduled)
- requirements.txt with firebase-functions and firebase-admin
- Proper directory structure
"""

import argparse
import os
import sys
import json

REQUIREMENTS = """firebase-functions>=0.5.0
firebase-admin>=6.0.0
google-cloud-firestore>=2.0.0
google-cloud-storage>=2.0.0
"""

MAIN_PY = '''"""Firebase Cloud Functions (Python)"""

from firebase_functions import https_fn, firestore_fn, scheduler_fn, options
from firebase_admin import initialize_app, firestore
from typing import Any

initialize_app()


# ============================================================================
# HTTP Functions
# ============================================================================

@https_fn.on_request()
def hello_world(req: https_fn.Request) -> https_fn.Response:
    """Simple HTTP function."""
    return https_fn.Response("Hello from Firebase!")


@https_fn.on_request(
    cors=options.CorsOptions(
        cors_origins=["*"],
        cors_methods=["GET", "POST"],
    )
)
def api_endpoint(req: https_fn.Request) -> https_fn.Response:
    """HTTP function with CORS enabled."""
    if req.method == "GET":
        return https_fn.Response(json.dumps({"message": "GET request received"}))
    elif req.method == "POST":
        data = req.get_json(silent=True) or {}
        return https_fn.Response(json.dumps({"received": data}))
    return https_fn.Response("Method not allowed", status=405)


# ============================================================================
# Callable Functions
# ============================================================================

@https_fn.on_call()
def process_data(req: https_fn.CallableRequest) -> Any:
    """Callable function with authentication."""
    # Check authentication
    if not req.auth:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="User must be authenticated"
        )
    
    # Validate input
    data = req.data
    if not data or "input" not in data:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Missing required field: input"
        )
    
    # Process and return
    return {
        "success": True,
        "processed": data["input"].upper(),
        "uid": req.auth.uid
    }


# ============================================================================
# Firestore Triggers
# ============================================================================

@firestore_fn.on_document_created(document="users/{userId}")
def on_user_created(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    """Triggered when a new user document is created."""
    if not event.data:
        return
    
    user_data = event.data.to_dict()
    user_id = event.params["userId"]
    print(f"New user created: {user_id}")
    print(f"User data: {user_data}")


@firestore_fn.on_document_updated(document="users/{userId}")
def on_user_updated(
    event: firestore_fn.Event[firestore_fn.Change[firestore_fn.DocumentSnapshot]]
) -> None:
    """Triggered when a user document is updated."""
    if not event.data:
        return
    
    before = event.data.before.to_dict() if event.data.before.exists else {}
    after = event.data.after.to_dict() if event.data.after.exists else {}
    user_id = event.params["userId"]
    
    print(f"User {user_id} updated")
    print(f"Before: {before}")
    print(f"After: {after}")


@firestore_fn.on_document_deleted(document="users/{userId}")
def on_user_deleted(event: firestore_fn.Event[firestore_fn.DocumentSnapshot]) -> None:
    """Triggered when a user document is deleted."""
    user_id = event.params["userId"]
    print(f"User deleted: {user_id}")
    
    # Example: Clean up related data
    db = firestore.client()
    # db.collection("user_data").document(user_id).delete()


# ============================================================================
# Scheduled Functions
# ============================================================================

@scheduler_fn.on_schedule(schedule="every 24 hours")
def daily_cleanup(event: scheduler_fn.ScheduledEvent) -> None:
    """Runs daily to clean up old data."""
    print("Running daily cleanup...")
    
    # Example: Delete documents older than 30 days
    # db = firestore.client()
    # cutoff = datetime.now() - timedelta(days=30)
    # old_docs = db.collection("logs").where("createdAt", "<", cutoff).stream()
    # for doc in old_docs:
    #     doc.reference.delete()


@scheduler_fn.on_schedule(
    schedule="0 9 * * 1",  # Every Monday at 9 AM
    timezone="America/New_York"
)
def weekly_report(event: scheduler_fn.ScheduledEvent) -> None:
    """Runs weekly to generate reports."""
    print("Generating weekly report...")


import json  # noqa: E402 - needed for api_endpoint
'''

FIREBASE_JSON_ENTRY = """{
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "runtime": "nodejs20"
    },
    {
      "source": "PYTHON_DIR",
      "codebase": "CODEBASE_NAME",
      "runtime": "python312"
    }
  ]
}"""


def create_python_functions(path: str, codebase: str) -> None:
    """Create Python functions directory structure."""
    
    # Create directory
    os.makedirs(path, exist_ok=True)
    
    # Create requirements.txt
    req_path = os.path.join(path, "requirements.txt")
    with open(req_path, "w") as f:
        f.write(REQUIREMENTS.strip() + "\n")
    print(f"✅ Created {req_path}")
    
    # Create main.py
    main_path = os.path.join(path, "main.py")
    with open(main_path, "w") as f:
        f.write(MAIN_PY.strip() + "\n")
    print(f"✅ Created {main_path}")
    
    # Create .gitignore
    gitignore_path = os.path.join(path, ".gitignore")
    with open(gitignore_path, "w") as f:
        f.write("venv/\n__pycache__/\n*.pyc\n.env\n")
    print(f"✅ Created {gitignore_path}")
    
    # Print firebase.json config
    config = FIREBASE_JSON_ENTRY.replace("PYTHON_DIR", path).replace("CODEBASE_NAME", codebase)
    
    print(f"""
✅ Python functions directory created at: {path}

📋 Add this to your firebase.json "functions" array:
{config}

📋 Next steps:
   1. Create virtual environment: python -m venv {path}/venv
   2. Activate: source {path}/venv/bin/activate
   3. Install deps: pip install -r {path}/requirements.txt
   4. Update firebase.json with the config above
   5. Deploy: firebase deploy --only functions:{codebase}
""")


def main():
    parser = argparse.ArgumentParser(
        description="Set up Python Cloud Functions project structure"
    )
    parser.add_argument(
        "--path", "-p",
        default="python-functions",
        help="Directory to create (default: python-functions)"
    )
    parser.add_argument(
        "--codebase", "-c",
        default="python",
        help="Codebase name for firebase.json (default: python)"
    )
    
    args = parser.parse_args()
    
    if os.path.exists(args.path) and os.listdir(args.path):
        print(f"⚠️  Directory {args.path} already exists and is not empty")
        response = input("Continue anyway? (y/N) ").strip().lower()
        if response != "y":
            print("Cancelled.")
            sys.exit(0)
    
    create_python_functions(args.path, args.codebase)


if __name__ == "__main__":
    main()
