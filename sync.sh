#!/bin/bash

# es para hacer una mini sincronizacion, realmente ignorenlo ya que es algo mas para mi que para ustedes, nada mas para mas agilidad
# Tambien como yo trabajo en macOS los comandos son en UNIX y no funconarian bien en Linux y mucho menos en Windows

    nombre="Mantenix-Windows-Edition"
    repo_url="https://github.com/RichyKunBv/$nombre.git"
    ubicacion="$HOME/$nombre"

if [ -d "$ubicacion" ]; then
    cd "$ubicacion"
fi

descargar() {
    echo "Obteniendo últimos cambios del repositorio..."
    git pull origin main
}

publicar() {
    git add .
    read -p "   >> Introduce el mensaje del commit: " mensaje
    
    if [ -z "$mensaje" ]; then
        echo "El mensaje no puede estar vacío. Cancelando publicación..."
        return
    fi
    
    git commit -m "$mensaje"
    
    git pull origin main --rebase
    
    git push origin main
}

# Configuración inicial del entorno
configurar() {
    clear
    echo "=== Clonar y Configurar Entorno de $nombre ==="

    if [ ! -d "$ubicacion" ]; then
        echo -e "\n Descargando el código..."
        cd "$HOME" || return
        git clone "$repo_url"
    else
        echo -e "\n La carpeta ya existe. Saltando la clonación..."
    fi
    
    cd "$ubicacion" || { echo "Error al entrar a la carpeta"; return; }

    echo ""

    echo -e "\n Configurando editor..."

    git config --global core.editor "nano"

    echo -e "\n ¡Entorno de $nombre configurado y listo para programar!"
    echo "Nota: Al hacer tu primer 'push', te va a pedir tus credenciales como nombre de usuario, correo y contraseña (la contraseña no es la de tu cuenta es un Token de Acceso Personal que se genera en las configuraciones de GitHub)."
}

# Clonar
clonar() {
    echo -e "\nClonando el repositorio..."
    git clone "$repo_url"
}

# Pausa interactiva
press_any_key() {
    echo -e "\nPulsa cualquier tecla para volver al menú..."
    read -n 1 -s -r
}

# --- MENÚ PRINCIPAL ---
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

# Bucle infinito para mantener el menú corriendo
while true; do
    show_menu
done