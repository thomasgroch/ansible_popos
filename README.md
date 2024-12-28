# Pop!_OS Config Via Ansible

Ansible playbooks for automating Pop!_OS configuration and setup. This project provides a streamlined way to configure your Pop!_OS system with predefined settings, packages, and customizations.

*Last updated: December 25, 2024*

## 🚀 Quick Start

### Option 1: Direct Pull (Recommended)
```bash
curl -sL https://raw.githubusercontent.com/thomasgroch/ansible_popos/main/bootstrap.sh | bash
```

### Option 2: Manual Setup
```bash
# Clone the repository
git clone https://github.com/thomasgroch/ansible_popos.git
cd ansible_popos

# Run the setup script
./bootstrap.sh
```

### Option 3: Using Ansible Pull
```bash
sudo ansible-pull -U https://github.com/thomasgroch/ansible_popos.git
```

## 🔧 Features

- Automated Pop!_OS system configuration
- Package management and dependency handling
- Custom GNOME settings
- Automated maintenance:
  - Auto-provisioning every 3 hours
  - `.ansible` directory cleanup on boot
  - Execution logs in `/var/log/ansible.log`
- Password store integration
- GPG key management
- SSH key configuration

## 💡 Tips & Tricks

### GNOME Settings Management

To track GNOME setting changes:

1. Export current settings:
```bash
dconf dump / > before.txt
```

2. Make your UI changes

3. Export new settings:
```bash
dconf dump / > after.txt
```

4. View changes:
```bash
diff before.txt after.txt
```

### Troubleshooting

- If you encounter permission issues, ensure your user has sudo privileges
- For GPG key issues, check if the keys are properly imported
- Log files are available at `/var/log/ansible.log`

## 📋 Roadmap

- [ ] Windows VM setup automation
- [ ] Package list customization
- [ ] Task documentation
- [ ] Contribution guidelines
- [ ] Testing framework implementation
- [ ] Multi-distribution support

## 🔧 New Script Features

- The `provision` script has been updated to use a modular design, with functions for checking running processes and executing ansible-pull.
- Variables are used throughout the script to make it easier to manage configuration settings.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.