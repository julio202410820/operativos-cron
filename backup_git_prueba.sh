#!/bin/bash

LOCK="/tmp/git_backup.lock"

exec 200>"$LOCK"

if ! flock -n 200; then
    echo "OMITIDO: ya existe otra ejecución del script en curso."
    exit 2
fi

echo "Ejecución en curso..."
sleep 20
echo "Ejecución terminada."
