ARG POSTGRES_BASE=postgres:18-bookworm@sha256:e742a2668255221388004f3a42b6150a2103f5054ab3a4a93ae9e4f01e551c35
FROM ${POSTGRES_BASE}
ARG PGBACKREST_VERSION
RUN test -n "$PGBACKREST_VERSION" && apt-get update \
    && apt-get install -y --no-install-recommends "pgbackrest=$PGBACKREST_VERSION" \
    && rm -rf /var/lib/apt/lists/*
COPY pgbackrest.conf /etc/pgbackrest/pgbackrest.conf
COPY prepare.sh /docker-entrypoint-initdb.d/10-backrest.sh
RUN chmod 755 /docker-entrypoint-initdb.d/10-backrest.sh
