#!/bin/sh

# This script is executed after the package is installed.

# Create the directory for packages if it doesn't exist.
echo "Ensuring package directory exists..."
mkdir -p /var/package-registry/packages

# On install or upgrade, reload the systemd daemon to recognize the new service
# and enable it to start on boot.
echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling package-registry service..."
systemctl enable package-registry.service

echo "Service enabled. Start it with: systemctl start package-registry.service"

exit 0