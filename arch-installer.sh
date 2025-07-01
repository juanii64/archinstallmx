#!/bin/bash

# Arch Linux Install Script (por juanii64)
set -e

echo "========== INSTALADOR DE ARCH LINUX (UEFI) Script (por juanii64) =========="

# Mostrar discos como menú numerado
echo "[1] Discos disponibles:"
DISKS=($(lsblk -dpno NAME | grep -v "loop"))
for i in "${!DISKS[@]}"; do
  SIZE=$(lsblk -dn -o SIZE "${DISKS[$i]}")
  echo "$((i+1))) ${DISKS[$i]} ($SIZE)"
done

read -rp "Selecciona el disco (número): " DISK_INDEX
DISK="${DISKS[$((DISK_INDEX-1))]}"

# Confirmación
echo "[⚠️] Se eliminarán TODOS los datos en: $DISK"
read -rp "¿Deseas continuar? (y/N): " CONFIRM
[[ $CONFIRM != "y" ]] && exit 1

# Hostname y usuarios
read -rp "[2] Nombre del sistema (hostname): " HOSTNAME
read -rp "[3] Nombre del usuario: " USERNAME
read -rsp "[4] Contraseña para $USERNAME: " USERPASS; echo
read -rsp "[5] Contraseña para root: " ROOTPASS; echo

# Limpieza y particionado
echo "[6] Borrando disco y creando tabla GPT..."
wipefs -af "$DISK"
sgdisk -Zo "$DISK"
parted "$DISK" --script mklabel gpt

# Particiones
echo "[7] Creando partición EFI (1GiB) y raíz (/)..."
parted "$DISK" --script mkpart primary fat32 1MiB 1025MiB
parted "$DISK" --script set 1 esp on
parted "$DISK" --script mkpart primary ext4 1025MiB 100%

BOOT="${DISK}1"
ROOT="${DISK}2"

# Formatear y montar
echo "[8] Formateando particiones..."
mkfs.fat -F32 "$BOOT"
mkfs.ext4 "$ROOT"

echo "[9] Montando particiones..."
mount "$ROOT" /mnt
mkdir -p /mnt/boot/efi
mount "$BOOT" /mnt/boot/efi

# Instalación base con efibootmgr
echo "[10] Instalando el sistema base..."
pacstrap /mnt base linux linux-firmware nano sudo networkmanager grub efibootmgr iwd

# Fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Configuración del sistema
echo "[11] Configurando el sistema dentro del nuevo entorno..."

arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc

echo "es_MX.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=es_MX.UTF-8" > /etc/locale.conf

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

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck

# Fallback para mayor compatibilidad con UEFI
mkdir -p /boot/efi/EFI/boot
cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/boot/bootx64.efi

grub-mkconfig -o /boot/grub/grub.cfg
EOF

# Final
echo "[✅] Instalación completada con éxito."
umount -R /mnt
echo "Ya puedes reiniciar. ¡Bienvenido a Arch Linux en español 🇲🇽!"
