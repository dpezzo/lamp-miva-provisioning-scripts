#!/bin/bash
# lampstack-menu.sh - Menu interface for LAMP + Miva provisioning

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEBUG=false
DRY_RUN=false

function header() {
  clear
  echo "==========================================="
  echo "     LAMP + Miva Empresa Provisioning      "
  echo "==========================================="
  echo "  Debug Mode: $(if "$DEBUG"; then echo "ON"; else echo "OFF"; fi)"
  echo "  Dry-Run Mode: $(if "$DRY_RUN"; then echo "ON"; else echo "OFF"; fi)"
  echo "==========================================="
  echo
}

function toggle_debug() {
  if "$DEBUG"; then
    DEBUG=false
    echo "Debug mode is now OFF."
  else
    DEBUG=true
    echo "Debug mode is now ON."
  fi
  pause
}

function toggle_dry_run() {
  if "$DRY_RUN"; then
    DRY_RUN=false
    echo "Dry-run mode is now OFF."
  else
    DRY_RUN=true
    echo "Dry-run mode is now ON."
  fi
  pause
}

function toggle_both() {
  if "$DEBUG" && "$DRY_RUN"; then
    DEBUG=false
    DRY_RUN=false
    echo "Debug mode is now OFF."
    echo "Dry-run mode is now OFF."
  else
    DEBUG=true
    DRY_RUN=true
    echo "Debug mode is now ON."
    echo "Dry-run mode is now ON."
  fi
  pause
}

function pause() {
  read -rp "Press [Enter] to return to the menu..."
}

function main_menu() {
  while true; do
    header
    echo "Choose an option:"
    echo "b) Toggle Both Debug and Dry-Run ($(if "$DEBUG" && "$DRY_RUN"; then echo "OFF"; else echo "ON"; fi))"
    echo "d) Toggle Debug Mode ($(if "$DEBUG"; then echo "ON"; else echo "OFF"; fi))"
    echo "r) Toggle Dry-Run Mode ($(if "$DRY_RUN"; then echo "ON"; else echo "OFF"; fi))"
    echo "1) Install LAMP stack"
    echo "2) Install Miva Empresa Engine"
    echo "3) Add a new virtual host"
    echo "4) Add Miva Empresa to an existing virtual host"
    echo "5) Create a MariaDB database for a virtual host"
    echo "6) Delete a virtual host"
    echo "7) View configuration log"
    echo "8) Set server hostname"
    echo "9) Exit"
    echo
    read -rp "Enter choice [b/d/r/1-9]: " choice

    case $choice in
      b)
        toggle_both
        ;;
      d)
        toggle_debug
        ;;
      r)
        toggle_dry_run
        ;;
      1)
        sudo "$SCRIPT_DIR/setup-lamp.sh"
        pause
        ;;
      2)
        sudo "$SCRIPT_DIR/setup-miva.sh"
        pause
        ;;
      3)
        sudo "$SCRIPT_DIR/add-virtualhost.sh"
        pause
        ;;
      4)
        sudo "$SCRIPT_DIR/add-miva-to-site.sh"
        pause
        ;;
      5)
        sudo "$SCRIPT_DIR/add-database.sh"
        pause
        ;;
      6)
        sudo "$SCRIPT_DIR/delete-virtualhost.sh"
        pause
        ;;
      7)
        sudo less /var/log/lampstack-install.log
        ;;
      8)
        sudo "$SCRIPT_DIR/set-hostname.sh"
        pause
        ;;
      9)
        echo "Goodbye!"
        break
        ;;
      *)
        echo "Invalid option." && sleep 1
        ;;
    esac
  done
}

main_menu
