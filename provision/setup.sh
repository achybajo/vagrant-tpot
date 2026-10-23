#!/bin/bash
set -e

echo "[*] Actualizando sistema operativo base..."
dnf update -y
dnf install -y git curl

echo "[*] Clonando repositorio oficial de T-Pot..."
if [ ! -d "/opt/tpotce" ]; then
    git clone https://github.com/telekom-security/tpotce.git /opt/tpotce
fi

# Buscamos la ruta correcta del instalador dentro del repositorio clonado
if [ -f "/opt/tpotce/installer.sh" ]; then
    cd /opt/tpotce/
elif [ -f "/opt/tpotce/iso/installer/install.sh" ]; then
    cd /opt/tpotce/iso/installer/
else
    # Fallback buscando el archivo install.sh de manera dinámica
    INSTALL_DIR=$(find /opt/tpotce -name "install.sh" -exec dirname {} \; | head -n 1)
    if [ -n "$INSTALL_DIR" ]; then
        cd "$INSTALL_DIR"
    else
        echo "[ERROR] No se pudo encontrar el script de instalación de T-Pot."
        exit 1
    fi
fi

echo "[*] Directorio de trabajo actual: $(pwd)"
echo "[*] Ejecutando instalador de T-Pot..."
./install.sh -s -t h -u tpotadmin -p Pps2026