FROM ubuntu:22.04

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    ansible \
    git \
    sudo \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user to run ansible
RUN useradd -m -s /bin/bash tg && \
    echo "tg ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/tg

# Switch to non-root user
USER tg
WORKDIR /home/tg

# Command to run when container starts
CMD ["sudo", "ansible-pull", "-U", "https://github.com/thomasgroch/ansible_popos.git"]
