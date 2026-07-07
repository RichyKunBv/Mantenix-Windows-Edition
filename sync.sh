#!/bin/bash

set -euo pipefail

# es para hacer una mini sincronizacion, realmente ignorenlo ya que es algo mas
# para mi que para ustedes, nada mas para mas agilidad
# El script es solo para Linux y MacOS, no es compatible con Windows.

nombre="Mantenix-Windows-Edition"
repo_url="https://github.com/RichyKunBv/$nombre.git"
repos_base="$HOME/Repos"
old_location="$HOME/$nombre"
ubicacion=""

ensure_repos_dir() {
    if [ ! -d "$repos_base" ]; then
        echo "Creando carpeta predeterminada de repositorios en $repos_base..."
        mkdir -p "$repos_base"
    fi
}

detect_repository_location() {
    if [ -d "$repos_base/$nombre/.git" ]; then
        ubicacion="$repos_base/$nombre"
    elif [ -d "$old_location/.git" ]; then
        ensure_repos_dir

        if [ -e "$repos_base/$nombre" ]; then
            echo "Existe un repositorio en $old_location y también en $repos_base/$nombre."
            echo "Por favor mueve manualmente el contenido o elimina uno de ellos."
            exit 1
        fi

        echo "Moviendo repositorio existente de $old_location a $repos_base/$nombre..."
        mv "$old_location" "$repos_base/"
        ubicacion="$repos_base/$nombre"
    else
        ubicacion="$repos_base/$nombre"
    fi
}

detect_repository_location

if [ -d "$ubicacion" ]; then
    cd "$ubicacion"
fi

descargar() {
    echo "Obteniendo últimos cambios del repositorio..."

    if git pull origin main --rebase; then
        echo "Actualización exitosa."
    else
        echo "Error al obtener los cambios. Revisa tu conexión o posibles conflictos."
    fi
}

publicar() {
    if [ -z "$(git status --porcelain)" ]; then
        echo "No hay cambios para publicar. Ya está actualizado."
        return
    fi

    git add .
    read -p "   >> Introduce el mensaje del commit: " mensaje

    if [ -z "$mensaje" ]; then
        echo "El mensaje no puede estar vacío. Cancelando publicación..."
        return
    fi

    git commit -m "$mensaje"

    git pull origin main --rebase

    if git push origin main; then
        echo "Publicación exitosa."
    else
        echo "Error al publicar. Revisa el mensaje de error y vuelve a intentarlo."
        return
    fi
}

configurar() {
    clear
    echo "=== Clonar y Configurar Entorno de $nombre ==="
    ensure_repos_dir

    if [ ! -d "$ubicacion/.git" ]; then
        echo -e "\nDescargando el código en $repos_base..."
        cd "$repos_base" || return
        git clone "$repo_url" "$nombre"
    else
        echo -e "\nLa carpeta ya existe en $ubicacion. Saltando la clonación..."
    fi

    cd "$ubicacion" || { echo "Error al entrar a la carpeta"; return; }

    echo ""
    echo -e "\nConfigurando editor..."
    git config --global core.editor "nano"

    echo -e "\n¡Entorno de $nombre configurado y listo para programar!"
    echo "Nota: Al hacer tu primer 'push', te va a pedir tus credenciales como nombre de usuario, correo y contraseña (la contraseña no es la de tu cuenta, es un Token de Acceso Personal que se genera en las configuraciones de GitHub)."
}

clonar() {
    ensure_repos_dir

    if [ -d "$ubicacion/.git" ]; then
        echo "El repositorio ya está clonado en $ubicacion."
        return
    fi

    echo -e "\nClonando el repositorio en $repos_base..."
    cd "$repos_base" || return
    git clone "$repo_url" "$nombre"
}

press_any_key() {
    echo -e "\nPulsa cualquier tecla para volver al menú..."
    read -n 1 -s -r
}

show_menu() {
    clear
    echo -e "   1) Actualizar local (Pull)"
    echo -e "   2) Actualizar el repo (Push)"
    echo -e "   0) Configurar"
    echo -e "   9) Clonar"
    echo -e "   X) Salir"
    read -p "   >> Introduce tu elección: " choice
    echo ""

    case "$choice" in
        1) descargar; press_any_key ;;
        2) publicar; press_any_key ;;
        0) configurar; press_any_key ;;
        9) clonar; press_any_key ;;
        X|x) echo "Saliendo... ¡Hasta pronto!"; exit 0 ;;
        *) echo "Opción inválida. Por favor, intenta de nuevo."; sleep 2 ;;
    esac
}

while true; do
    show_menu
done
