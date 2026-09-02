#! /bin/sh
# Optional: -v ON_ERROR_ROLLBACK=1, this active rollback on error performs the same as
# passive rollback when the connection is about to close with a open transaction.
psql -f - -d exercises -v ON_ERROR_STOP=1 <<EOF > psql.log
BEGIN;
\i $1
ROLLBACK;
EOF
