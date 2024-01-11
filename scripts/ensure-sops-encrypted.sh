#!/bin/bash
# Set the -e option to exit immediately if a command exits with a non-zero status.
set -e
tmpfile=$(mktemp /tmp/ensure-sops-encrypted.XXXXXX)
echo "UNENCRYPTED_FILE_COUNT=0" > $tmpfile
failIfNotEncrypted() {
  echo "checking file '$1'for sops encryption."
  my_var=$(yq '. | has("sops")' "$1")
  if [ "$my_var" = false ]; then
    echo " '$1' is not encrypted."
    source $2
    #echo "$UNENCRYPTED_FILE_COUNT"
    ((UNENCRYPTED_FILE_COUNT=UNENCRYPTED_FILE_COUNT+1))
    #echo "$UNENCRYPTED_FILE_COUNT"
    echo "UNENCRYPTED_FILE_COUNT=$UNENCRYPTED_FILE_COUNT" > $2
    exit 0
  fi
}
export -f failIfNotEncrypted
echo "$UNENCRYPTED_FILE_COUNT"
find . -name "*.secret.sops.yaml" -type f -exec sh -c "failIfNotEncrypted {} $tmpfile" \;
source "$tmpfile"
rm "$tmpfile"
if (( $UNENCRYPTED_FILE_COUNT > 0 )); then
  echo "FAIL: number of files not encrypted: $UNENCRYPTED_FILE_COUNT"
  exit 1
else
  exit 0
fi
