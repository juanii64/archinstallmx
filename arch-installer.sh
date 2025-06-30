#!/bin/bash
set -e

echo "========== INSTALADOR DE ARCH LINUX =========="

# Pausa
pause() {
  read -rp "Presiona Enter para continuar..."
}

# Mostrar discos
echo "[1] Discos disponibles:"
lsblk -dpno NAME,SIZE | grep -v "loop"
read -rp "Selecciona el disco (ej. /dev/sda o /dev/nvme0n1): " DISK

# Modo de arranque
echo "[2] Selecciona el tipo de instalación:"
echo "1) UEFI"
echo "2) MBR (BIOS)"
read -rp "Opción: " bootopt
if [[ "$bootopt" == "1" ]]; then
  BOOTMODE="UEFI"
else
  BOOTMODE="MBR"
fi

# ¿Partición /home?
echo "[3] ¿Deseas partición /home separada?"
echo "1) Sí"
echo "2) No"
read -rp "Opción: " homeopt
if [[ "$homeopt" == "1" ]]; then
  HOMEPART="Sí"
else
  HOMEPART="No"
fi

# Hostname y usuarios
read -rp "[4] Nombre del sistema (hostname): " HOSTNAME
read -rp "[5] Nombre del usuario: " USERNAME
read -rsp "[6] Contraseña para $USERNAME: " USERPASS; echo
read -rsp "[7] Contraseña para root: " ROOTPASS; echo

# Confirmación
echo
echo "[⚠️] ¡Se eliminará TODO el contenido de $DISK!"
read -rp "¿Continuar? (y/N): " CONFIRM
[[ $CONFIRM != "y" ]] && exit 1

# Borrar disco
echo "[8] Limpiando y creando tabla de particiones..."
wipefs -af "$DISK"
sgdisk -Zo "$DISK"

if [[ $BOOTMODE == "UEFI" ]]; then
  parted "$DISK" --script mklabel gpt
else
  parted "$DISK" --script mklabel msdos
fi

# Crear particiones
PART_COUNT=1

if [[ $BOOTMODE == "UEFI" ]]; then
  echo "[9] Creando partición EFI de 1GiB..."
  parted "$DISK" --script mkpart primary fat32 1MiB 1025MiB
  parted "$DISK" --script set ${PART_COUNT} esp on
  BOOT="${DISK}${PART_COUNT}"
  ((PART_COUNT++))
  ROOT_START="1025MiB"
else
  ROOT_START="1MiB"
fi

echo "[10] ¿Tamaño para raíz (/) en GiB? (0 para usar el resto): "
read -rp "Tamaño (ej. 20): " ROOTSIZE
if [[ "$ROOTSIZE" == "0" || "$ROOTSIZE" == "" ]]; then
  ROOT_END="100%"
else
  ROOT_END="$((1025 + ROOTSIZE))MiB"
fi

parted "$DISK" --script mkpart primary ext4 "$ROOT_START" "$ROOT_END"
ROOT="${DISK}${PART_COUNT}"
((PART_COUNT++))

if [[ $HOMEPART == "Sí" ]]; then
  parted "$DISK" --script mkpart primary ext4 "$ROOT_END" 100%
  HOME="${DISK}${PART_COUNT}"
fi

sync
sleep 1

# Formateo y montaje
echo "[11] Formateando particiones..."
mkfs.ext4 "$ROOT"
mount "$ROOT" /mnt

if [[ $BOOTMODE == "UEFI" ]]; then
  mkfs.fat -F32 "$BOOT"
  mkdir -p /mnt/boot/efi
  mount "$BOOT" /mnt/boot/efi
fi

if [[ $HOMEPART == "Sí" ]]; then
  mkfs.ext4 "$HOME"
  mkdir /mnt/home
  mount "$HOME" /mnt/home
fi

# Instalación base
echo "[12] Instalando sistema base..."
pacstrap /mnt base linux linux-firmware networkmanager nano sudo grub

# Fstab
echo "[13] Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Configuración del sistema
echo "[14] Configurando Arch Linux dentro de chroot..."

arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<EOL
127.0.0.1 localhost
::1       localhost
127.0.1.1 $HOSTNAME.localdomain $HOSTNAME
EOL

echo root:$ROOTPASS | chpasswd

useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$USERPASS" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

systemctl enable NetworkManager

if [[ "$BOOTMODE" == "UEFI" ]]; then
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
else
  grub-install --target=i386-pc $DISK
fi

grub-mkconfig -o /boot/grub/grub.cfg
EOF

# Finalizar
echo "[✅] Instalación completada."
umount -R /mnt
echo "Ya puedes reiniciar el sistema. ¡Disfruta Arch Linux!"
