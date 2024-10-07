#!/bin/bash

LOCALUSER="tg"
ANSIBLEUSER="ansible"
BRANCH="master"
LOGFILE="/var/log/ansible.log"
DOTFILES_REPO="https://github.com/camilasrody/dotfiles"  # Set the path to your dotfiles repo
LAST_COMMIT_FILE="/tmp/last_dotfiles_commit.txt"
REPO="https://github.com/camilasrody/ansible_popos"
COMMON_OPTS="--vault-password-file /home/${ANSIBLEUSER}/.vault_key --url $REPO --limit $(cat /etc/hostname).local --checkout $BRANCH"

# Function to check for running ansible-pull processes
check_running() {
  if pgrep -f ansible-pull > /dev/null; then
    printf "\n$(date +"%Y-%m-%d %H:%M:%S") A running ansible-pull process was found.\nExiting.\n" | tee -a "$LOGFILE"
    exit 1
  fi
}

# Function to check for changes in the dotfiles repo
check_for_changes() {
  cd "$DOTFILES_REPO" || exit

  # Fetch the latest changes from the remote
  git fetch origin

  # Get the latest commit hash from the remote branch
  LATEST_COMMIT=$(git rev-parse origin/$BRANCH)

  # Check if the last commit file exists
  if [ -f "$LAST_COMMIT_FILE" ]; then
    LAST_COMMIT=$(cat "$LAST_COMMIT_FILE")
  else
    LAST_COMMIT=""
  fi

  # Compare the latest commit with the last known commit
  if [ "$LATEST_COMMIT" != "$LAST_COMMIT" ]; then
    echo "$LATEST_COMMIT" > "$LAST_COMMIT_FILE"
    return 0  # Changes detected
  fi

  return 1  # No changes
}

# Main script logic
check_running

# Check for changes in the dotfiles repo
if check_for_changes; then
  printf "\n$(date +"%Y-%m-%d %H:%M:%S") Changes detected in the dotfiles repository. Running ansible-pull...\n" | tee -a "$LOGFILE"
  if [[ ! -z "$1" ]]; then
    ansible-pull --tags "$1" $COMMON_OPTS >> "$LOGFILE" 2>&1
  else
    ansible-pull --only-if-changed $COMMON_OPTS >> "$LOGFILE" 2>&1
  fi
else
  printf "\n$(date +"%Y-%m-%d %H:%M:%S") No changes detected in the dotfiles repository. Exiting.\n" | tee -a "$LOGFILE"
fi
