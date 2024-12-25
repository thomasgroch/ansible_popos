#!/bin/bash

LOCAL_USER=${2:-tg}
PASSWORD_STORE_REPO=${1:-https://gitlab.com/thomas.groch/password-store.git}

# Check if sudo is installed and the user has sudo privileges
if sudo -v &>/dev/null; then
    echo "User has sudo privileges"
else
    echo "sudo is not installed or user does not have sudo privileges"
fi

novo_hostname="tgworkstation"

# Atualiza o hostname
sudo hostnamectl set-hostname "$novo_hostname"

# Atualiza o /etc/hosts
sudo sed -i "s/127.0.1.1.*/127.0.1.1   $novo_hostname/" /etc/hosts || echo "127.0.1.1   $novo_hostname" | sudo tee -a /etc/hosts

if [ ! -f ~/.ssh/tgroch_id_rsa ]; then
    chown $LOCAL_USER:$LOCAL_USER ~/.ssh/tgroch_id_rsa
    chown $LOCAL_USER:$LOCAL_USER ~/.ssh

    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/tgroch_id_rsa
    ssh-add ~/.ssh/tgroch_id_rsa
fi

# Clone password store
if [[ ! -e ~/.password-store ]]; then
    git clone "$PASSWORD_STORE_REPO" ~/.password-store
fi

# Install Homebrew if not installed on macOS
if [[ $(uname) == "Darwin" ]] && ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install pass
if ! command -v pass &> /dev/null; then
    if command -v brew &> /dev/null; then
        brew install pass
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm pass
    elif command -v apt &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y pass
    else
        echo "Unsupported package manager. Please install 'pass' manually."
    fi
fi

# Install Ansible
if ! command -v ansible-pull &> /dev/null; then
    if [[ $(uname) == "Darwin" ]] && command -v brew &> /dev/null; then
        brew install ansible
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm ansible
    elif command -v apt &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y ansible
    else
        echo "Unsupported package manager. Please install 'ansible' manually."
    fi
fi

sudo pacman -S --noconfirm xclip

# Update system
if command -v brew &> /dev/null; then
    echo "Updating Homebrew..."
    brew update
    brew upgrade
    brew cleanup
elif command -v pacman &> /dev/null; then
    sudo sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 50/g" /etc/pacman.conf
    sudo sed -i "s/#Color/Color/g" /etc/pacman.conf
    sudo pacman -Syyu --noconfirm
elif command -v apt &> /dev/null; then
    sudo apt-get update
    sudo apt-get upgrade -y
fi

# cat "/run/media/${LOCAL_USER}/SAFE/safe/gpg/thomas.groch@gmail.com.private.gpg-key.passphrase" | xclip -selection clipboard

# gpg --import "/run/media/${LOCAL_USER}/SAFE/safe/gpg/thomas.groch@gmail.com.private.gpg-key"
# gpg --import "/run/media/${LOCAL_USER}/SAFE/safe/gpg/thomas.groch@gmail.com.public.gpg-key"

sudo touch /var/log/ansible.log
sudo chown $USER:$USER /var/log/ansible.log

# Restore ansible
ansible-pull --url https://github.com/thomasgroch/ansible_popos --checkout main
