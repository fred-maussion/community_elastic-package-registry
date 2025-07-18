#!/bin/sh

# This script is executed before the package is removed.

# Before removing the package, stop and disable the service to clean up gracefully.
echo "Stopping package-registry service..."
systemctl stop package-registry.service

echo "Disabling package-registry service..."
systemctl disable package-registry.service

exit 0
