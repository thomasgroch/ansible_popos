#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[*] $1${NC}"
}

# Function to print warning messages
print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}[!] $1${NC}"
}

# Function to check if a package is installed
is_package_installed() {
    dpkg -l "$1" &> /dev/null
    return $?
}

# Function to check if a repository is already added
is_repo_added() {
    grep -h "^deb.*$1" /etc/apt/sources.list /etc/apt/sources.list.d/* &> /dev/null
    return $?
}

# Function to check if a flatpak remote exists
is_flatpak_remote_exists() {
    flatpak remotes --show-details | grep -q "^$1"
    return $?
}

# Function to check if a flatpak app is installed
is_flatpak_installed() {
    flatpak list --app | grep -q "^$1"
    return $?
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root (with sudo)"
    exit 1
fi

# Store the real user who executed sudo
REAL_USER=$(logname || who am i | awk '{print $1}')
REAL_HOME=$(eval echo ~$REAL_USER)

# Setup XDG Base Directories
setup_xdg_dirs() {
    print_status "Setting up XDG Base Directories..."
    
    # Define XDG Base Directory paths
    export XDG_CONFIG_HOME="$REAL_HOME/.config"
    export XDG_CACHE_HOME="$REAL_HOME/.cache"
    export XDG_DATA_HOME="$REAL_HOME/.local/share"
    export XDG_STATE_HOME="$REAL_HOME/.local/state"
    
    # Create XDG Base Directories with proper permissions
    mkdir -p "$XDG_CONFIG_HOME"
    mkdir -p "$XDG_CACHE_HOME"
    mkdir -p "$XDG_DATA_HOME"
    mkdir -p "$XDG_STATE_HOME"
    
    # Set correct ownership
    chown -R "$REAL_USER:$REAL_USER" "$XDG_CONFIG_HOME"
    chown -R "$REAL_USER:$REAL_USER" "$XDG_CACHE_HOME"
    chown -R "$REAL_USER:$REAL_USER" "$XDG_DATA_HOME"
    chown -R "$REAL_USER:$REAL_USER" "$XDG_STATE_HOME"
    
    # Set correct permissions
    chmod 700 "$XDG_CONFIG_HOME"
    chmod 700 "$XDG_CACHE_HOME"
    chmod 700 "$XDG_DATA_HOME"
    chmod 700 "$XDG_STATE_HOME"
    
    # Create XDG user directories config
    if [ ! -f "$XDG_CONFIG_HOME/user-dirs.dirs" ]; then
        print_status "Creating XDG user directories configuration..."
        cat > "$XDG_CONFIG_HOME/user-dirs.dirs" << EOL
XDG_DESKTOP_DIR="$REAL_HOME/Desktop"
XDG_DOWNLOAD_DIR="$REAL_HOME/Downloads"
XDG_TEMPLATES_DIR="$REAL_HOME/Templates"
XDG_PUBLICSHARE_DIR="$REAL_HOME/Public"
XDG_DOCUMENTS_DIR="$REAL_HOME/Documents"
XDG_MUSIC_DIR="$REAL_HOME/Music"
XDG_PICTURES_DIR="$REAL_HOME/Pictures"
XDG_VIDEOS_DIR="$REAL_HOME/Videos"
EOL
        chown "$REAL_USER:$REAL_USER" "$XDG_CONFIG_HOME/user-dirs.dirs"
        chmod 644 "$XDG_CONFIG_HOME/user-dirs.dirs"
    fi
}

print_status "Setting up system for user: $REAL_USER"

# Setup GPG with XDG compliance
setup_gpg() {
    print_status "Setting up GPG with XDG compliance..."
    
    GPG_DIR="$XDG_DATA_HOME/gnupg"
    
    if [ ! -d "$GPG_DIR" ]; then
        mkdir -p "$GPG_DIR"
        print_status "Created XDG-compliant GPG directory"
    fi
    
    current_perm=$(stat -c "%a" "$GPG_DIR")
    if [ "$current_perm" != "700" ]; then
        chown -R "$REAL_USER:$REAL_USER" "$GPG_DIR"
        chmod 700 "$GPG_DIR"
        find "$GPG_DIR" -type f -exec chmod 600 {} \;
        print_status "Fixed GPG directory permissions"
    else
        print_warning "GPG directory permissions already correct"
    fi
    
    # Create GPG config to use XDG directory
    if [ ! -f "$XDG_CONFIG_HOME/gnupg/gpg.conf" ]; then
        mkdir -p "$XDG_CONFIG_HOME/gnupg"
        touch "$XDG_CONFIG_HOME/gnupg/gpg.conf"
        chown -R "$REAL_USER:$REAL_USER" "$XDG_CONFIG_HOME/gnupg"
        chmod 700 "$XDG_CONFIG_HOME/gnupg"
    fi
}

# Function to check if a package is installed
is_package_installed() {
    dpkg -l "$1" &> /dev/null
    return $?
}

# Function to check if a repository is already added
is_repo_added() {
    grep -h "^deb.*$1" /etc/apt/sources.list /etc/apt/sources.list.d/* &> /dev/null
    return $?
}

# Function to check if a flatpak remote exists
is_flatpak_remote_exists() {
    flatpak remotes --show-details | grep -q "^$1"
    return $?
}

# Function to check if a flatpak app is installed
is_flatpak_installed() {
    flatpak list --app | grep -q "^$1"
    return $?
}

# Add repositories
add_repositories() {
    print_status "Checking repositories..."
    
    # Check Guake PPA
    if ! is_repo_added "linuxuprising/guake"; then
        print_status "Adding Guake PPA..."
        add-apt-repository -y ppa:linuxuprising/guake
    else
        print_warning "Guake PPA already added"
    fi
    
    # Check Flathub
    if ! is_flatpak_remote_exists "flathub"; then
        print_status "Adding Flathub repository..."
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    else
        print_warning "Flathub repository already added"
    fi
}

# Install packages
install_packages() {
    print_status "Checking and installing packages..."
    
    # Wait for any apt locks to be released
    while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
        sleep 1
    done

    local needs_update=false
    PACKAGES=(
        tigervnc-standalone-server
        tigervnc-xorg-extension
        ca-certificates
        software-properties-common
        zsh
        snapd
        dconf-cli
        python3-psutil
        gnome-tweaks
        openssh-server
        bat
        ffmpeg
        virtualbox
        curl
        file
        git
        xclip
        xsel
        gufw
        guake
        zsh
        encfs
        shellcheck
        iperf3
        bash
        openssl
        gopass
    )

    # Check each package
    for pkg in "${PACKAGES[@]}"; do
        if ! is_package_installed "$pkg"; then
            needs_update=true
            break
        fi
    done

    if [ "$needs_update" = true ]; then
        print_status "Installing missing packages..."
        apt-get update
        apt-get install -y "${PACKAGES[@]}"
    else
        print_warning "All packages are already installed"
    fi
}

# Install Flatpak applications
install_flatpak_apps() {
    print_status "Installing Flatpak applications as user $REAL_USER..."
    
    if ! sudo -u "$REAL_USER" flatpak list --app | grep -q "com.moonlight_stream.Moonlight"; then
        print_status "Installing Moonlight..."
        sudo -u "$REAL_USER" flatpak install -y flathub com.moonlight_stream.Moonlight
    else
        print_warning "Moonlight already installed"
    fi
}

# Install lazygit
install_lazygit() {
    print_status "Checking lazygit installation..."
    
    if ! command -v lazygit &> /dev/null; then
        print_status "Installing lazygit..."
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        install lazygit /usr/local/bin
        rm lazygit.tar.gz lazygit
    else
        print_warning "Lazygit already installed"
    fi
}

# Setup ZSH
setup_zsh() {
    print_status "Checking ZSH setup..."
    
    # Check if ZSH is already the default shell
    if ! grep -q "^$REAL_USER.*zsh$" /etc/passwd; then
        print_status "Setting ZSH as default shell..."
        chsh -s $(which zsh) "$REAL_USER"
    else
        print_warning "ZSH is already the default shell"
    fi
    
    # Check Oh My Zsh installation
    if [ ! -d "$XDG_CONFIG_HOME/oh-my-zsh" ]; then
        print_status "Installing Oh My Zsh..."
        su - "$REAL_USER" -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
    else
        print_warning "Oh My Zsh is already installed"
    fi
}

# Setup cron jobs
setup_cron() {
    print_status "Setting up cron jobs..."
    
    # Install cron package
    if ! is_package_installed "cron"; then
        sudo apt-get install -y cron
    fi

    # Download provision script directly from GitHub
    sudo wget -q https://raw.githubusercontent.com/thomasgroch/ansible_popos/main/files/provision -O /usr/local/bin/provision
    sudo chmod +x /usr/local/bin/provision

    # Add cron jobs
    (crontab -l 2>/dev/null || true; echo "*/3 * * * * { date; /usr/local/bin/provision; RC=\$?; date; echo \"Exit code: \$RC\"; } >> /var/tmp/ansible_provision.log 2>&1 && if [ \$RC -eq 0 ]; then echo \$(date) > /var/tmp/ansible_provision_last_run.txt; fi") | crontab -
    (crontab -l 2>/dev/null || true; echo "@reboot /bin/rm -rf /home/$USER/.ansible") | crontab -
}

