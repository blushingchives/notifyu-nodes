#!/bin/bash

set -e

cp /usr/local/config/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

echo "🚀 Starting load balancer..."
haproxy -f /usr/local/etc/haproxy/haproxy.cfg -d