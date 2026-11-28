#!/bin/sh
set -eu
mkdir -p /backup
pgbackrest --stanza=fixture stanza-create
