#!/bin/bash
set -e

echo "========== INSTALADOR DE ARCH LINUX =========="
echo

# Función para pausar
pause() {
  read -rp "Presiona Enter para continuar..."
}

# Mostrar discos
echo "[1] Discos disponibles:"
lsblk -dpno NAME,SIZE | grep -v "loop"
read -rp "Selecciona el disco (ej. /dev/sda o /dev/nvme0n1): " DISK

# Modo de instalación
echo "[2] ¿Qué modo de arranque deseas usar?"
select BOOTMODE in "UEFI" "MBR"; do
  [[ $BOOTMODE ]] && break
done

# ¿Partición /home?
echo "[3] ¿Deseas crear una partición /home separada?"
select HOMEPART in "Sí" "No"; do
  [[ $HOMEPART ]] && break
done

# Hostname, usuario y contraseñas
read -rp "[4] Nombre del sistema (hostname): " HOSTNAME
read -rp "[5] Nombre del usuario: " USERNAME
read -rsp "[6] Contraseña para $USERNAME: " USERPASS; echo
read -rsp "[7] Contraseña para root: " ROOTPASS; echo

# Confirmación
echo
echo "[⚠️] ¡Se formateará el disco completo: $DISK!"
read -rp "¿Deseas continuar? (y/N): " CONFIRM
[[ $CONFIRM != "y" ]] && exit 1

# Limpiar y crear tabla
echo "[8] Limpiando tabla de particiones..."
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
  read -rp "Tamaño para /boot/efi (ej. 512MiB, default): " EFISIZE
  EFISIZE=${EFISIZE:-512MiB}
  parted "$DISK" --script mkpart primary fat32 1MiB "$EFISIZE"
  parted "$DISK" --script set ${PART_COUNT} esp on
  BOOT="${DISK}${PART_COUNT}"
  ((PART_COUNT++))
  EFI_END="$EFISIZE"
else
  EFI_END="1MiB"
fi

read -rp "Tamaño para la raíz / (ej. 20G). Deja vacío o 0 para usar el resto: " ROOTSIZE
if [[ $ROOTSIZE == "" || $ROOTSIZE == "0" ]]; then
  ROOT_END="100%"
else
  ROOT_END="${ROOTSIZE}GiB"
fi

parted "$DISK" --script mkpart primary ext4 "$EFI_END" "$ROOT_END"
ROOT="${DISK}${PART_COUNT}"
((PART_COUNT++))

if [[ $HOMEPART == "Sí" ]]; then
  parted "$DISK" --script mkpart primary ext4 "$ROOT_END" 100%
  HOME="${DISK}${PART_COUNT}"
fi

sync
sleep 1

# Formatear y montar
echo "[9] Formateando y montando particiones..."
mkfs.ext4 "$ROOT"
mount "$ROOT" /mnt

if [[ $BOOTMODE == "UEFI" ]]; then
  mkfs.fat -F32 "$BOOT"
  mkdir -p /mnt/boot/efi
  mount "$BOOT" /mnt/boot/efi
fi

if [[ $HOMEPART == "Sí" ]]; then
  mkfs.ext4 "$HOME"
  mkdir -p /mnt/home
  mount "$HOME" /mnt/home
fi

# Instalar base
echo "[10] Instalando el sistema base..."
pacstrap /mnt base linux linux-firmware nano sudo networkmanager grub

# Fstab
echo "[11] Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Configurar dentro de chroot
echo "[12] Configurando el sistema dentro de chroot..."

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
echo "[✅] Instalación completada exitosamente."
echo "Desmontando particiones..."
umount -R /mnt

echo "Ya puedes reiniciar. ¡Bienvenido a Arch Linux!"
