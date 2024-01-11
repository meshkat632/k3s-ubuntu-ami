#!/bin/bash

input_string=$(cat $1 | grep 'Adding tags to AMI (ami-')
# Given string
#input_string="Adding tags to AMI (ami-023e8761caf86cd7d)"

# Extract AMI ID using awk
ami_id=$(echo "$input_string" | awk 'match($0, /\(ami-([a-fA-F0-9]+)\)/) {print substr($0, RSTART+5, RLENGTH-6)}')

# Create a JSON string
json_output="{ \"ami_id\": \"ami-$ami_id\" }"

# Write the JSON string to a file
echo "$json_output" > $2
