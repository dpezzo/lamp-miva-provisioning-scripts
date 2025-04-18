#!/bin/bash
# setup-miva.sh - Download and install Miva Empresa engine

source ./utils.sh

MIVA_URL="https://docs.miva.com/miva-software/empresa/mivavm-v5.51-ubuntu20_x64.tar.gz"
MIVA_DEST="/usr/local/mivavm-v5.51"
TEMP_FILE="/tmp/mivavm.tar.gz"

log "Downloading Miva Empresa from $MIVA_URL to $TEMP_FILE..."
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - curl -L \"$MIVA_URL\" -o \"$TEMP_FILE\""
else
  curl -L "$MIVA_URL" -o "$TEMP_FILE"
fi

log "Extracting Miva Empresa to $MIVA_DEST..."
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - sudo mkdir -p \"$MIVA_DEST\""
  log "DEBUG: DRY-RUN - sudo tar -xzf \"$TEMP_FILE\" -C \"$MIVA_DEST\" --strip-components=1"
else
  sudo mkdir -p "$MIVA_DEST"
  sudo tar -xzf "$TEMP_FILE" -C "$MIVA_DEST" --strip-components=1
fi

log "Cleaning up temporary file $TEMP_FILE..."
if [[ "$DRY_RUN" == "true" ]]; then
  log "DEBUG: DRY-RUN - rm -f \"$TEMP_FILE\""
else
  rm -f "$TEMP_FILE"
fi

log "Miva Empresa v5.51 installed at $MIVA_DEST"