# nuke-docker

Script de **limpieza total** de Docker en la máquina local.  
Elimina **contenedores**, **imágenes**, **volúmenes**, **redes sin uso** y **cachés** del builder.

> ⚠️ **Peligroso**: este script borra datos en volúmenes y elimina **todo** lo de Docker. Úsalo sólo si sabes lo que haces.

---

## Requisitos

- Bash (Linux, macOS o WSL/WSL2).
- Docker CLI instalado y funcionando.
- Permisos para administrar Docker:
  - Estar en el grupo `docker` **o**
  - Usar `sudo` (p. ej. `sudo nuke-docker -y`).

---

## Instalación

### Opción A — Local (ejecutar desde la carpeta)
```bash
chmod +x nuke-docker.sh
./nuke-docker.sh

### Opción B — Global (disponible en todo el sistema)

sudo install -m 0755 /ruta/a/nuke-docker.sh /usr/local/bin/nuke-docker
# Verifica:
which nuke-docker
nuke-docker -h

Uso

nuke-docker             # Pide confirmación (escribe YES)
nuke-docker -y          # Ejecuta sin pedir confirmación
nuke-docker -h          # Muestra la ayuda
nuke-docker --no-progress  # Ejecuta sin barra de progreso

nuke-docker             # Pide confirmación (escribe YES)
nuke-docker -y          # Ejecuta sin pedir confirmación
nuke-docker -h          # Muestra la ayuda
nuke-docker --no-progress  # Ejecuta sin barra de progreso


Opciones

-y, --yes — Ejecuta sin confirmación.

-h, --help — Muestra ayuda y sale.

--no-progress — Desactiva la barra de progreso.



¿Qué hace?

En este orden:

Elimina contenedores (corriendo y detenidos).

Elimina volúmenes (⚠️ pierdes datos).

Elimina imágenes.

docker network prune -f (redes sin uso).

docker builder prune -a -f (cachés del builder).

docker system prune -a --volumes -f (limpieza general).

Al final muestra un resumen de contenedores, imágenes, volúmenes y redes restantes.

Ejemplos:

# Modo interactivo con barra de progreso
nuke-docker

# Forzar (sin prompt) – ideal para scripts CI
nuke-docker -y

# Sin barra de progreso (útil para logs de CI)
nuke-docker --no-progress


Notas y consejos

Si no estás en el grupo docker, ejecuta con sudo:
sudo nuke-docker -y
Si ves errores de “en uso” al borrar imágenes/redes, el script vuelve a intentar y continúa (usa xargs -r y || true).

WSL2 / Windows:

Asegúrate de que Docker Desktop esté corriendo.

El script se ejecuta dentro de la distro WSL (Ubuntu, Debian, etc.).

Desinstalación
sudo rm -f /usr/local/bin/nuke-docker
