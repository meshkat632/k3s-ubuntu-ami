#!/bin/bash

touch src-sum.txt
sha256sum package-lock.json > src-sum.txt
find src -type f -exec sha256sum {} \; >> src-sum.txt
sha256sum src-sum.txt | awk '{print$1}' > src-sum.txt
cat src-sum.txt
