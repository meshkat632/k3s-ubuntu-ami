#!/bin/bash

# Install k3s
curl -sfL https://get.k3s.io | sh -

# Copy example.txt with correct permissions
cp example.txt /example.txt
chmod 644 /example.txt

# Add more customization tasks if needed
