#!/bin/bash
# add-database.sh - Create database and user for a virtual host

source ./utils.sh

echo "Add MariaDB Database for a Site"
read -rp "Enter site domain (must already be configured): " domain
domain=$(echo "$domain" | tr '[:upper:]' '[:lower:]')

if ! grep -q "^$domain=" "$IP_CONFIG_FILE"; then
  log "Domain $domain is not configured. Run add-virtualhost.sh first."
  exit 1
fi

db_name=$(echo "$domain" | tr '.' '_' | cut -c1-16)
db_user="${db_name}_u"
db_pass=$(generate_password)

log "Creating database $db_name and user $db_user..."
mysql_commands="
CREATE DATABASE IF NOT EXISTS \`$db_name\`;
CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_pass';
GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'localhost';
FLUSH PRIVILEGES;
"
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - sudo mysql -u root -e \"$mysql_commands\""
else
  sudo mysql -u root -e "$mysql_commands"
fi

credfile="$LAMP_CONFIG_DIR/site-db-creds.txt"
log "Saving database credentials to $credfile..."
credentials="$domain
  DB: $db_name
  User: $db_user
  Pass: $db_pass
"
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - echo -e \"$credentials\" >> \"$credfile\""
else
  echo -e "$credentials" >> "$credfile"
fi

log "Database created and credentials saved to $credfile"