# Setup dotfiles
setup_dotfiles() {
    print_status "Setting up dotfiles..."
    
    # Install oh-my-zsh if not already installed
    if [ ! -d "$XDG_CONFIG_HOME/oh-my-zsh" ]; then
        curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | RUNZSH=no KEEP_ZSHRC=yes sh
    fi

    # Create and set permissions for oh-my-zsh directories
    mkdir -p "$XDG_CONFIG_HOME/oh-my-zsh/cache/completions"
    mkdir -p "$XDG_CONFIG_HOME/oh-my-zsh-custom"
    chmod -R 755 "$XDG_CONFIG_HOME/oh-my-zsh"
    chmod -R 755 "$XDG_CONFIG_HOME/oh-my-zsh-custom"
}

# Setup GNOME settings
setup_gnome() {
    print_status "Setting up GNOME settings..."
    
    # Install required packages
    sudo apt-get install -y dconf-cli python3-psutil

    # Setup wallpaper
    print_status "Setting up GNOME wallpaper..."
    sudo wget -q https://raw.githubusercontent.com/thomasgroch/ansible_popos/main/files/wallpaper.png -O /usr/share/backgrounds/wallpaper.png
    gsettings set org.gnome.desktop.background picture-uri "file:///usr/share/backgrounds/wallpaper.png"
    gsettings set org.gnome.desktop.background picture-uri-dark "file:///usr/share/backgrounds/wallpaper.png"
    gsettings set org.gnome.desktop.background picture-options "zoom"

    # Create passphrase script
    sudo tee /usr/local/bin/digitar_passphrase.sh > /dev/null << 'EOF'
#!/bin/bash
notify-send "pasted"
xclip -selection clipboard < /media/tg/SAFE/safe/gpg/thomas.groch@gmail.com.private.gpg-key.passphrase
xdotool key --clearmodifiers ctrl+v
EOF
    sudo chmod 755 /usr/local/bin/digitar_passphrase.sh
}

