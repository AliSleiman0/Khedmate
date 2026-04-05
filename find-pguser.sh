#!/bin/sh
set -e

echo "=== Checking postgres roles ==="
# Trust auth is configured, try various usernames
for user in postgres root admin khudmati superadmin; do
  result=$(psql -h 127.0.0.1 -U "$user" postgres -c "SELECT rolname, rolsuper FROM pg_roles ORDER BY rolsuper DESC LIMIT 10;" 2>&1)
  echo "User $user: $result"
  if echo "$result" | grep -q "rolname"; then
    echo "SUCCESS: Connected as $user"
    break
  fi
done

# Also try local socket
echo "=== Trying local socket ==="
psql -U root postgres -c "SELECT rolname FROM pg_roles LIMIT 5;" 2>&1 || true
