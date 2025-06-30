#!/bin/bash

# Arch Linux Post-Install Script (por juanii64)

set -e

# ---- COLORES ----
verde="\e[32m"
rojo="\e[31m"
reset="\e[0m"

# ---- FUNCIONES ----

instalar_entorno() {
    echo -e "${verde}Selecciona un entorno gráfico para instalar:${reset}"
    select opt in KDE GNOME XFCE LXQt i3 "Cancelar"; do
        case $opt in
            KDE)
                sudo pacman -S --noconfirm plasma kde-applications sddm
                sudo systemctl enable sddm
                break ;;
            GNOME)
                sudo pacman -S --noconfirm gnome gnome-extra gdm
                sudo systemctl enable gdm
                break ;;
            XFCE)
                sudo pacman -S --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
                sudo systemctl enable lightdm
                break ;;
            LXQt)
                sudo pacman -S --noconfirm lxqt sddm
                sudo systemctl enable sddm
                break ;;
            i3)
                sudo pacman -S --noconfirm i3 dmenu xorg xterm
                break ;;
            "Cancelar")
                break ;;
            *) echo -e "${rojo}Opción inválida.${reset}" ;;
        esac
    done
}

instalar_yay() {
    echo -e "${verde}Instalando yay (AUR helper)...${reset}"
    sudo pacman -S --noconfirm base-devel git
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    echo -e "${verde}yay instalado correctamente.${reset}"
}

instalar_utiles() {
    echo -e "${verde}Instalando herramientas comunes...${reset}"
    sudo pacman -S --noconfirm nano git curl wget unzip neofetch htop reflector
}

configurar_shell() {
    echo -e "${verde}Selecciona un shell para usar:${reset}"
    select shell in bash zsh fish "Cancelar"; do
        case $shell in
            bash) sudo chsh -s /bin/bash $USER; break ;;
            zsh) sudo pacman -S --noconfirm zsh; sudo chsh -s /bin/zsh $USER; break ;;
            fish) sudo pacman -S --noconfirm fish; sudo chsh -s /bin/fish $USER; break ;;
            "Cancelar") break ;;
            *) echo -e "${rojo}Opción inválida.${reset}" ;;
        esac
    done
}

instalar_fuentes() {
    echo -e "${verde}Instalando fuentes útiles...${reset}"
    sudo pacman -S --noconfirm ttf-dejavu ttf-liberation ttf-nerd-fonts-symbols
}

habilitar_servicios() {
    echo -e "${verde}Selecciona servicios para habilitar:${reset}"
    servicios=(bluetooth tlp cups avahi)
    for srv in "${servicios[@]}"; do
        read -rp "¿Habilitar $srv.service? [y/N]: " resp
        if [[ $resp == "y" || $resp == "Y" ]]; then
            sudo systemctl enable "$srv.service"
        fi
    done
}

# ---- MENÚ PRINCIPAL ----

while true; do
    echo -e "\n${verde}== Menú de post-instalación de Arch ==${reset}"
    select opt in \
        "1) Instalar entorno gráfico" \
        "2) Instalar yay (AUR helper)" \
        "3) Instalar herramientas comunes" \
        "4) Configurar shell" \
        "5) Instalar fuentes" \
        "6) Habilitar servicios útiles" \
        "7) Salir"; do

        case $REPLY in
            1) instalar_entorno; break ;;
            2) instalar_yay; break ;;
            3) instalar_utiles; break ;;
            4) configurar_shell; break ;;
            5) instalar_fuentes; break ;;
            6) habilitar_servicios; break ;;
            7) echo -e "${verde}¡Hasta luego, $USER!${reset}"; exit 0 ;;
            *) echo -e "${rojo}Opción inválida. Intenta de nuevo.${reset}" ;;
        esac
    done
done
