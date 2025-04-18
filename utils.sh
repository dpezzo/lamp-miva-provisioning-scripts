#!/bin/bash
# utils.sh - Shared helper functions for LAMP + Miva stack setup

LAMP_CONFIG_DIR="/etc/lampstack"
IP_CONFIG_FILE="$LAMP_CONFIG_DIR/site-ips.conf"
LOG_FILE="/var/log/lampstack-install.log"
IP_BASE="192.168.56"
IP_START=10
IP_END=99
NETPLAN_FILE="/etc/netplan/01-netcfg.yaml"
INTERFACE="enp0s8"
DEBUG=false
DRY_RUN=false

mkdir -p "$LAMP_CONFIG_DIR"
touch "$IP_CONFIG_FILE"
touch "$LOG_FILE"

log() {
  local level="$1" # Optional level - not currently used but can be extended
  shift
  local message="$*"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  if [[ "$DEBUG" == "true" ]]; then
    echo "[DEBUG - $timestamp] $message"
  fi
  echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

generate_password() {
  if [[ "$DRY_RUN" == "true" ]]; then
    log "DEBUG: DRY-RUN - openssl rand -base64 14 (simulating password generation)"
    echo "dry-run-password"
  else
    openssl rand -base64 14
  fi
}

get_next_ip() {
  local used_ips
  used_ips=$(awk -F '=' '{print $2}' "$IP_CONFIG_FILE" 2>/dev/null)

  for i in $(seq $IP_START $IP_END); do
    candidate="$IP_BASE.$i"
    if ! grep -q "$candidate" <<< "$used_ips"; then
      echo "$candidate"
      return 0
    fi
  done

  log "ERROR: No available IPs in range $IP_BASE.$IP_START-$IP_END"
  return 1
}

assign_ip_to_site() {
  local domain=$1
  local ip=$2

  if [[ "$DRY_RUN" == "true" ]]; then
    log "DEBUG: DRY-RUN - echo \"$domain=$ip\" >> \"$IP_CONFIG_FILE\""
  else
    echo "$domain=$ip" >> "$IP_CONFIG_FILE"
  fi
  log "Assigned IP $ip to $domain"
}

update_hosts_file() {
  local domain=$1
  local ip=$2
  local content="
$ip  $domain
"

  if ! grep -q "$content" "/etc/hosts"; then
    if [[ "$DRY_RUN" == "true" ]]; then
      log "DEBUG: DRY-RUN - echo \"$content\" | sudo tee -a \"/etc/hosts\""
    else
      echo "$content" | sudo tee -a "/etc/hosts"
    fi
    log "Updated /etc/hosts for $domain"
  else
    log "/etc/hosts already contains: $content - skipping"
  fi
}

add_ip_to_netplan() {
  local ip=$1
  local content="
    - address: $ip/24
"

  if ! grep -q "$content" "$NETPLAN_FILE"; then
    if [[ "$DRY_RUN" == "true" ]]; then
      log "DEBUG: DRY-RUN - echo \"$content\" | sudo tee -a \"$NETPLAN_FILE\""
      log "DEBUG: DRY-RUN - sudo netplan apply"
    else
      echo "$content" | sudo tee -a "$NETPLAN_FILE"
      sudo netplan apply
    fi
    log "Added IP $ip to $NETPLAN_FILE and applied"
  else
    log "$NETPLAN_FILE already contains: $content - skipping"
  fi
}

safe_append_to_file() {
  local file=$1
  local content=$2

  if ! grep -q "$content" "$file"; then
    if [[ "$DRY_RUN" == "true" ]]; then
      log "DEBUG: DRY-RUN - echo \"$content\" | sudo tee -a \"$file\""
    else
      echo "$content" | sudo tee -a "$file"
    fi
    log "Appended to $file: $content"
  else
    log "$file already contains: $content - skipping"
  fi
}

backup_file() {
  local file_to_backup=$1
  local backup_dir="$LAMP_CONFIG_DIR/backups"
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_file="$backup_dir/$(basename "$file_to_backup").$timestamp"

  if [[ "$DRY_RUN" == "true" ]]; then
    log "DEBUG: DRY-RUN - mkdir -p \"$backup_dir\""
    log "DEBUG: DRY-RUN - cp -p \"$file_to_backup\" \"$backup_file\""
    log "Backed up $file_to_backup to $backup_file (dry-run)"
  else
    mkdir -p "$backup_dir"
    if cp -p "$file_to_backup" "$backup_file"; then
      log "Backed up $file_to_backup to $backup_file"
    else
      log "ERROR: Failed to backup $file_to_backup"
    fi
  fi
}