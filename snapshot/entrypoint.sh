#!/bin/bash

# Get current snapshot file in /data
CURRENT_HEIGHT=$(ls /data/*.tar.gz 2>/dev/null | grep -Eo "[0-9]+.tar.gz" | cut -d "." -f1)

# Get latest snapshot filename from the internet
LATEST_SNAPSHOT=$(curl -s "https://snapshots.ninerealms.com/snapshots?prefix=thornode" | grep -Eo "thornode/[0-9]+.tar.gz" | sort -n | tail -n 1 | cut -d "/" -f2)
LATEST_HEIGHT=$(echo $LATEST_SNAPSHOT | cut -d "." -f1)

echo "Current Height: $CURRENT_HEIGHT, Latest Height: $LATEST_HEIGHT"

# Compare and skip if same
if [[ "$CURRENT_HEIGHT" == "$LATEST_HEIGHT" ]]; then
    echo "Skipping snapshot."
    exit 0
fi

rm -rf /data/*
FILENAME=$(curl -s "https://snapshots.ninerealms.com/snapshots?prefix=thornode" | grep -Eo "thornode/[0-9]+.tar.gz" | sort -n | tail -n 1 | cut -d "/" -f 2)
aria2c --split=16 --max-concurrent-downloads=16 --max-connection-per-server=16 --continue --min-split-size=100M -d /data -o $FILENAME "https://snapshots.ninerealms.com/snapshots/thornode/${FILENAME}"
echo "Extracting $FILENAME."
pv --force /data/$FILENAME | tar -xzf - -C /data
echo "Extracting $FILENAME."
echo "Removing tar file."
rm -rf /data/$FILENAME
echo "Done. Snapshot process complete.