# Development image only until build, extension, upgrade and restore acceptance passes.
# The build stage and runtime use the same PostgreSQL major release and Debian variant.
FROM postgres:18-bookworm AS extensions
ARG AGE_REF=PG18/v1.8.0-rc0
ARG TEXTSEARCH_REF=v1.5.1
ARG PGMQ_REF=v1.13.0
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git make gcc g++ flex bison \
    postgresql-server-dev-18 libreadline-dev libicu-dev \
    && rm -rf /var/lib/apt/lists/*
ENV PG_CONFIG=/usr/lib/postgresql/18/bin/pg_config
RUN git clone --depth 1 --branch "${AGE_REF}" https://github.com/apache/age.git /src/age \
    && make -C /src/age PG_CONFIG="${PG_CONFIG}" -j2 \
    && make -C /src/age PG_CONFIG="${PG_CONFIG}" install
RUN git clone --depth 1 --branch "${TEXTSEARCH_REF}" https://github.com/timescale/pg_textsearch.git /src/pg_textsearch \
    && make -C /src/pg_textsearch PG_CONFIG="${PG_CONFIG}" -j2 \
    && make -C /src/pg_textsearch PG_CONFIG="${PG_CONFIG}" install
RUN git clone --depth 1 --branch "${PGMQ_REF}" https://github.com/pgmq/pgmq.git /src/pgmq \
    && make -C /src/pgmq/pgmq-extension PG_CONFIG="${PG_CONFIG}" \
    && make -C /src/pgmq/pgmq-extension PG_CONFIG="${PG_CONFIG}" install

FROM postgres:18-bookworm
# pg_cron requires the extension binary in the runtime, not only the builder.
RUN apt-get update && apt-get install -y --no-install-recommends postgresql-18-cron \
    && rm -rf /var/lib/apt/lists/*
COPY --from=extensions /usr/lib/postgresql/18/lib/age.so /usr/lib/postgresql/18/lib/
COPY --from=extensions /usr/lib/postgresql/18/lib/pg_textsearch.so /usr/lib/postgresql/18/lib/
# SQL scripts and control files are installed by each upstream PGXS make install.
COPY --from=extensions /usr/share/postgresql/18/extension/ /usr/share/postgresql/18/extension/
COPY init/ /docker-entrypoint-initdb.d/
