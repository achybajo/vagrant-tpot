# T-Pot sobre AlmaLinux con Vagrant

Levanta una VM con AlmaLinux 10 usando Vagrant + VirtualBox, la actualiza, crea los usuarios que definas e instala [T-Pot](https://github.com/telekom-security/tpotce) de forma automática.

## Contenido del repositorio

| Archivo | Para qué sirve | ¿Se edita? |
|---|---|---|
| `Vagrantfile` | Define la VM (box, red, RAM, CPU) | Sí: red y recursos |
| `provision.sh` | Actualiza el SO, crea usuarios, instala T-Pot | Normalmente no |
| `users.conf.example` | Plantilla de usuarios de Linux | Se copia a `users.conf` y se edita |
| `tpot.conf.example` | Plantilla de la configuración de T-Pot | Se copia a `tpot.conf` y se edita |
| `.gitignore` | Evita subir `users.conf` y `tpot.conf` (tienen claves) | No |
| `.gitattributes` | Fuerza saltos de línea LF | No |

## Requisitos

- Equipo con procesador **Intel/AMD (x86_64)**. VirtualBox en Mac con Apple Silicon (M1/M2/M3...) no ejecuta VMs x86, así que esta solución no corre ahí.
- **RAM:** la VM usa 16 GB. Conviene tener 24 GB o más en el equipo.
- **Disco:** T-Pot Hive pide unos 256 GB. Ver [Limitaciones conocidas](#limitaciones-conocidas).
- Conexión a internet (descarga la box, actualizaciones y T-Pot).
- Git, VirtualBox y Vagrant.

---

## 1. Instalar VirtualBox y Vagrant

Descargas oficiales:
- Vagrant: https://developer.hashicorp.com/vagrant/downloads
- VirtualBox: https://www.virtualbox.org/wiki/Downloads

### Windows

1. Instalá **VirtualBox** con el instalador de la página oficial.
2. Instalá **Vagrant** con el instalador (`.msi`) de la página oficial y **reiniciá** el equipo cuando lo pida.
3. Instalá **Git** desde https://git-scm.com/download/win.

Alternativa, si ya usás Chocolatey (PowerShell como administrador):

```powershell
choco install git virtualbox vagrant -y
```

Verificá en PowerShell:

```powershell
vagrant --version
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --version
```

> Si tenés Hyper-V o WSL2 activos, VirtualBox puede andar lento o fallar. Si te pasa, desactivá Hyper-V o usá otra máquina.

### Linux

**Vagrant en Debian / Ubuntu** (repositorio oficial de HashiCorp):

```bash
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant
```

**Vagrant en Fedora:**

```bash
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
sudo dnf -y install vagrant
```

> En Fedora 41 o posterior (dnf5) el segundo comando es:
> `sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo`

**Vagrant en RHEL / Rocky / AlmaLinux:**

```bash
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf -y install vagrant
```

Si algún comando falla, revisá las instrucciones actualizadas en la página de descargas de Vagrant.

**VirtualBox en Linux:**
- Debian / Ubuntu: `sudo apt install virtualbox`
- Fedora / RHEL y derivadas: descargá el paquete desde la página oficial de VirtualBox.
- Si tenés Secure Boot activado, puede bloquear los módulos de VirtualBox: hay que firmarlos o desactivar Secure Boot.

Verificá:

```bash
vagrant --version
VBoxManage --version
```

### macOS (solo Intel)

```bash
brew install --cask virtualbox
brew install --cask vagrant
brew install git
```

Sin Homebrew, usá los instaladores de las páginas oficiales. Al instalar VirtualBox, macOS puede pedir permiso en *Ajustes del Sistema > Privacidad y seguridad*; aceptalo y reiniciá si lo pide.

Verificá:

```bash
vagrant --version
VBoxManage --version
```

---

## 2. Clonar el repositorio

```bash
git clone https://github.com/TU_USUARIO/TU_REPO.git
cd TU_REPO
cp users.conf.example users.conf
cp tpot.conf.example tpot.conf
```

En Windows (PowerShell) el copiado es: `Copy-Item users.conf.example users.conf` y `Copy-Item tpot.conf.example tpot.conf`.

---

## 3. Editar los archivos

Usá un editor que respete los saltos de línea **LF** (VS Code lo muestra abajo a la derecha: tiene que decir `LF`, no `CRLF`).

### `users.conf` — usuarios de Linux

Una línea por usuario, con el formato `usuario:contraseña:sudo`.

```
admin:UnaClaveFuerte123:yes
pps:OtraClaveFuerte456:no
```

- `sudo`: `yes` agrega el usuario al grupo `wheel`; `no` lo deja sin privilegios.
- La contraseña **no puede contener `:`**.
- Las líneas que empiezan con `#` se ignoran.
- Tiene que haber al menos un usuario con `yes`: es el que ejecuta el instalador de T-Pot.

### `tpot.conf` — configuración de T-Pot

```bash
TPOT_TYPE='h'
TPOT_INSTALL_USER='admin'
TPOT_WEB_USER='pps'
TPOT_WEB_PASS='ClaveParaLaWeb789'
```

- `TPOT_TYPE`: tipo de instalación (`h` = hive, `s` = sensor, `l` = llm, `i` = mini, `m` = mobile, `t` = tarpit). Para empezar, `h`.
- `TPOT_INSTALL_USER`: tiene que existir en `users.conf` con `yes`.
- `TPOT_WEB_USER` / `TPOT_WEB_PASS`: login de la web de T-Pot. **No** son usuarios de Linux.
- Usá comillas simples. Si la clave tiene un `'`, evitalo.

### `Vagrantfile` — red y recursos

Buscá la sección `RED (EDITAR)`:

```ruby
config.vm.network "public_network",
  bridge: "NOMBRE_DE_TU_PLACA",
  ip: "192.168.1.50",
  use_dhcp_assigned_default_route: true
```

- `bridge`: nombre **exacto** de la placa con la que tu equipo sale a la red (Wi-Fi o Ethernet). Para verlo:
  - Linux / macOS: `VBoxManage list bridgedifs` (campo `Name:`).
  - Windows: `& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" list bridgedifs`
- `ip`: una IP **libre** de tu red y del mismo segmento que tu equipo. Si tu PC es `192.168.0.23`, usá algo como `192.168.0.50`.
- Si preferís que el router asigne la IP, borrá la línea `ip:`.

Recursos, en la sección `RECURSOS`: `vb.memory` (MB de RAM) y `vb.cpus`. T-Pot Hive recomienda 16 GB.

### `provision.sh`

Normalmente no hace falta tocarlo. Hace, en orden: actualiza el sistema, crea los usuarios de `users.conf`, instala T-Pot como el usuario `TPOT_INSTALL_USER` y reinicia la VM. Al terminar borra de `/tmp` los archivos con claves.

---

## 4. Desplegar

```bash
vagrant up
```

La primera vez tarda bastante (descarga de la box, actualización del sistema e instalación de T-Pot). Es normal que parezca quieto un buen rato.

Cuando termina, la VM se reinicia sola. Después:

| Qué | Cómo (reemplazá la IP por la tuya) |
|---|---|
| SSH | `ssh -p 64295 admin@192.168.1.50` |
| Web de T-Pot | `https://192.168.1.50:64297` (usuario y clave de `tpot.conf`) |

### Importante: después de instalar T-Pot

T-Pot mueve el SSH al puerto **64295**. Vagrant espera el puerto 22, así que `vagrant ssh`, `vagrant provision` y `vagrant reload` **dejan de funcionar** una vez instalado. Usá estos comandos:

| Acción | Comando |
|---|---|
| Entrar a la VM | `ssh -p 64295 admin@IP` |
| Reiniciar | dentro de la VM: `sudo reboot` |
| Apagar | `vagrant halt --force` |
| Encender | `vagrant up` |
| Borrar todo y empezar de cero | `vagrant destroy -f` |

---

## Solución de problemas

| Problema | Causa / solución |
|---|---|
| `Falta users.conf` o `tpot.conf` | No copiaste los `.example`. Ver paso 2. |
| Error 404 al descargar la box | La box de Vagrant Cloud puede estar rota. Probá `vagrant box add almalinux/10 --provider virtualbox` para ver el error exacto y abrí un issue. |
| Errores raros en la primera línea de `provision.sh` | Saltos de línea CRLF. Convertí a LF (`.gitattributes` lo evita al clonar con git). |
| `bridge` no existe / la VM no tiene red | El nombre de la placa no coincide. Copialo tal cual de `VBoxManage list bridgedifs`. |
| La instalación falla o se corta | Ver el mensaje en la consola. Con la VM aún en el SSH 22, `vagrant provision` reintenta. |
| No puedo entrar por SSH con contraseña | El `sshd` de la box puede tener la autenticación por contraseña desactivada. Usá `vagrant ssh` antes de instalar T-Pot, o configurá una clave pública. |

## Limitaciones conocidas

- **Disco:** la box trae un disco mucho menor a los 256 GB que pide T-Pot Hive. El `Vagrantfile` no lo amplía todavía. Si la instalación se queda sin espacio, hay que agrandar el disco de la VM y expandir el sistema de archivos.
- **Una sola placa de red:** T-Pot está pensado para equipos con una sola interfaz. Se usa `public_network` con `use_dhcp_assigned_default_route` para que la ruta por defecto salga por la placa puenteada. Si hay problemas de red, empezá por ahí.
- **Box:** se usa `almalinux/10` de Vagrant Cloud. Si su disponibilidad cambia, se puede forzar otra con `config.vm.box`.

## Seguridad

- T-Pot es un honeypot: está hecho para recibir ataques. Con `public_network` la VM queda visible para toda tu red local. No lo uses en una red con equipos importantes y no lo expongas a internet sin saber lo que hacés.
- **No subas `users.conf` ni `tpot.conf` a GitHub.** El `.gitignore` ya los excluye; subí solo los `.example`.
- Cambiá todas las contraseñas de ejemplo por unas fuertes.
- Si el repo es público, no pongas IPs ni datos internos de tu red en los archivos versionados.
