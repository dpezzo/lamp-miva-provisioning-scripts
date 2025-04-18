#!/bin/bash
# set-hostname.sh - Set the server hostname

source ./utils.sh

echo "Set Server Hostname"
read -rp "Enter the desired hostname for the server (e.g., cre-lamp-calvo): " new_hostname

log "Setting hostname to $new_hostname..."
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - sudo hostnamectl set-hostname \"$new_hostname\""
else
  sudo hostnamectl set-hostname "$new_hostname"
fi

log "Updating /etc/hostname..."
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - echo \"$new_hostname\" | sudo tee /etc/hostname"
else
  echo "$new_hostname" | sudo tee /etc/hostname
fi

log "Updating /etc/hosts..."
if grep -q "127.0.1.1" /etc/hosts; then
  sed_command="s/127.0.1.1.*/127.0.1.1 $new_hostname/"
  if [[ "$DRY_RUN" == "true" ]]; then
    log "DEBUG: DRY-RUN - sudo sed -i \"$sed_command\" /etc/hosts"
  else
    sudo sed -i "$sed_command" /etc/hosts
  fi
else
  hosts_entry="127.0.1.1 $new_hostname"
  if [[ "$DRY_RUN" == "true" ]]; then
    log "DEBUG: DRY-RUN - echo \"$hosts_entry\" | sudo tee -a /etc/hosts"
  else
    echo "$hosts_entry" | sudo tee -a /etc/hosts
  fi
fi

log "Hostname set to $new_hostname. Please reboot the server for the changes to be fully applied."

# Optional: Verify the hostname
log "Verifying current hostname:"
hostname
hostname -f