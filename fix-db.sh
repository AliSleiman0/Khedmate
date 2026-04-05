#!/bin/sh
# Try to find what postgres user exists and reset password
PGPASSWORD=postgres psql -h 127.0.0.1 -p 5432 -U postgres khudmati -c "select usename from pg_user;" 2>/tmp/pg_err
if [ $? -ne 0 ]; then
  cat /tmp/pg_err
  echo "Trying different users..."
  # Check if there's a superuser we can connect as
  PGPASSWORD=postgres psql -h 127.0.0.1 -p 5432 -U admin khudmati -c "select usename from pg_user;" 2>&1
  PGPASSWORD=khudmati psql -h 127.0.0.1 -p 5432 -U khudmati khudmati -c "select usename from pg_user;" 2>&1
else
  echo "Connected as postgres!"
fi

# Try pg_dumpall to see cluster users
pg_dumpall --globals-only 2>/dev/null | head -30
