#!/bin/bash
# delete-virtualhost.sh - Delete an Apache virtual host

source ./utils.sh

echo "Delete Virtual Host"
read -rp "Enter site domain to delete (e.g., project1.local): " domain
domain=$(echo "$domain" | tr '[:upper:]' '[:lower:]')

vhost_file="/etc/apache2/sites-available/$domain.conf"
docroot="/var/www/$domain"
mivadata="/var/www/${domain}-data"

log "Disabling site $domain..."
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - sudo a2dissite \"$domain\" > /dev/null"
else
  sudo a2dissite "$domain" > /dev/null
fi

if ! [[ -f "$vhost_file" ]]; then
  log "Virtual host configuration file $vhost_file not found."
else
  log "Backing up $vhost_file..."
  backup_file "$vhost_file"
  log "Deleting $vhost_file..."
  if [[ "$DRY_RUN" == "true" ]]; then
    log "DEBUG: DRY-RUN - rm -f \"$vhost_file\""
  else
    rm -f "$vhost_file"
  fi
fi

if [[ -d "$docroot" ]]; then
  log "Backing up $docroot/index.html..."
  backup_file "$docroot/index.html"
  log "Deleting $docroot..."
  if [[ "$DRY_RUN" == "true" ]]; then
    log "DEBUG: DRY-RUN - rm -rf \"$docroot\""
  else
    rm -rf "$docroot"
  fi
fi

if [[ -d "$mivadata" ]]; then
  log "Deleting $mivadata..."
  if [[ "$DRY_RUN" == "true" ]]; then
    log "DEBUG: DRY-RUN - rm -rf \"$mivadata\""
  else
    rm -rf "$mivadata"
  fi
fi

# Remove IP from config and netplan
remove_ip_from_config() {
  local domain=$1
  local sed_command="s/^$domain=.*//d"
  if [[ "$DRY_RUN" == "true" ]]; then
    log "DEBUG: DRY-RUN - sudo sed -i \"$sed_command\" \"$IP_CONFIG_FILE\""
  else
    sudo sed -i "$sed_command" "$IP_CONFIG_FILE"
  fi
  log "Removed $domain from $IP_CONFIG_FILE"
}
remove_ip_from_config "$domain"

remove_ip_from_netplan() {
  local domain=$1
  local ip=$(awk -F '=' "/^$domain=/ {print \$2}" "$IP_CONFIG_FILE")

  if [[ -n "$ip" ]]; then
    local sed_command="/- address: $ip\\/24/d"
    if [[ "$DRY_RUN" == "true" ]]; then
      log "DEBUG: DRY-RUN - sudo sed -i \"$sed_command\" \"$NETPLAN_FILE\""
      log "DEBUG: DRY-RUN - sudo netplan apply"
    else
      sudo sed -i "$sed_command" "$NETPLAN_FILE"
      sudo netplan apply
    fi
    log "Removed IP $ip from $NETPLAN_FILE and applied"
  else
    log "No IP found for $domain in $IP_CONFIG_FILE"
  fi
}
remove_ip_from_netplan "$domain"

log "Reloading Apache..."
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - sudo systemctl reload apache2"
else
  sudo systemctl reload apache2
fi

log "Virtual host $domain deleted."