# Setup users and groups
setup_users() {
    print_status "Setting up users and groups..."
    
    # Create groups
    for group in ansible tg users adm sudo lpadmin; do
        sudo groupadd -f "$group"
    done

    # Create ansible user
    if ! id -u ansible &>/dev/null; then
        sudo useradd -m -u 900 -g ansible -G ansible,tg,users,adm,sudo,lpadmin -s /usr/bin/zsh ansible
    fi

    # Copy sudoers files
    print_status "Setting up sudoers files..."
    sudo wget -q https://raw.githubusercontent.com/thomasgroch/ansible_popos/main/files/sudoers_ansible -O /etc/sudoers.d/ansible
    sudo chmod 0440 /etc/sudoers.d/ansible
    sudo wget -q https://raw.githubusercontent.com/thomasgroch/ansible_popos/main/files/ssh_agent -O /etc/sudoers.d/ssh_agent
    sudo chmod 0440 /etc/sudoers.d/ssh_agent

    # Create tg user if not exists
    if ! id -u tg &>/dev/null; then
        sudo useradd -m -g tg -G tg,users,adm,sudo,lpadmin -s /usr/bin/zsh tg
    fi
}

# Main execution
main() {
    setup_xdg_dirs
    setup_gpg
    add_repositories
    install_packages
    install_flatpak_apps
    install_lazygit
    setup_zsh
    setup_cron
    setup_dotfiles
    setup_gnome
    setup_users
    
    print_status "Setup completed successfully!"
    print_status "Please log out and log back in for all changes to take effect."
}

# Run main function
main
