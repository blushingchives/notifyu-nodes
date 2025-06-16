#!/bin/bash

set -e

apt-get update
apt-get install -y rsync
echo "✅ Snapshot detected! Setting up node..."

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

  echo "⚙️ Setting minimum gas price..."
  sed -i 's/minimum-gas-prices = ""/minimum-gas-prices = "0.1rune"/' /root/.thornode/config/app.toml

  echo "📦 Copying snapshot into thornode directory..."
  # cp -r /root/shared-volume/data/* /root/.thornode
  rsync -ah --progress /root/shared-volume/data/ /root/.thornode/

  echo "Modifying config/app.toml files"
  sed -i.bak -e "s/^query_gas_limit *=.*/query_gas_limit = 100000000/" /root/.thornode/config/app.toml
  sed -i.bak -e "s/^index-events *=.*/index-events = \"null\"/" /root/.thornode/config/app.toml
  sed -i.bak -e "s/^pruning *=.*/pruning = \"everything\"/" /root/.thornode/config/app.toml
  sed -i.bak -e "s/^enable-unsafe-cors *=.*/enable-unsafe-cors = true/" /root/.thornode/config/app.toml
  sed -i.bak -e "s/^enable *=.*/enable = true/" /root/.thornode/config/app.toml
  sed -i.bak -e "s/^swagger *=.*/swagger = true/" /root/.thornode/config/app.toml

  echo "Modifying config/config.toml files"
  sed -i.bak -e "s/^max_txs_bytes *=.*/max_txs_bytes = 10485760/" /root/.thornode/config/config.toml
  sed -i.bak -e "s/^size *=.*/size = 1000/" /root/.thornode/config/config.toml
  sed -i.bak -e "s/^cors_allowed_origins *=.*/cors_allowed_origins = [\"*\"]/" /root/.thornode/config/config.toml

fi

echo "🚀 Starting thornode..."
exec thornode start