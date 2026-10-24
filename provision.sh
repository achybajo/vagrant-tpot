#!/bin/bash
set -euo pipefail

SUDOERS_TMP="/etc/sudoers.d/90-tpot-install"
trap 'rm -f "$SUDOERS_TMP"' EXIT

# Por si los archivos se editaron en Windows (saltos de línea CRLF)
sed -i 's/\r$//' /tmp/users.conf /tmp/tpot.conf
source /tmp/tpot.conf

echo "[*] Actualizando el sistema..."
dnf -y update
dnf -y install git curl sudo

echo "[*] Creando usuarios..."
while IFS=: read -r user pass sudo_flag || [[ -n "${user:-}" ]]; do
  [[ -z "${user:-}" || "$user" =~ ^# ]] && continue

  id "$user" &>/dev/null || useradd -m -s /bin/bash "$user"
  echo "${user}:${pass}" | chpasswd

  if [ "${sudo_flag:-no}" = "yes" ]; then
    usermod -aG wheel "$user"
  fi

  echo "Usuario $user listo (sudo: ${sudo_flag:-no})"
done < /tmp/users.conf

# --- T-Pot: se instala una sola vez ---
if [ -f /var/lib/tpot_installed ]; then
  echo "[*] T-Pot ya instalado, no se repite."
  exit 0
fi

echo "[*] Instalando T-Pot (tarda bastante)..."
# El instalador no corre como root y con -s necesita sudo sin clave (temporal)
echo "$TPOT_INSTALL_USER ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_TMP"
chmod 440 "$SUDOERS_TMP"

sudo -u "$TPOT_INSTALL_USER" -H env \
  TPOT_TYPE="$TPOT_TYPE" TPOT_WEB_USER="$TPOT_WEB_USER" TPOT_WEB_PASS="$TPOT_WEB_PASS" \
  bash -s <<'EOS'
set -euo pipefail
cd "$HOME"
[ -d tpotce ] || git clone https://github.com/telekom-security/tpotce tpotce
cd tpotce
./install.sh -s -t "$TPOT_TYPE" -u "$TPOT_WEB_USER" -p "$TPOT_WEB_PASS"
EOS

touch /var/lib/tpot_installed
echo "[*] Listo. La VM se reinicia en 1 minuto."
shutdown -r +1 >/dev/null 2>&1