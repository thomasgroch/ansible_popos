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

print_status "Setting up system for user: $REAL_USER"

# Fix GPG directory permissions
setup_gpg() {
    print_status "Checking GPG directory permissions..."
    
    if [ ! -d "$REAL_HOME/.gnupg" ]; then
        mkdir -p "$REAL_HOME/.gnupg"
        print_status "Created .gnupg directory"
    fi
    
    current_perm=$(stat -c "%a" "$REAL_HOME/.gnupg")
    if [ "$current_perm" != "700" ]; then
        chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.gnupg"
        chmod 700 "$REAL_HOME/.gnupg"
        find "$REAL_HOME/.gnupg" -type f -exec chmod 600 {} \;
        print_status "Fixed GPG directory permissions"
    else
        print_warning "GPG directory permissions already correct"
    fi
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
    print_status "Checking Flatpak applications..."
    
    if ! is_flatpak_installed "com.moonlight_stream.Moonlight"; then
        print_status "Installing Moonlight..."
        flatpak install -y flathub com.moonlight_stream.Moonlight
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
    if [ ! -d "$REAL_HOME/.oh-my-zsh" ]; then
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

    # Copy provision script
    sudo cp files/provision /usr/local/bin/provision
    sudo chmod 0755 /usr/local/bin/provision

    # Add cron jobs
    (crontab -l 2>/dev/null || true; echo "*/3 * * * * { date; /usr/local/bin/provision; RC=\$?; date; echo \"Exit code: \$RC\"; } >> /var/tmp/ansible_provision.log 2>&1 && if [ \$RC -eq 0 ]; then echo \$(date) > /var/tmp/ansible_provision_last_run.txt; fi") | crontab -
    (crontab -l 2>/dev/null || true; echo "@reboot /bin/rm -rf /home/$USER/.ansible") | crontab -
}

# Setup dotfiles
setup_dotfiles() {
    print_status "Setting up dotfiles..."
    
    # Install oh-my-zsh if not already installed
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | RUNZSH=no KEEP_ZSHRC=yes sh
    fi

    # Create and set permissions for oh-my-zsh directories
    mkdir -p "$HOME/.oh-my-zsh/cache/completions"
    mkdir -p "$HOME/.oh-my-zsh-custom"
    chmod -R 755 "$HOME/.oh-my-zsh"
    chmod -R 755 "$HOME/.oh-my-zsh-custom"
}

# Setup GNOME settings
setup_gnome() {
    print_status "Setting up GNOME settings..."
    
    # Install required packages
    sudo apt-get install -y dconf-cli python3-psutil

    # Setup wallpaper
    sudo cp files/wallpaper.png /usr/share/backgrounds/wallpaper.png
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
    sudo cp files/sudoers_ansible /etc/sudoers.d/ansible
    sudo chmod 440 /etc/sudoers.d/ansible
    sudo cp files/ssh_agent /etc/sudoers.d/ssh_agent
    sudo chmod 440 /etc/sudoers.d/ssh_agent

    # Create tg user if not exists
    if ! id -u tg &>/dev/null; then
        sudo useradd -m -g tg -G tg,users,adm,sudo,lpadmin -s /usr/bin/zsh tg
    fi
}

# Main execution
main() {
    print_status "Starting system setup..."
    
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
