#!/bin/bash
set -e
eval "$(jq -r '@sh "FILE=\(.file)"')"

# Placeholder for whatever data-fetching logic your script implements
cat $FILE | jq -r '.'

