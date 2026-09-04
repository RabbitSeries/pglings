#! /bin/sh
# Options: -v ON_ERROR_ROLLBACK=off, which is off by default, this is counter intuitive,
# it should be called ON_ERROR_CONTINUE, when set to 'off' the connection will exit
# and a rollback to some implicit savepoint is performed.
# Options: -1, --single-transaction, the entire connection will be wrapped into a
# BEGIN; COMMIT; clause.
# Options: -v ON_ERROR_STOP=1
psql -f $1 -d exercises -v ON_ERROR_STOP=1 | tee psql.log
