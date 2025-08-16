#!/usr/bin/env bash
# nuke-docker.sh — Borra TODO lo relacionado a Docker en esta máquina.
#   ⚠️  Esto elimina contenedores, imágenes, redes sin uso, volúmenes y cachés .
#        "github.com/Ltomxd".
# Uso:
#   nuke-docker.sh           # pide confirmación
#   nuke-docker.sh -y        # sin confirmar (forzar)
#   nuke-docker.sh -h        # ayuda
#   nuke-docker.sh --no-progress  # sin barra de progreso
#
# Requiere: docker CLI
set -euo pipefail

VERSION="1.2.0"

FORCE=false
NO_PROGRESS=false

usage() {
  cat <<'EOF'
Uso:
  nuke-docker [-y|--yes] [-h|--help] [--no-progress]

Opciones:
  -y, --yes         Ejecuta sin pedir confirmación.
  -h, --help        Muestra esta ayuda y sale.
  --no-progress     Desactiva la barra de progreso.

Qué hace (en orden):
  1) Eliminar contenedores (corriendo y detenidos)
  2) Eliminar volúmenes (⚠️ pierde datos)
  3) Eliminar imágenes
  4) Prune de redes sin uso
  5) Limpiar caché del builder
  6) Limpieza general (system prune con --volumes)

Ejemplos:
  nuke-docker
  nuke-docker -y
  nuke-docker --no-progress
EOF
}

# Colores
bold()  { printf "\033[1m%s\033[0m\n" "$*"; }
info()  { printf "\033[36m%s\033[0m\n" "$*"; }   # cian
warn()  { printf "\033[33m%s\033[0m\n" "$*"; }   # amarillo
good()  { printf "\033[32m%s\033[0m\n" "$*"; }   # verde

# Parseo simple de argumentos
while [[ "${1:-}" != "" ]]; do
  case "$1" in
    -y|--yes)        FORCE=true ;;
    -h|--help)       usage; exit 0 ;;
    --no-progress)   NO_PROGRESS=true ;;
    *) echo "Opción no válida: $1"; usage; exit 2 ;;
  esac
  shift
done

# Comprobación de Docker
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker no está instalado o no está en el PATH."
  exit 1
fi

# Barra de progreso (por pasos), sólo si NO_PROGRESS=false y salida a TTY
TOTAL_STEPS=6
CURRENT_STEP=0
IS_TTY=0
if [[ -t 1 && "$NO_PROGRESS" = false ]]; then
  IS_TTY=1
fi

draw_progress() {
  [[ "$IS_TTY" -eq 1 ]] || return 0
  local w=40
  local pct=$(( CURRENT_STEP * 100 / TOTAL_STEPS ))
  local filled=$(( w * pct / 100 ))
  local empty=$(( w - filled ))
  printf "\r["
  printf "%0.s#" $(seq 1 $filled)
  printf "%0.s." $(seq 1 $empty)
  printf "] %3d%%  " "$pct"
}

finish_progress() {
  [[ "$IS_TTY" -eq 1 ]] || return 0
  draw_progress
  printf "\n"
}

run_step() {
  local title="$1"
  shift
  bold "$title"
  # Ejecutar el comando (si falla, salir por set -e)
  # Para evitar ruido cuando no hay nada que borrar, usamos -r en xargs.
  "$@"
  CURRENT_STEP=$((CURRENT_STEP + 1))
  draw_progress
  printf "\n"
}

warn "⚠️  Esto ELIMINARÁ contenedores, imágenes, volúmenes y cachés de Docker."
warn "⚠️  Perderás datos guardados en volúmenes."
info  "Versión del script: $VERSION"
if ! $FORCE; then
  read -r -p "Escribe YES para continuar: " ans
  [[ "$ans" == "YES" ]] || { echo "Cancelado."; exit 0; }
fi

# Pasos
draw_progress

run_step "1) Eliminando contenedores (corriendo y detenidos)…" \
  bash -c 'docker ps -aq | xargs -r docker rm -f; true'

run_step "2) Eliminando volúmenes (⚠️ datos)…" \
  bash -c 'docker volume ls -q | xargs -r docker volume rm; true'

run_step "3) Eliminando imágenes…" \
  bash -c 'docker images -aq | xargs -r docker rmi -f; true'

run_step "4) Prune de redes sin uso…" \
  bash -c 'docker network prune -f || true'

run_step "5) Limpiando caché del builder…" \
  bash -c 'docker builder prune -a -f || true'

run_step "6) Limpieza general de recursos colgantes…" \
  bash -c 'docker system prune -a --volumes -f || true'

finish_progress

good "✅ Hecho."
echo "Estado actual:"
echo "  Contenedores: $(docker ps -aq | wc -l)"
echo "  Imágenes:     $(docker images -aq | wc -l)"
echo "  Volúmenes:    $(docker volume ls -q | wc -l)"
echo "  Redes:        $(docker network ls -q | wc -l)  (deberían quedar 'bridge', 'host' y 'none')"
