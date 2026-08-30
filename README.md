# PosgreSQL Exercises
This repository is meant for soruce controll of the exercises for PostgreSQL personally.

## Prepare PostgreSQL
```bash
sudo pacman -S postgresql
su - postgres -c "initdb ~/data"
sudo systemctl enable postgresql 
sudo systemctl start postgresql 
su postgres -c "pg_ctl status -D /var/lib/postgres/data"
su - postgres -c "initdb ~/data"
su - postgres -c "craeteuser -s $(whoami) rabbit"
createdb rabbit
```

## Prepare the pgexercises

```bash
curl -L https://pgexercises.com/dbfiles/clubdata.sql | psql
```
