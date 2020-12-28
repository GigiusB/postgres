The docker-entrypoint is modified in order to append the content of a file 
`docker-entrypoint-initdb.d/pg_hba.conf`
to
`$PGDATA/pg_hba.conf`