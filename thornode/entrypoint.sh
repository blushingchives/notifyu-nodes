#!/bin/bash

set -e

echo "✅ Setting up node..."
# Initialize thornode if not already done
if [ ! -f /root/.thornode/config/genesis.json ]; then

  echo "🕒 Waiting for snapshot to be available..."

  # Wait for a known file that is created only after snapshot is fully extracted
  while [ ! -f /root/shared-volume/data/priv_validator_state.json ]; do
    echo "⏳ Snapshot not ready yet. Sleeping 5s..."
    sleep 5
  done

  thornode init docker-node --chain-id=thorchain-1

  echo "📥 Downloading genesis..."
  curl -s https://storage.googleapis.com/public-snapshots-ninerealms/genesis/17562000.json -o /root/.thornode/config/genesis.json

  rm -rf /root/.thornode/data

  echo "📦 Copying snapshot into thornode directory..."
  rsync -ah --progress /root/shared-volume/data/ /root/.thornode/data
fi

echo "Copying app/config files..."
cp /root/config/app.toml /root/.thornode/config/app.toml
cp /root/config/config.toml /root/.thornode/config/config.toml

echo "🚀 Starting thornode..."
exec thornode start