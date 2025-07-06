FROM alpine:latest

RUN apk add --no-cache aria2 tar curl pv coreutils bash

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /data
# Download latest snapshot index and extract the latest .tar.lz4 file
# ENTRYPOINT sh -c '\
#   rm -rf /data/* && \
#   FILENAME=$(curl -s "https://snapshots.ninerealms.com/snapshots?prefix=thornode" | grep -Eo "thornode/[0-9]+.tar.gz" | sort -n | tail -n 1 | cut -d "/" -f 2) && \
#   aria2c --split=16 --max-concurrent-downloads=16 --max-connection-per-server=16 --continue --min-split-size=100M -d /data -o $FILENAME "https://snapshots.ninerealms.com/snapshots/thornode/${FILENAME}" && \
#   echo "Extracting $FILENAME." && \
#   pv --force /data/$FILENAME | tar -xzf - -C /data && \
#   echo "Extracting $FILENAME." && \
#   echo "Removing tar file." && \
#   rm -rf /data/$FILENAME && \
#   echo "Done. Snapshot process complete."'

ENTRYPOINT ["/entrypoint.sh"]
# # Download latest snapshot index and extract the latest .tar.lz4 file
# ENTRYPOINT sh -c '\
#   FILENAME=$(curl -s "https://snapshots.ninerealms.com/snapshots?prefix=thornode" | grep -Eo "thornode/[0-9]+.tar.gz" | sort -n | tail -n 1 | cut -d "/" -f 2) && \
#   aria2c --split=16 --max-concurrent-downloads=16 --max-connection-per-server=16 --continue --min-split-size=100M -d /data -o $FILENAME "https://snapshots.ninerealms.com/snapshots/thornode/${FILENAME}" && \
#   echo "Extracting $FILENAME." && \
#   tar -xzf "/data/$FILENAME" -C /data && \
#   echo "Extracting $FILENAME." && \
#   echo "Removing tar file." && \
#   rm -rf /data/$FILENAME && \
#   echo "Done. Snapshot process complete."'