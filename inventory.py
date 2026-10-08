#!/usr/bin/env python3
import json

inventory = {
    "cli": {
        "hosts": ["cli.au.team"],
        "vars": {
            "ansible_user": "user1.user1",
            "ansible_password": "P@ssw0rd123"
        }
    },
    "_meta": {
        "hostvars": {}
    }
}

print(json.dumps(inventory))