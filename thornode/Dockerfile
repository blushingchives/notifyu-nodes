FROM registry.gitlab.com/thorchain/thornode:mainnet-3.15.2

RUN apt-get update
RUN apt-get install -y --no-install-recommends aria2 ca-certificates curl git golang jq make pv rsync apt-utils

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]