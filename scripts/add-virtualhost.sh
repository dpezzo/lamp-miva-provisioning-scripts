#!/bin/bash
# add-virtualhost.sh - Create Apache virtualhost with optional Miva integration

source ./utils.sh

MIVA_ENGINE="/usr/local/mivavm-v5.51"
BUILTIN_DIR="$MIVA_ENGINE/lib/builtins"
CERTS_DIR="$MIVA_ENGINE/certs/openssl-1.0"
MYSQL_LIB="$MIVA_ENGINE/lib/databases/mysql.so"
CGI_BINARY="$MIVA_ENGINE/cgi-bin/mivavm"
ENV_CONFIG="$MIVA_ENGINE/lib/config/env.so"

echo "Add New Virtual Host"
read -rp "Enter site domain (e.g., project1.local): " domain
domain=$(echo "$domain" | tr '[:upper:]' '[:lower:]')

if [[ $domain != *.* ]]; then
  domain="$domain.local"
fi

if grep -q "^$domain=" "$IP_CONFIG_FILE"; then
  log "$domain is already configured. Aborting."
  exit 1
fi

ip=$(get_next_ip)
[[ $? -ne 0 ]] && exit 1

assign_ip_to_site "$domain" "$ip"

# Update /etc/hosts (within the VM)
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
    # IMPORTANT: To access this site from the host machine, you MUST also
    # add an entry to the host's 'hosts' file (e.g., '192.168.56.115 yourdomain.local').
  else
    log "/etc/hosts already contains: $content - skipping"
  fi
}
update_hosts_file "$domain" "$ip"

add_ip_to_netplan "$ip"

docroot="/var/www/$domain"
cgibin="$docroot/cgi-bin"
mivadata="/var/www/${domain}-data"

log "Creating directories $docroot, $cgibin, $mivadata..."
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - sudo mkdir -p \"$docroot\" \"$cgibin\" \"$mivadata\""
  log "DEBUG: DRY-RUN - sudo chown -R www-data:www-data \"$docroot\" \"$mivadata\""
  log "DEBUG: DRY-RUN - sudo chmod -R 755 \"$docroot\" \"$mivadata\""
else
  sudo mkdir -p "$docroot" "$cgibin" "$mivadata"
  sudo chown -R www-data:www-data "$docroot" "$mivadata"
  sudo chmod -R 755 "$docroot" "$mivadata"
fi
log "Created $docroot, $cgibin, and $mivadata"

log "Creating default index.html..."
default_content="<h1>$domain is working!</h1>"
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - echo \"$default_content\" > \"$docroot/index.html\""
else
  echo "$default_content" > "$docroot/index.html"
fi

read -rp "Would you like to configure Miva Empresa for this site? (y/n): " miva_answer

vhost_file="/etc/apache2/sites-available/$domain.conf"

log "Creating Apache virtual host configuration file: $vhost_file"
vhost_config="<VirtualHost $ip:80>
    ServerName $domain
    DocumentRoot $docroot

    <Directory $docroot>
        AllowOverride All
        Require all granted
    </Directory>

    ScriptAlias /cgi-bin/ $cgibin/
    <Directory \"$cgibin\">
        AllowOverride None
        Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
        Require all granted
    </Directory>
</VirtualHost>"

if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - cat > \"$vhost_file\" <<EOF\n$vhost_config\nEOF"
else
  cat > "$vhost_file" <<EOF
$vhost_config
EOF
fi

if [[ "$miva_answer" =~ ^[Yy]$ ]]; then
  log "Configuring Miva Empresa for $domain..."

  log "Copying Miva CGI binary..."
  if [[ "$DRY_RUN" == "true" ]]; then
    log "DEBUG: DRY-RUN - sudo cp \"$CGI_BINARY\" \"$cgibin/mivavm\""
    log "DEBUG: DRY-RUN - sudo chown www-data:www-data \"$cgibin/mivavm\""
    log "DEBUG: DRY-RUN - sudo chmod 0755 \"$cgibin/mivavm\""
  else
    sudo cp "$CGI_BINARY" "$cgibin/mivavm"
    sudo chown www-data:www-data "$cgibin/mivavm"
    sudo chmod 0755 "$cgibin/mivavm"
  fi

  log "Copying Miva config library..."
  if [[ "$DRY_RUN" == "true" ]]; then
    log "DEBUG: DRY-RUN - sudo cp \"$ENV_CONFIG\" \"$cgibin/libmivaconfig.so\""
    log "DEBUG: DRY-RUN - sudo chown www-data:www-data \"$cgibin/libmivaconfig.so\""
    log "DEBUG: DRY-RUN - sudo chmod 0755 \"$cgibin/libmivaconfig.so\""
  else
    sudo cp "$ENV_CONFIG" "$cgibin/libmivaconfig.so"
    sudo chown www-data:www-data "$cgibin/libmivaconfig.so"
    sudo chmod 0755 "$cgibin/libmivaconfig.so"
  fi

  miva_env_config="
    SetEnv HTTP_MvCONFIG_DIR_MIVA $docroot
    SetEnv HTTP_MvCONFIG_DIR_DATA $mivadata
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

  log "Adding Miva Empresa configuration to virtual host file..."
  if [[ "$DRY_RUN" == "true" ]]; then
    log "DEBUG: DRY-RUN - cat >> \"$vhost_file\" <<EOF\n$miva_env_config\nEOF"
  else
    cat >> "$vhost_file" <<EOF
$miva_env_config
EOF
  fi
  log "Miva configured for $domain"
fi

log "Enabling site $domain..."
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - sudo a2ensite \"$domain\" > /dev/null"
  log "DEBUG: DRY-RUN - sudo systemctl reload apache2"
else
  sudo a2ensite "$domain" > /dev/null
  sudo systemctl reload apache2
fi

log "Virtual host for $domain created at $ip"
log "You can now visit: http://$domain (mapped to $ip) WITHIN THE VM."
echo ""
echo "-----------------------------------------------------------------------"
echo "IMPORTANT: To access this site from your HOST MACHINE (e.g., Windows"
echo "browser), you need to add the following line to your host's 'hosts' file:"
echo ""
echo "  $ip $domain"
echo ""
echo "Windows 'hosts' file location: C:\\Windows\\System32\\drivers\\etc\\hosts"
echo "macOS/Linux 'hosts' file location: /etc/hosts"
echo ""
echo "You might need to flush your browser's DNS cache or run 'ipconfig /flushdns'"
echo "(on Windows) for the change to take effect."
echo "-----------------------------------------------------------------------"