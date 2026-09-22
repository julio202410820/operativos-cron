#!/bin/bash

# ==============================
# CONFIGURACIÓN
# ==============================

REPO="$HOME/operativos-cron"
LOG="$HOME/git_backup.log"
LOCK="/tmp/git_backup.lock"

# ==============================
# FUNCIÓN PARA REGISTRAR LOG
# ==============================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"
}

# ==============================
# EVITAR EJECUCIONES SIMULTÁNEAS
# ==============================

exec 200>"$LOCK"

if ! flock -n 200; then
    log "OMITIDO: ya existe otra ejecución del script en curso."
    exit 2
fi

# ==============================
# VALIDAR REPOSITORIO
# ==============================

if [ ! -d "$REPO" ]; then
    log "ERROR: el repositorio no existe: $REPO"
    exit 1
fi

cd "$REPO" || {
    log "ERROR: no se pudo acceder al repositorio."
    exit 1
}

# Comprobar que realmente sea un repositorio Git
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log "ERROR: la carpeta no es un repositorio Git."
    exit 1
fi

# ==============================
# VALIDAR RAMA MAIN
# ==============================

RAMA=$(git branch --show-current)

if [ "$RAMA" != "main" ]; then
    log "ERROR: la rama actual es '$RAMA', se esperaba 'main'."
    exit 1
fi

log "Repositorio y rama validados correctamente: main"

# ==============================
# DETECTAR CAMBIOS
# ==============================

if [ -n "$(git status --porcelain)" ]; then

    log "Se detectaron cambios."

    # ==============================
    # AGREGAR CAMBIOS
    # ==============================

    if ! git add -A; then
        log "ERROR: falló git add."
        exit 1
    fi

    log "Cambios agregados al área de preparación."

    # ==============================
    # COMPROBAR SI REALMENTE HAY CAMBIOS
    # ==============================

    if git diff --cached --quiet; then
        log "No hay cambios para realizar commit."
    else

        # ==============================
        # CREAR COMMIT
        # ==============================

        FECHA=$(date '+%Y-%m-%d %H:%M:%S')
        MENSAJE="Actualización automática - $FECHA"

        if ! git commit -m "$MENSAJE"; then
            log "ERROR: falló la creación del commit."
            exit 1
        fi

        log "Commit creado: $MENSAJE"
    fi

else
    log "No se detectaron cambios nuevos."
fi

# ==============================
# PUSH
# ==============================

if git push; then
    log "PUSH realizado correctamente."
else
    log "ERROR: git push falló."
    exit 1
fi

log "Ejecución finalizada correctamente."
exit 0
