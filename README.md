# 🖥️ archinstallmx

**Script automatizado para instalar Arch Linux en modo UEFI con configuración en español (México).**  
Realiza una instalación limpia, rápida y mínima de Arch Linux, sin partición `/home` separada, con soporte para GRUB y NetworkManager.

---

## 🚀 Requisitos previos

Antes de ejecutar el script, asegúrate de:

1. **Cambiar la distribución del teclado a español:**
    ```bash
    loadkeys es
    ```

2. **Actualizar la lista de paquetes:**
    ```bash
    pacman -Sy
    ```

3. **Instalar Git:**
    ```bash
    pacman -S git
    ```

4. **Clonar el repositorio:**
    ```bash
    git clone https://github.com/juanii64/archinstallmx
    ```

5. **Dar permisos de ejecución al script:**
    ```bash
    chmod +x arch-installer.sh
    ```

6. **Entrar al directorio del repositorio:**
    ```bash
    cd archinstallmx
    ```

7. **Ejecutar el instalador:**
    ```bash
    sh arch-installer.sh
    ```

---

## 🧠 ¿Qué hace el script?

- Muestra los discos disponibles y permite elegir con menú numérico.
- Realiza particionado en modo UEFI (GPT):
  - Partición EFI (1 GiB)
  - Partición raíz `/` con el resto del disco
- Formatea y monta dichas particiones.
- Instala el sistema base: kernel, firmware, GRUB, NetworkManager, etc.
- Configura idioma (`es_MX.UTF-8`), zona horaria, hostname, usuario y contraseña.
- Instala y configura GRUB en UEFI, incluyendo fallback.
- Activa NetworkManager para conexión al primer reinicio.

---

## ❗ Qué NO hace

- No instala entorno gráfico (GNOME, KDE, XFCE…)
- No crea partición `/home` separada
- No instala software adicional (editores, navegadores, etc.)

---

## 📄 Licencia

Este proyecto está licenciado bajo [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html).

---

## 📌 Enlace del repositorio

[https://github.com/juanii64/archinstallmx](https://github.com/juanii64/archinstallmx)

---

## 🧾 Licencia GPL v3.0 (extracto)

> GNU GENERAL PUBLIC LICENSE  
> Version 3, 29 June 2007  
> Copyright (C) 2007 Free Software Foundation, Inc.  
> https://fsf.org/
>
> Everyone is permitted to copy and distribute verbatim copies of this license document, but changing it is not allowed.
>
> *(Incluye el texto completo de la licencia en el archivo original)*