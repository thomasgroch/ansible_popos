#!/bin/bash

# Define configuration settings
USER=${2:-tg}
PASSWORD_STORE_REPO=${1:-https://gitlab.com/thomas.groch/password-store.git}

# Function to install packages
install() {
    local package_name=$1
    local distribution_type=$2
    
    case $distribution_type in
        Debian|Ubuntu) echo "Installing $package_name on Debian/Ubuntu"; sudo apt-get install -y $package_name;;
        ArchLinux) echo "Installing $package_name on ArchLinux"; sudo pacman -S --noconfirm $package_name;;
    esac
}

# Function to clone a repository
clone() {
    local repository_url=$1
    local directory=$2
    
    if [ ! -e "$directory" ]; then
        echo "Cloning repository from $repository_url in $directory"
        git clone $repository_url "$directory"
    else
        echo "Directory $directory already exists"
    fi
}

# Function to import a GPG key
import_gpg_key() {
    local gpg_key=$1
    
    if [ -f "$gpg_key" ]; then
        echo "Importing GPG key from $gpg_key"
        gpg --import "$gpg_key"
    else
        echo "GPG key file not found"
    fi
}

# Function to update the system
update_system() {
    local distro=$1
    
    case $distro in
        Debian) echo "Updating the system on Debian"; sudo apt-get update && sudo apt-get dist-upgrade -y;;
        Ubuntu) echo "Updating the system on Ubuntu"; sudo apt-get update && sudo apt-get dist-upgrade -y;;
        ArchLinux) echo "Updating the system on ArchLinux"; sudo pacman -Syu && sudo pacman -Syyu;;
    esac
}

# Install Pass and Ansible
install pass $(uname)

# Clone password store
clone $PASSWORD_STORE_REPO ~/.password-store

# Update the system
update_system $(uname)

# Import GPG key
import_gpg_key "~/.password-store/$USER.GMAIL_PRIVATE_GPG_KEY"

# Copy GPG private key to clipboard and import key
cat "~/.password-store/$USER.GMAIL_PRIVATE_GPG_KEY" | xclip -selection clipboard || \
gpg --import "~/.password-store/$USER.GMAIL_PRIVATE_GPG_KEY"

# Restore Ansible
ansible-pull --url https://github.com/thomasgroch/ansible_popos --checkout main

# Configure GPG to use the imported private key
echo "Configuring GPG to use the private key"
gpg --default-key "~/.password-store/$USER.GMAIL_PRIVATE_GPG_KEY"

# Update Ansible settings
ansible-pull --url https://github.com/thomasgroch/ansible_popos --checkout main

# Add additional command to update GPG
update_system $(uname)

echo "Configuration complete. Please run `ansible-pull` again to apply changes."