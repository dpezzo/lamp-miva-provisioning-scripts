#!/bin/bash
# setup-lamp.sh - Base LAMP stack setup for Ubuntu 24.04

source ./utils.sh

log "Starting LAMP stack setup..."

# Update system packages
log "Updating system packages..."
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - sudo apt update && sudo apt upgrade -y"
else
  sudo apt update && sudo apt upgrade -y
  log "System updated."
fi

# Install Apache
log "Installing Apache..."
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - sudo apt install -y apache2"
else
  sudo apt install -y apache2
  log "Apache installed."
fi

# Install PHP and required extensions
log "Installing PHP and extensions..."
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - sudo apt install -y php libapache2-mod-php php-mysql php-cli php-curl php-xml php-mbstring php-zip php-bcmath"
else
  sudo apt install -y php libapache2-mod-php php-mysql php-cli php-curl php-xml php-mbstring php-zip php-bcmath
  log "PHP and extensions installed."
fi

# Install MariaDB
log "Installing MariaDB..."
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - DEBIAN_FRONTEND=noninteractive sudo apt install -y mariadb-server mariadb-client"
else
  DEBIAN_FRONTEND=noninteractive sudo apt install -y mariadb-server mariadb-client
  log "MariaDB installed."
fi

# Secure MariaDB with user-provided root password
read -sp "Enter a new MariaDB root password: " rootpass
echo
log "Setting MariaDB root password..."
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - mysql -u root -e \"ALTER USER 'root'@'localhost' IDENTIFIED BY '$rootpass'; FLUSH PRIVILEGES;\""
else
  sudo mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$rootpass'; FLUSH PRIVILEGES;"
fi
log "MariaDB root password set and privileges flushed."

# Install phpMyAdmin non-interactively
log "Installing phpMyAdmin..."
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - DEBIAN_FRONTEND=noninteractive sudo apt install -y phpmyadmin"
else
  DEBIAN_FRONTEND=noninteractive sudo apt install -y phpmyadmin
  log "phpMyAdmin installed."
fi

# Enable Apache modules and restart
log "Enabling Apache modules and restarting..."
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - sudo a2enmod rewrite"
  log "DEBUG: DRY-RUN - sudo systemctl restart apache2"
else
  sudo a2enmod rewrite
  sudo systemctl restart apache2
  log "Apache modules enabled and restarted."
fi

# Configure UFW
log "Configuring UFW..."
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - sudo ufw allow OpenSSH"
  log "DEBUG: DRY-RUN - sudo ufw allow 'Apache Full'"
  log "DEBUG: DRY-RUN - sudo ufw --force enable"
else
  sudo ufw allow OpenSSH
  sudo ufw allow 'Apache Full'
  sudo ufw --force enable
  log "UFW configured for SSH and Apache."
fi

# --- Virtualbox Shared Folder Setup ---
log "Setting up Virtualbox Shared Folder..."

# 1. Install Virtualbox Guest Additions (if not already installed)
log "Checking Virtualbox Guest Additions..."
if ! dpkg -l | grep -q virtualbox-guest; then
  log "Virtualbox Guest Additions not found, installing..."
  if [[ "$DRY_RUN" == "true" ]]; then
    log "DEBUG: DRY-RUN - sudo apt install -y virtualbox-guest-utils virtualbox-guest-x11"
  else
    sudo apt install -y virtualbox-guest-utils virtualbox-guest-x11
    log "Virtualbox Guest Additions installed."
  fi
else
  log "Virtualbox Guest Additions are already installed."
fi

# 2. Create the mount point (e.g., for all websites)
SHARED_MOUNT_POINT="/home/darren/shared" # CHANGED to /home/darren/shared
log "Creating shared folder mount point at $SHARED_MOUNT_POINT..."
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - sudo mkdir -p \"$SHARED_MOUNT_POINT\""
  log "DEBUG: DRY-RUN - sudo chown www-data:www-data \"$SHARED_MOUNT_POINT\""
  log "DEBUG: DRY-RUN - sudo chmod 775 \"$SHARED_MOUNT_POINT\""
else
  sudo mkdir -p "$SHARED_MOUNT_POINT"
  sudo chown www-data:www-data "$SHARED_MOUNT_POINT"
  sudo chmod 775 "$SHARED_MOUNT_POINT"
fi

# 3. Check if something is already mounted on the mount point
if mountpoint -q "$SHARED_MOUNT_POINT"; then
  log "WARNING: $SHARED_MOUNT_POINT already has a mount! Skipping Virtualbox Shared Folder mount."
else
  # 4. Add to /etc/fstab for automatic mounting on boot
  #    - Replace 'your_shared_folder_name' with the name you gave the Shared Folder in Virtualbox
  #    - 'uid=33,gid=33' ensures www-data (uid 33, gid 33) has ownership
  fstab_entry="your_shared_folder_name  $SHARED_MOUNT_POINT  vboxsf  uid=33,gid=33,rw,auto  0  0"
  log "Adding to /etc/fstab: $fstab_entry"
  if [[ "$DRY_RUN" == "true" ]]; then
    log "DEBUG: DRY-RUN - echo \"$fstab_entry\" | sudo tee -a /etc/fstab"
  else
    echo "$fstab_entry" | sudo tee -a /etc/fstab
  fi

  # 5. Mount the shared folder immediately
  if ! mountpoint -q "$SHARED_MOUNT_POINT"; then
    log "Mounting Virtualbox Shared Folder..."
    if [[ "$DRY_RUN" == "true" ]]; then
      log "DEBUG: DRY-RUN - sudo mount \"$SHARED_MOUNT_POINT\""
    else
      sudo mount "$SHARED_MOUNT_POINT"
      log "Virtualbox Shared Folder mounted successfully at $SHARED_MOUNT_POINT"
    fi
  else
    log "Virtualbox Shared Folder already mounted."
  fi
fi

# --- End Shared Folder Setup ---

log "LAMP stack installation complete."