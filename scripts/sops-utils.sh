#!/bin/bash

set -e

failIfEncrypted() {
  my_var=$(yq '. | has("sops")' "$1")
  if [ "$my_var" = true ]; then
    echo "$1 is already encrypted"
    exit 1
  fi
}
export -f failIfEncrypted

failIfNotEncrypted() {
  my_var=$(yq '. | has("sops")' "$1")
  if [ "$my_var" = false ]; then
    echo "$1 is already unencrypted"
    exit 1
  fi
}
export -f failIfNotEncrypted

encryptFile() {
  FILE=$1
  echo "[ vvc-control-plane-app ]encryptFile file:$FILE"
  #keys=$(cat .sops.yaml | yq eval '.creation_rules[0].age' -o=j | jq -s 'flatten(1) | join(", ")')
  keys=$(cat .sops.yaml | yq eval '.creation_rules[0].age' -o=j | tr -d '"')
  #echo "keys:[$keys]"
  #export SOPS_AGE_RECIPIENTS=$keys
  #echo "SOPS_AGE_RECIPIENTS:[$SOPS_AGE_RECIPIENTS]"
  if test -f "$FILE"; then
    yq "$FILE" >/dev/null
    failIfEncrypted "$FILE"
    str_to_replace=".yaml"
    replace_str=".encrypted.yaml"
    result=$(echo "$FILE" | sed -e "s/$str_to_replace/$replace_str/g")
    sops --encrypt --age "$keys" "$FILE" >"$result"
    #sops updatekeys -y $result
    mv "$result" "$FILE"
  fi
}
export -f encryptFile
decryptFile() {
  FILE=$1
  echo "[ vvc-control-plane-app ] decryptFile file:$FILE"
  if test -f "$FILE"; then
    yq "$FILE" >/dev/null
    failIfNotEncrypted "$FILE"
    str_to_replace=".yaml"
    replace_str=".unencrypted.yaml"
    result=$(echo "$FILE" | sed -e "s/$str_to_replace/$replace_str/g")
    sops --decrypt "$FILE" >"$result"
    mv "$result" "$FILE"
  fi
}
export -f decryptFile

updateKeys() {
  FILE=$1
  echo "updateKeys file:$FILE"
  if test -f "$FILE"; then
    yq "$FILE" >/dev/null
    failIfNotEncrypted "$FILE"
    sops updatekeys -y "$FILE"
  fi
}
export -f updateKeys

readKey() {
  SRC=$1
  KEY=$2
  #echo "readKey key:"$KEY" from config:$SRC"
  if test -f "$SRC"; then
    yq "$SRC" >/dev/null
    failIfEncrypted "$SRC"
  fi
  result=$(cat "$SRC" | yq eval ".$KEY" -o=j | tr -d '"')
  echo "$result"
}
export -f readKey

decryptAll() {
  #ENCRYPTED_DIRECTORY=$1
  #echo "decryptAll $ENCRYPTED_DIRECTORY"
  #du -a "$ENCRYPTED_DIRECTORY" | grep .yaml | awk '{print$2}' | xargs -n 1 bash -c 'decryptFile "$@"' _
  find . -name "*.secret.sops.yaml" -type f -exec sh -c "decryptFile {} $tmpfile" \;
}

encryptAll() {
  #ENCRYPTED_DIRECTORY=$1
  #echo "encryptAll $ENCRYPTED_DIRECTORY"
  #du -a "$ENCRYPTED_DIRECTORY" | grep .yaml | awk '{print$2}' | xargs -n 1 bash -c 'encryptFile "$@"' _

  find . -name "*.secret.sops.yaml" -type f -exec sh -c "encryptFile {} $tmpfile" \;


}

checkFilesEncryptedAll() {
  ENCRYPTED_DIRECTORY=$1
  echo "check files are encrypted in $ENCRYPTED_DIRECTORY"
  du -a "$ENCRYPTED_DIRECTORY" | grep .yaml | awk '{print$2}' | xargs -n 1 bash -c 'failIfNotEncrypted "$@"' _
}

updateKeysAll() {
  ENCRYPTED_DIRECTORY=$1
  echo "encryptAll $ENCRYPTED_DIRECTORY"
  du -a "$ENCRYPTED_DIRECTORY" | grep .yaml | awk '{print$2}' | xargs -n 1 bash -c 'updateKeys "$@"' _
}

updateSopsConfig() {
  result=$(cat .sops-keys.yaml | yq eval '.devopsMembers' -o=j | jq -r 'map(.agePublicKeys)' | jq '.[]' | jq -s 'flatten(1) | join(",")')
  yq e -i ".creation_rules[].age = $result" .sops.yaml
}

# Check if the function exists (bash specific)
if declare -f "$1" >/dev/null; then
  # call arguments verbatim
  "$@"
else
  # Show a helpful error
  echo "'$1' is not a known function name" >&2
  exit 1
fi
