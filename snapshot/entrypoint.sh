#!/bin/bash

# Get current snapshot height from /data (empty if none)
CURRENT_HEIGHT=$(ls /data/*.tar.gz 2>/dev/null | grep -Eo "[0-9]+.tar.gz" | cut -d "." -f1 || echo "")

# Get latest snapshot filename from the internet
LATEST_SNAPSHOT=$(curl -s "https://snapshots.ninerealms.com/snapshots?prefix=thornode" | grep -Eo "thornode/[0-9]+.tar.gz" | sort -n | tail -n 1 | cut -d "/" -f2)
LATEST_HEIGHT=$(echo $LATEST_SNAPSHOT | cut -d "." -f1)

# If no local snapshot or heights differ, download and extract
if [[ "$CURRENT_HEIGHT" != "$LATEST_HEIGHT" ]]; then
    rm -rf /data/*
    aria2c --split=16 --max-concurrent-downloads=16 --max-connection-per-server=16 --continue --min-split-size=100M -d /data -o $LATEST_SNAPSHOT "https://snapshots.ninerealms.com/snapshots/thornode/${LATEST_SNAPSHOT}"
    echo "Extracting $LATEST_SNAPSHOT."
    pv --force /data/$LATEST_SNAPSHOT | tar -xzf - -C /data
    echo "Extracting $LATEST_SNAPSHOT."
fi

echo "Done. Snapshot process complete."
