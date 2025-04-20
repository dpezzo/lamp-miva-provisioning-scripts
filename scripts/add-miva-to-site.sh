#!/bin/bash
# add-miva-to-site.sh - Add Miva Empresa support to an existing virtual host

source ./utils.sh

MIVA_ENGINE="/usr/local/mivavm-v5.51"
BUILTIN_DIR="$MIVA_ENGINE/lib/builtins"
CERTS_DIR="$MIVA_ENGINE/certs/openssl-1.0"
MYSQL_LIB="$MIVA_ENGINE/lib/databases/mysql.so"
CGI_BINARY="$MIVA_ENGINE/cgi-bin/mivavm"
ENV_CONFIG="$MIVA_ENGINE/lib/config/env.so"

read -rp "Enter domain to add Miva Empresa to (e.g., project1.local): " domain
domain=$(echo "$domain" | tr '[:upper:]' '[:lower:]')

if ! grep -q "^$domain=" "$IP_CONFIG_FILE"; then
  log "Domain $domain is not configured. Run add-virtualhost.sh first."
  exit 1
fi

vhost_file="/etc/apache2/sites-available/$domain.conf"

if ! grep -q "SetEnv HTTP_MvCONFIG_DIR_MIVA" "$vhost_file"; then
  miva_config_block="
    SetEnv HTTP_MvCONFIG_DIR_MIVA /var/www/$domain
    SetEnv HTTP_MvCONFIG_DIR_DATA /var/www/${domain}/mivadata
    SetEnv HTTP_MvCONFIG_DIR_BUILTIN $BUILTIN_DIR
    SetEnv HTTP_MvCONFIG_DIR_CA $CERTS_DIR
    SetEnv HTTP_MvCONFIG_FILE_CA /etc/ssl/certs/ca-certificates.crt
    SetEnv HTTP_MvCONFIG_DATABASE_MYSQL $MYSQL_LIB
    SetEnv HTTP_MvCONFIG_SSL_OPENSSL /lib/x86_64-linux-gnu/libssl.so.3
    SetEnv HTTP_MvCONFIG_SSL_CRYPTO /lib/x86_64-linux-gnu/libcrypto.so.3
    SetEnv HTTP_MvCONFIG_COOKIES 0

    AddHandler mivascript .mvc
    Action mivascript /cgi-bin/mivavm
  "
  log "Adding Miva Empresa configuration to $vhost_file..."
  sed_command="/<\/VirtualHost>/i \\\n$miva_config_block"
  if [[ "$DRY_RUN" == "true" ]]; then
    log "DEBUG: DRY-RUN - sudo sed -i \"$sed_command\" \"$vhost_file\""
  else
    sudo sed -i "$sed_command" "$vhost_file"
  fi

  # Copy Miva related files if they don't exist
  if [ ! -f "/var/www/$domain/cgi-bin/mivavm" ]; then
    log "Copying Miva VM executable..."
    if [[ "$DRY_RUN" == "true" ]]; then
      log "DEBUG: DRY-RUN - sudo mkdir -p \"/var/www/$domain/cgi-bin\""
      log "DEBUG: DRY-RUN - sudo cp \"$CGI_BINARY\" \"/var/www/$domain/cgi-bin/mivavm\""
      log "DEBUG: DRY-RUN - sudo chown www-data:www-data \"/var/www/$domain/cgi-bin/mivavm\""
      log "DEBUG: DRY-RUN - sudo chmod 0755 \"/var/www/$domain/cgi-bin/mivavm\""
    else
      sudo mkdir -p "/var/www/$domain/cgi-bin"
      sudo cp "$CGI_BINARY" "/var/www/$domain/cgi-bin/mivavm"
      sudo chown www-data:www-data "/var/www/$domain/cgi-bin/mivavm"
      sudo chmod 0755 "/var/www/$domain/cgi-bin/mivavm"
    fi
  fi

  if [ ! -f "/var/www/$domain/cgi-bin/libmivaconfig.so" ]; then
    log "Copying Miva config library..."
    if [[ "$DRY_RUN" == "true" ]]; then
      log "DEBUG: DRY-RUN - sudo mkdir -p \"/var/www/$domain/cgi-bin\""
      log "DEBUG: DRY-RUN - sudo cp \"$ENV_CONFIG\" \"/var/www/$domain/cgi-bin/libmivaconfig.so\""
      log "DEBUG: DRY-RUN - sudo chown www-data:www-data \"/var/www/$domain/cgi-bin/libmivaconfig.so\""
      log "DEBUG: DRY-RUN - sudo chmod 0755 \"/var/www/$domain/cgi-bin/libmivaconfig.so\""
    else
      sudo mkdir -p "/var/www/$domain/cgi-bin"
      sudo cp "$ENV_CONFIG" "/var/www/$domain/cgi-bin/libmivaconfig.so"
      sudo chown www-data:www-data "/var/www/$domain/cgi-bin/libmivaconfig.so"
      sudo chmod 0755 "/var/www/$domain/cgi-bin/libmivaconfig.so"
    fi
  fi

  log "Restarting Apache..."
  if [[ "$DRY_RUN" == "true" ]]; then
    log "DEBUG: DRY-RUN - sudo systemctl restart apache2"
  else
    sudo systemctl restart apache2
  fi

  log "Miva Empresa added to $domain"
else
  log "Miva Empresa configuration already exists for $domain"
fi
